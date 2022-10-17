# Tub is a direct domain which allows storage of arbitrary form data

package require OO

set ::API(Domains/Tub) {
    {
	Domain for storage and retrieval of arbitrary form data
    }
    view {View within which to store data (no default)}
    key {key within view which uniquely identifies store (default "user")}
    realm {Realm used in password challenges}
    cookie {cookie for storing key}
    age {cookie age}
    permissive {boolean - will storing under a new key create record?}
    emptypass {boolean - are passwords required to be non-blank (default: 0, of course)}
}

package require Debug
Debug define tub 10

package require Direct
package require View
package require Cookies

package provide Tub 1.0

class create ::Tub {
    variable view realm key properties cookie age permissive emptypass
    
    # get the data given by key
    method get {r k} {
	if {[catch {$view find $key $k} index eo]} {
	    return [Http NotFound $r]
	}
	set record [$view get $index]

	# handle conditional request
	if {[dict exists $record timestamp]} {
	    set when [dict get $record timestamp]
	    if {[dict exists $r if-modified-since]} {
		set since [Http DateInSeconds [dict get $r if-modified-since]]
		if {$when <= $since} {
		    Debug.file {NotModified: $path - [Http Date [file mtime $path]] < [dict get $r if-modified-since]}
		    Debug.file {if-modified-since: not modified}
		    return [Http NotModified $r]
		}
	    }
	}
	
	if {[dict exists $record args]} {
	    set a [dict get $record args]
	    dict unset record args
	    set record [dict merge $record $args]
	}

	# convert dict to json
	set result {}
	dict for {n v} $d {
	    lappend result "\"$n\": \"$v\""
	}
	set result \{[join $result ,\n]\}

	if {[info exists when]} {
	    return [Http CacheableContent $r $result]
	} else {
	    return [Http Ok $R $result]
	}
    }

    method set {r key args} {
	if {[catch {$view find $key $k} index]} {
	    if {$permissive} {
		# create a new element
		set index [$view append $key $k]
	    } else {
		return [Http NotFound $r]
	    }
	}

	set record {}
	foreach p in $properties {
	    if {$p eq "args"} continue
	    if {[info exists $args $p]} {
		dict set record $p [dict get $args $p]
		dict unset args $p
	    }
	    if {$p eq "timestamp"} {
		# record timestamp
		dict set record $p [clock seconds]
	    }
	}

	dict set record args $args
	$view set $index {*}$record
	return [Http Ok $index]
    }

    method /get {r args} {
	if {![info exists $args $key]} {
	    error "No key to Tub."
	}
	set k [dict get $args $key]
	dict unset args $key
	return [my get $r [dict get $args $k] {*}$args]
    }

    method /set {r args} {
	if {![info exists $args $key]} {
	    error "No key to Tub."
	}
	set k [dict get $args $key]
	catch {dict unset args $key}
	return [my set $r [dict get $args $k] {*}$args]
    }

    method /getUser {r} {
	lassign [Http Credentials $r] userid pass
	if {[catch {$view find $key $userid} index]
	    || $userid eq ""
	    || (!$emptypass && $pass eq "")
	    || [$view get $index password] ne $password
	} {
	    return [challenge $r $realm]
	}
	return [my get $r $userid]
    }

    method /setUser {r args} {
	lassign [Http Credentials $r] userid pass
	if {[catch {$view find $key $userid} index]} {
	    if {$permissive && $userid ne "" && $pass ne ""} {
		set index [$view append $key $userid]
	    } else {
		return [challenge $r $realm]
	    }
	}
	if {$userid eq ""
	    || (!$emptypass && $pass eq "")
	    || [$view get $index password] ne $pass
	} {
	    return [challenge $r $realm]
	}
	catch {dict unset args $key}
	return [my set $r $userid {*}$args]
    }

