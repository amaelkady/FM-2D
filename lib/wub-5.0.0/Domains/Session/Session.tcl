# Session - handle Session vars stored in a mk db, indexed by a cookie slot.
#
# This is to be run in the main thread, and to amend the -session var in
# a request, to be passed along with request to Workers.
#
# Use of a mk db allows sessions to be available to all threads in a
# multithreaded environment.
#
# ARCHITECTURE:
# Cookies shouldn't be sent with a path of /, because it screws up caching
# Session maintains a key in cookie which is sent within a constrained path.
# (a) how can a cookie within a constrained path be used
# everywhere on a site when it's only sent for a subpath of the site - use a
# web-bug technique - load some file from session domain on every page, don't cache
# that subdomain.  Use Wub to associate the cookie with the whole session.
# (b) how can a cookie within a sub-path impact on the whole page as seen by a
# client?  Javascript.  Send javascript from the web bug.
#
# IMPLEMENTATION:
# Sessions are records in a metakit database which are loaded into a subdict
# of request, using the session key value passed in via a cookie.
# If the session subdict changes during processing of the request, changes will
# be rewritten to the database.
#
# Examples:
#
# 1) Fetch a session
#
#	set req [Session fetch $req] ;# fetch session specified by cookie
#	set session [dict get $req -session]	;# this is the session dict
#	if {[dict exists $session _key]} {
#		# this is an existing session
#		puts "[dict get $session _key] is the session key"
#	} else {
#		# this is a brand new session (as no key has been assigned)
#	}
#
# 2) Modify/use session state
#
# FIRST:
#	dict set req -session somevar $value	;# set a session variable
#
# THEN:
#	dict with req -session {
#		... modify existing variables - only works on existing sessions
#		# risky unless you can control the contents of the dict,
#		# as any element in dict *will* overwrite other vars.
#	}
# OR:
#	Session with req {
#		... modify existing variables
#	}
#
# FINALLY:
#	set rsp [Session store $req]	;# session doesn't exist until stored
#	return $rsp			;# the rsp will have required cookies
#
# 3) Remove a session from the database
#
#	set rsp [Session remove $req]
#	return $rsp

package require Debug
Debug define session 10
package require md5
package require View

package provide Session 3.1
set ::API(Obsolete/Session) {
    {
	Session manipulation - note, may be redundant now coroutines are available.
    }
    dir {}
    file {session database (default session.db)}
    fields {fields in session view}
    cookie {session cookie name (default "session")}
    cpath {session cookie path (default "/" - this default is a bad idea)}
}

namespace eval ::Session {
    variable dir ""
    variable db session.db	;# session database
    variable fields		;# fields in session view
    variable layout {_key:S _ctime:L _mtime:L _slot:I}

    variable salt [clock microseconds]	;# source of random session key
    variable size	;# total count of sessions
    variable empty	;# count of empty slots

    variable cookie "session"	;# session cookie name
    variable cpath "/"		;# session cookie path - this default is a bad idea.

    # traverse the session db clearing old session data
    #
    # we don't remove the rows, because we depend on the slot not changing,
    # however we remove the data from each of the deleted records
    # this should be done occasionally, whenever the db gets too big
    # however, there's a race if new sessions can be made in parallel with gc, so don't.
    proc gc {} {
	set dope {}
	foreach el [session properties] {
	    Debug.session {gc $el}
	    set type [lassign [split $el :] name]
	    lappend dope $name
	    switch $type {
		I - D - F {
		    lappend dope 0
		}
		default {
		    lappend dope {}
		}
	    }
	}

	variable size [session size]
	variable empty 0
	Debug.session {gc size $size}
	set slots [session lselect _key ""]
	Debug.session {gc slot: $slots}
	foreach slot $slots {
	    Debug.session {gc slot $slot}
	    session set $slot {*}$dope _slot $slot
	    incr empty
	}
    }

    # fetch a session slot in a request
    proc fetch {req args} {
	if {[dict exists $req -session]} {
	    # -session exists, ensure that
	    # it's written back to the db by setting --session to empty
	    Debug.session {fetch preset -session ([dict get $req -session])} 10
	    dict set req --session {}
	    return $req
	}

	# no session record in request dict
	set req [Cookies 4Server $req]	;# first get cookies

	variable cookie
	if {[catch {
	    dict get [Cookies fetch [dict get $req -cookies] {*}$args -name $cookie] -value
	} scookie eo]} {
	    # there's no session cookie, we're done
	    Debug.session {fetch failed: no session cookie}
	    return $req
	}

	# got a session cookie
	set slot ""; set key ""
	lassign [split $scookie @] slot key	;# fetch the slot
	if {$key ne ""} {
	    # non null key means session has an active slot
	    if {![catch {
		session get $slot	;# read session from db
	    } session eo]
		&& ([dict get $session _key] eq $key)
	    } {
		dict set req -session $session	;# store the session in the request
		dict set req --session $session	;# copy session to detect changes
	    } else {
		# session keys don't match or no such session
		Debug.session {session cookies didn't match $slot $key ($eo)}
		dict set req -cookies [Cookies clear [dict get $req -cookies] -name $cookie {*}$args]
		catch {dict unset req -session}
		catch {dict unset req --session}
	    }
	}

	Debug.session {fetch -session ([dict get? $req -session])} 10
	return $req
    }

    proc rekey {req slot} {
	variable cpath; variable cookie; variable salt
	set key [md5::md5 -hex [incr salt]]	;# new slot's random key
	session set $slot _key $key
	dict set req -cookies [Cookies modify [dict get $req -cookies] -path $cpath {*}$args -name $cookie -value "$slot@$key"]
	return $req
    }

    variable expires "next month"
    proc attach {req slot} {
	variable cpath; variable cookie; variable expires
	set key [session get $slot _key]
	dict set req -cookies [Cookies add [dict get $req -cookies] -path $cpath -expires $expires {*}$args -name $cookie -value "$slot@$key"]
	return $req
    }

    proc detach {req} {
	variable cookie; variable cpath
	set cookies [Cookies remove [dict get $req -cookies] -name $cookie]
	Debug.session {detach remove '$cookies'}
	catch {dict unset req -session user}
	set cookies [Cookies add [dict get $req -cookies] -path $cpath -max-age 0 -name $cookie -changed 1 -value ""]
	Debug.session {detach expire '$cookies'}
	dict set req -cookies $cookies
	return $req
    }

    # remove the session associated with this request
    proc remove {req} {
	set req [Cookies 4Server $req]	;# fetch the cookies
	if {![dict exists $req -session _slot]} {
	    return $req	;# no session in request, we're done
	}

	Debug.session {remove -session ([dict get $req -session]) --session ([dict get $req --session])} 10
	# there's a session in the request - remove it
	set slot [dict get $req -session _slot]	;# get the session slot
	catch {dict unset req -session}		;# remove -session from request
	catch {dict unset req --session} 	;# remove comparison --session too
	session set $slot _key ""	;# flag session as deleted in the db

	return [detach $req]	;# remove cookies as well as session
    }

    # provide session vars as local vars in caller
    proc with {rv body} {
	Debug.session {with -session ([dict get $req -session])} 10
	if {[catch {
	    uplevel "dict with $rv -session [list $body]"
	} r eo]} {
	    Debug.error {Session with: $r ($eo)}
	} else {
	    return $r
	}
    }

    # store the session in the db if it's changed
    proc store {req args} {
	Debug.session {store -session ([dict get? $req -session]) --session ([dict get? $req --session])} 10
	if {[dict get? $req -session] eq [dict get? $req --session]} {
	    Debug.session {no change to store / code [dict get? $req -code] (C: [dict get? $req -cookies])}
	    return $req	;# no change to session vars - just skip it
	}

	# write back changed -session state
	set req [Cookies 4Server $req]	;# get cookie (redundant?)
	set session [dict get $req -session]	;# get the session

	# change layout to accomodate new fields
	variable fields
	set change 0
	foreach field [dict keys $session] {
	    if {![dict exists $fields $field]} {
		dict set fields $field "$field:S"
		set change 1
	    }
	}
	if {$change} {
	    ::mk::view layout sessdb.session [dict values $fields]
	}

	# locate a slot to store session in
	if {[dict exists $session _slot]} {
	    # session is already stored in db - update record.
	    set slot [dict get $session _slot]	;# remember session slot
	    set key [dict get $session _key]	;# remember session key
	    Debug.session {storing session in old $slot with $key ($session)} 10
	    session set $slot {*}$session _mtime [clock seconds] _slot $slot
	} else {
	    # need to create a new slot for the session
	    variable salt; variable size; variable empty
	    set key [md5::md5 -hex [incr salt]]	;# new slot's random key
	    set now [clock seconds]		;# get current time
	    if {[catch {
		session find _key ""	;# get a deleted session slot
	    } slot]} {
		# no empty slots - create a new slot
		set slot [session append {*}$session _key $key _ctime $now _mtime $now]
		session set $slot _slot $slot	;# fixup session's slot
		incr size
		Debug.session {storing session in new $slot with $key (db size $size) ($session)} 10
	    } else {
		# use a deleted session slot - write session content
		Debug.session {found empty session: [session get $slot]}
		session set $slot {*}$session _key $key _ctime $now _mtime $now _slot $slot
		Debug.session {storing session in empty $slot with $key (db empty $empty size $size) ($session)} 10
		incr empty -1
	    }
	}
	session commit

	# add the accessor cookie to the request
	variable cookie; variable cpath; variable expires
	dict set req -cookies [Cookies add [dict get $req -cookies] -path $cpath -expires $expires {*}$args -name $cookie -value "$slot@$key"]

	Debug.session {cookie added '[dict get? $req -cookies]'}
	return $req
    }

    # find a session matching the given search form
    proc find {r args} {
	set r [store $r]
	if {[catch {
	    session find {*}$args
	} slot]} {
	    catch {dict unset r -store}
	    catch {dict unset r --store}
	} else {
	    dict set r -store [session get $slot]
	    dict set r --store [dict get $r -store]
	}
	return $r
    }

    proc /_snew {r} {
	if {![dict exists $r -session]} {
	    Debug.session {create new empty session}
	    dict set r -session [list _ctime [clock seconds]]
	} else {
	    Debug.session {failed to create new empty session}
	}
	return [Http NoCache [Http Ok $r "Session created" text/plain]]
    }

    # clear the current session cookie
    proc /_sdetach {req} {
	catch {dict unset req -session}; catch {dict unset req --session}
	return [Http NoCache [Http Ok [detach $req] "Session detached" text/plain]]
    }

    # delete current session
    proc /_sdel {req} {
	return [Http NoCache [Http Ok [remove $req] "Session removed" text/plain]]
    }

    if {0} {
	# store content - DANGEROUS DO NOT ENABLE
	proc /_sstore {r args} {
	    dict lappend r -session {*}$args
	    return [Http Redir $r "_sshow"]
	}
    }

    # show current session's values
    proc /_sshow {r} {
	set content [<table> class session border 1 width 80% [subst {
	    [<tr> [<th> "Session"]]
	    [Foreach {n v} [dict get? $r -session] {
		[<tr> "[<td> $n] [<td> [armour $v]]"]
	    }]
	}]]

	return [Http NoCache [Http Ok $r $content x-text/html-fragment]]
    }

    # this is the default wildcard proc for Sessions
    # it does nothing, but it causes the session to be
    # presented to the server
    proc / {r} {
	return [Http NoCache [Http Ok $r "session default" text/plain]]
    }

    # record fields in session view
    proc fields {} {
	variable fields
	foreach field [::mk::view layout sessdb.session] {
	    set type [lassign [split $field :] name]
	    if {$type eq ""} {
		set type S
	    }
	    dict set fields $name "$name:$type"
	}
    }

    variable direct

    # initialize the session accessor functions
    proc init {args} {
	variable file [file join [file dirname [info script]] session.db]
	variable {*}[Site var? Session]	;# allow .ini file to modify defaults
	if {$args ne {}} {
	    variable {*}$args
	}

	variable file; variable layout
	variable direct
	if {![info exists direct]} {
	    View create session file $file db sessdb view session layout $layout
	    fields
	    gc	;# start up by garbage collecting Session db.
	}
    }

    proc create {name args} {
	init {*}$args
	variable direct [Direct create $name {*}$args namespace ::Session]
	return $direct
    }
    proc new {args} {
	init {*}$args

	variable direct [Direct new {*}$args namespace ::Session]
	return $direct
    }
    proc destroy {} {
	variable direct
	$direct destroy
    }
    namespace export -clear *
    namespace ensemble create -subcommands {}
}