    method /loginbox {r} {
	set r [Cookies 4server $r]
	lassign [Cookie fetch [dict get $r -cookies]] userid pass
	if {[catch {$view find $key $userid} index]} {
	    return [Http NotFound $r "There is no such user as '$userid'"]
	}

	return [my get $r $userid]
    }

    method /login {r userid {password ""} {url ""}} {
	# prelim check on args
	if {$userid eq ""} {
	    return [Http NotFound $r "Blank username not permitted."]
	}
	if {!$emptypass && $password eq ""} {
	    return [Http NotFound $r "Blank password not permitted."]
	}

	# find matching userid in view
	if {[catch {$view find $key $userid} index]} {
	    if {$permissive && $userid ne "" && $password ne ""} {
		# permissive - create a new user
		set index [$view append $key $userid password $password]
	    } else {
		return [Http NotFound $r "There is no such user as '$userid'"]
	    }
	}

	if {password in $properties} {
	    # we're storing passwords in this view, so match them
	    if {[$view get $index password] ne $password} {
		return [Http NotFound $r "Passwords don't match for '$userid'"]
	    }
	}
	
	# got a password match. set up cookie with the appropriate value
	set r [Cookies 4server $r]

	if {[dict exists $r -cookies]} {
	    set cdict [dict get $r -cookies]
	} else {
	    set cdict {}
	}

	# include an optional expiry age for the cookie
	if {$age} {
	    set expiry [list -expires $age]
	} else {
	    set expiry {}
	}

	# add in the cookie
	set cdict [Cookies add $cdict -path $mount -name $cookie -value [list $userid $password] {*}$expiry]
	dict set r -cookies $cdict

	if {$url eq ""} {
	    set url [Http Referer $r]
	    if {$url eq ""} {
		set url "http://[dict get $r host]/"
	    }
	}

	return [Http NoCache [Http SeeOther $r $url "Logged in as $userid"]]
    }

    method /logout {r {url ""}} {
	# clear out the cookie
	set r [Cookies 4server $r]
	dict set r -cookies [Cookie clear [dict get $r -cookies] -name $cookie]

	if {$url eq ""} {
	    set url [Http Referer $r]
	    if {$url eq ""} {
		set url "http://[dict get $r host]/"
	    }
	}

	return [Http NoCache [Http SeeOther $r $url "Logged out"]]
    }

    # get store with cookie
    method /getCookie {r} {
	set r [Cookies 4server $r]
	lassign [Cookie fetch [dict get $r -cookies]] userid pass
	if {[catch {$view find $key $userid} index]} {
	    return [Http NotFound $r "There is no such user as '$userid'"]
	}

	return [my get $r $userid]
    }

    method /setCookie {r args} {
	set r [Cookies 4server $r]
	lassign [Cookie fetch [dict get $r -cookies]] userid pass
	if {[catch {$view find $key $userid} index]} {
	    return [Http NotFound $r "There is no such user as '$userid'"]
	}
	catch {dict unset args $key}	;# can't change key
	return [my set $r $userid {*}$args]
    }

    superclass Direct

    constructor {args} {
	set realm "Tub [self] Realm"
	set permissive 0
	set key user
	set cookie tub
	set emptypass 0
	variable {*}[Site var? Tub]	;# allow .ini file to modify defaults

	dict for {n v} $args {
	    set $n $v
	}

	# create the data view
	if {[llength $view] > 1} {
	    if {[llength $view]%2} {
		set view [View create {*}$view]
	    } else {
		set view [View new {*}$view]
	    }
	}

	set properties [$view properties]

	if {![info exists key] || $key eq ""} {
	    if {[info exists cookie] && $cookie ne ""} {
		set key $cookie
	    } else {
		set properties [lassign [lindex $properties 0] key]
	    }
	} elseif {$key ni $properties} {
	    error "Key $key must appear in $view's layout ($properties)"
	}

	# this is the means by which we're invoked.
	next? {*}$args ctype application/json
    }
}
