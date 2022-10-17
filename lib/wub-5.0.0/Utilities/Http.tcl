# Http.tcl - useful utilities for an Http server.
#
# Contains procs to generate most useful HTTP response forms.

package require ip
package require Html
package require Url
package require Mime
package require md5

package require Debug
Debug define caching

package provide Http 2.1

set ::API(Utilities/Http) {
    {
	HTTP response generator and reply analyser

	Used to create HTTP responses in dict form.
    }
}

proc Trace {{skip 1}} {
    set result {}
    for {set level [expr {[info level] - $skip}]} {$level >= 0} {incr level -1} {
	lappend result [info level $level]
    }
    return $result
}

# translation -- 
#
#	fconfigure the connected socket into a given mode
#
# Arguments:
#	args	additional args to fconfigure
#
# Side Effects:
#	sets the connected socket to the given mode

proc translation {sock args} {
    set additional {}
    for {set i 0} {$i < [llength $args]} {incr i} {
	set a [lindex $args $i]
	switch -glob -- $a {
	    -r* {
		incr i
		set rmode [lindex $args $i]
	    }
	    -w* {
		incr i
		set wmode [lindex $args $i]
	    }
	    default {
		lappend additional $a
	    }
	}
    }

    lassign [fconfigure $sock -translation] crm cwm

    if {[info exists rmode] && ($crm ne $rmode)} {
	Debug.socket {$sock read mode to $rmode} 20
    } else {
	set rmode $crm
    }

    if {[info exists wmode] && ($cwm ne $wmode)} {
	Debug.socket {$sock write mode to $wmode} 20
    } else {
	set wmode $cwm
    }

    fconfigure $sock -translation [list $rmode $wmode] {*}$additional
    Debug.socket {MODE: $rmode $wmode} 20
}

namespace eval ::Http {
    # HTTP error codes and default textual interpretation
    variable Errors
    array set Errors {
	1 "Informational - Request received, continuing process"
	100 Continue
	101 "Switching Protocols"

	2 "Success - received, understood, and accepted"
	200 OK
	201 Created
	202 Accepted
	203 "Non-Authoritative Information"
	204 "No Content"
	205 "Reset Content"
	206 "Partial Content"

	3 "Redirection - Further action needed"
	300 "Multiple Choices"
	301 "Moved Permanently"
	302 "Found"
	303 "See Other"
	304 "Not Modified"
	305 "Use Proxy"
	307 "Temporary Redirect"

	4 "Client Error - request bad or cannot be fulfilled"
	400 "Bad Request"
	401 "Unauthorized"
	402 "Payment Required"
	403 "Forbidden"
	404 "Not Found"
	405 "Method Not Allowed"
	406 "Not Acceptable"
	407 "Proxy Authentication Required"
	408 "Request Time-out"
	409 "Conflict"
	410 "Gone"
	411 "Length Required"
	412 "Precondition Failed"
	413 "Request Entity Too Large"
	414 "Request-URI Too Large"
	415 "Unsupported Media Type"
	416 "Requested range not satisfiable"
	417 "Expectation Failed"

	5 "Server Error - Server failed to fulfill an apparently valid request"
	500 "Internal Server Error"
	501 "Not Implemented"
	502 "Bad Gateway"
	503 "Service Unavailable"
	504 "Gateway Time-out"
	505 "HTTP Version not supported"
    }

    # categorise headers
    variable headers
    variable notmod_headers {
	date expires cache-control vary etag content-location
    }

    # set of request-only headers
    variable rq_headers {
	accept accept-charset accept-encoding accept-language authorization
	expect from host if-match if-modified-since if-none-match if-range
	if-unmodified-since max-forwards proxy-authorization referer te
	user-agent keep-alive cookie via range
	origin sec-websocket-key1 sec-websocket-key2
    }
    foreach n $rq_headers {
	set headers($n) rq
    }

    # set of response-only headers
    variable rs_headers {
	accept-ranges age etag location proxy-authenticate retry-after
	server vary www-authenticate content-disposition content-range
    }
    foreach n $rs_headers {
	set headers($n) rs
    }

    # set of entity-only headers
    variable e_headers {
	allow content-encoding content-language content-length 
	content-location content-md5 content-range content-type
	expires last-modified cache-control connection date pragma
	trailer transfer-encoding upgrade warning
    }
    foreach n $e_headers {
	set headers($n) e
    }

    # clf - common log format
    proc clf {r} {
	lappend line [dict get $r -ipaddr]	;# remote IP
	lappend line -	;# RFC 1413 identity of the client.  'sif
	set user [dict get? $r -user]	;# is there a user identity?
	if {$user ne ""} {
	    lappend line $user
	} else {
	    lappend line -
	}

	# receipt time of connection
	lappend line \[[clock format [dict get $r -received_seconds] -format "%d/%b/%Y:%T %Z"]\]

	# first line of request
	lappend line \"[dict get? $r -header]\"

	# status we returned to it
	if {[dict exists $r -code]} {
	    lappend line [dict get $r -code]
	} else {
	    lappend line 200
	}

	# content byte length
	lappend line [string length [dict get? $r -content]]

	# referer, useragent, cookie, if any
	lappend line \"[dict get? $r referer]\"
	lappend line \"[dict get? $r user-agent] ([dict get? $r -ua_class])\"
	if {[dict exists $r -user]} {
	    lappend line \"[dict get? $r -user]\"
	} elseif {[dict exists $r -human]} {
	    lappend line \"[dict get? $r -human]\"
	} else {
	    lappend line \"[dict get? $r cookie]\"
	}

	if {[dict exists $r -received] && [dict exists $r -sent]} {
	    set diff [expr {[dict get $r -sent] - [dict get $r -received]}]
	    if {$diff > 1000000} {
		Debug.slow {SLOW ($diff uS): ([dict get? $r -behaviour]) [dumpMsg $r]}
	    }
	    lappend line \"$diff [dict get? $r -htime]\"
	}

	lappend line \"[dict get? $r -forwards]\"

	return [string map {\n \\n \r \\r} [join $line]]
    }

    # map http error code to human readable message
    proc ErrorMsg {code} {
	variable Errors
	if {[info exist Errors($code)]} {
	    return $Errors($code)
	} else {
	    return "Error $code"
	}
    }

    # return an HTTP date
    proc DateInSeconds {date} {
	if {[string is integer -strict $date]} {
	    return $date
	} elseif {[catch {clock scan $date \
			-format {%a, %d %b %Y %T GMT} \
			-gmt true} result eo]} {
	    #error "DateInSeconds '$date', ($result)"
	    return 0	;# oldest possible date
	} else {
	    return $result
	}
    }

    # return an HTTP date
    proc Date {{seconds ""}} {
	if {$seconds eq ""} {
	    set seconds [clock seconds]
	}

	return [clock format $seconds -format {%a, %d %b %Y %T GMT} -gmt true]
    }

    # return the current time and date in HTTP format
    proc Now {} {
	return [clock format [clock seconds] -format {%a, %d %b %Y %T GMT} -gmt true]
    }

    proc md5file {path {bufsz 16384}} {
	set chan [open $path]
	fconfigure $chan -translation binary
	set tok [md5::MD5Init]
	while {![chan eof $chan]} {
	    md5::MD5Update $tok [read $chan $bufsz]
	}
	close $chan
	return [md5::Hex [md5::MD5Final $tok]]
    }

    # Coerce return type to a given mime type
    proc coerce {r mime} {
	dict set r accept $mime
	return $r
    }
    proc coerceTo {r ext} {
	# calculate the desired content-type
	set mime [Mime MimeOf [string tolower $ext]]
	if {$mime eq "" || $mime eq "text/plain"} {
	    return $r	;# no change
	}
	dict set r accept $mime	;# we coerce the acceptable types
	return $r
    }

    proc Continue {r} {
	dict set r -code 100
	return $r
    }

    proc Switching {r content} {
	dict set r -code 101
	dict set r -content $content
	dict set r content-length [string length $content]
	return $r
    }

    # give the response an inline disposition
    proc Inline {r filename} {
	dict set r content-disposition "inline; filename=\"$filename\""
	return $r
    }

    # give ther response an attachment disposition
    proc Attachment {r filename} {
	dict set r content-disposition "attachment; filename=\"$filename\""
	return $r
    }

    # give the response the nominate $disposition
    proc ContentDisposition {r disposition filename} {
	dict set r content-disposition "$disposition; filename=\"$filename\""
	return $r
    }

    # content is a file
    proc File {rsp path {ctype ""}} {
	set path [file normalize $path]
	dict set rsp -file $path

	if {$ctype eq ""} {
	    dict set rsp content-type [Mime magic path $path]
	} else {
	    dict set rsp content-type $ctype
	}

	dict set rsp -code 200
	dict set rsp -rtype File
	return $rsp
    }

    # modify response so it will not be returned to client
    proc Suspend {rsp} {
	Debug.log {Suspend [dict merge $rsp {-content <elided>}]}
	dict set rsp -suspend 1
	return $rsp
    }

    # content is a cacheable file
    proc CacheableFile {rsp path {ctype ""}} {
	set path [file normalize $path]
	dict set rsp -file $path

	# set the file mod time
	set mtime [file mtime $path]
	dict set rsp -modified $mtime
	dict set rsp last-modified [Date $mtime]
	dict set rsp -dynamic 0	;# signal that we can cache this

	# ensure the response has a mime-type
	if {$ctype eq ""} {
	    # calculate content-type using mime guessing
	    if {[dict get? $rsp content-type] eq ""} {
		dict set rsp content-type [Mime magic path $path]
	    }
	} else {
	    dict set rsp content-type $ctype
	}

	dict set rsp -code 200
	dict set rsp -rtype CacheableFile

	Debug.caching {CacheableFile: last-modified '[dict get $rsp last-modified]'}
	#catch {dict unset rsp -content}
	return $rsp
    }

    # contents may not be Cached
    proc NoCache {rsp} {
	dict set rsp cache-control "no-store, no-cache, must-revalidate, max-age=0, post-check=0, pre-check=0"; # HTTP/1.1
	dict set rsp expires "Sun, 01 Jul 2005 00:00:00 GMT"	;# deep past
	dict set rsp pragma "no-cache"	;# HTTP/1.0
	dict set rsp -dynamic 1
	catch {dict unset rsp -modified}
	catch {dict unset rsp -depends}
	#catch {dict unset rsp last-modified}
	Debug.caching {NoCache}
	return $rsp
    }

    # contents may be Cached
    proc Cache {rsp {age 0} {realm ""}} {
	if {[string is integer -strict $age]} {
	    # it's an age
	    if {$age != 0} {
		dict set rsp expires [Date [expr {[clock seconds] + $age}]]
		Debug.caching {Http Cache: numeric age expires '[dict get $rsp expires]'}
	    } else {
		Debug.caching {Http Cache: turn off expires}
		catch {dict unset rsp expires}
		catch {dict unset rsp -expiry}
	    }
	} else {
	    dict set rsp -expiry $age	;# remember expiry verbiage for caching
	    dict set rsp expires [Date [clock scan $age]]
	    Debug.caching {Http Cache: text age expires '$age' - '[dict get $rsp expires]'}
	    set age [expr {[clock scan $age] - [clock seconds]}]
	}
	dict set rsp -dynamic 0	;# signal that we can cache this

	if {$realm ne ""} {
	    dict set rsp cache-control $realm
	}

	if {$age} {
	    if {[dict exists $rsp cache-control]} {
		dict append rsp cache-control ",max-age=$age"
	    } else {
		dict set rsp cache-control "max-age=$age"
	    }
	}

	Debug.caching {Http Cache: ($age) cache-control: [dict get? $rsp cache-control]}
	return $rsp
    }

    # Dynamic cache - contents, while cacheable, must be revalidated
    proc DCache {rsp {age 0} {realm ""}} {
	set rsp [Cache $rsp $age $realm]
	if {[dict exists $rsp cache-control]} {
	    dict append rsp cache-control ",must-revalidate"
	} else {
	    dict set rsp cache-control "must-revalidate"
	}
	Debug.caching {DCache: [dict get? $rsp cache-control]}

	return $rsp
    }

    # set default content type if needed
    proc setCType {rsp ctype} {
	# new ctype passed in?
	if {$ctype ne ""} {
	    dict set rsp content-type $ctype
	} elseif {![dict exists $rsp content-type]} {
	    dict set rsp content-type "text/html"
	}
	return $rsp
    }

    # content is cacheable
    proc CacheableContent  {rsp mtime {content ""} {ctype ""}} {
	# cacheable content must have last-modified
	if {![dict exists $rsp last-modified]} {
	    dict set rsp last-modified [Date $mtime]
	}
	dict set rsp -modified $mtime

	#if {![dict exists $rsp cache-control]} {
	#    dict set rsp cache-control public
	#}

	# Cacheable Content may have an -expiry clause
	if {[dict exists $rsp -expiry]} {
	    dict set rsp expires [Date [clock scan [dict get $rsp -expiry]]]
	}

	# new content passed in?
	if {$content ne ""} {
	    dict set rsp -content $content
	}

	set rsp [setCType $rsp $ctype]; # new ctype passed in?

	# new code passed in?
	if {![dict exists $rsp -code]} {
	    dict set rsp -code 200
	}
	catch {dict unset rsp -dynamic}
	dict set rsp -rtype CacheableContent	;# tag the response type
	return $rsp
    }

    # construct a generic Ok style response form
    proc OkResponse {rsp code rtype {content ""} {ctype ""}} {
	if {$content ne ""} {
	    dict set rsp -content $content
	} elseif {![dict exists $rsp -content]} {
	    dict set rsp content-length 0
	}

	set rsp [setCType $rsp $ctype]; # new ctype passed in?

	dict set rsp -code $code
	dict set rsp -rtype Ok
	return $rsp
    }

    # construct an HTTP Ok response
    proc Ok {rsp {content ""} {ctype ""}} {
	if {[dict exists $rsp -code]} {
	    set code [dict get $rsp -code]
	} else {
	    set code 200
	}
	return [OkResponse $rsp $code Ok $content $ctype]
    }

    # construct an HTTP Ok response of dynamic type (turn off caching)
    proc Ok+ {rsp {content ""} {ctype "x-text/html-fragment"}} {
	if {[dict exists $rsp -code]} {
	    set code [dict get $rsp -code]
	} else {
	    set code 200
	}
	return [OkResponse [Http NoCache $rsp] $code Ok $content $ctype]
    }

    # construct an HTTP passthrough response
    # this is needed if we already have a completed response and just want to
    # substitute content.  [Http Ok] does too much.
    proc Pass {rsp {content ""} {ctype ""}} {
	if {![dict exists $rsp -code]} {
	    dict set rsp -code 200
	}
	return [OkResponse $rsp [dict get $rsp -code] Ok $content $ctype]
    }

    # construct an HTTP Created response
    proc Created {rsp location} {
	dict set rsp -code 201
	dict set rsp -rtype Created
	dict set rsp location $location	;# location of created entity

	# unset the content components
	catch {dict unset rsp -content}
	catch {dict unset rsp content-type}
	dict set rsp content-length 0

	dict set rsp -dynamic 1	;# prevent caching
	dict set rsp -raw 1	;# prevent conversion

	return $rsp
    }

    # construct an HTTP Accepted response
    proc Accepted {rsp {content ""} {ctype ""}} {
	return [OkResponse $rsp 202 Accepted $content $ctype]
    }

    # construct an HTTP NonAuthoritative response
    proc NonAuthoritative {rsp {content ""} {ctype ""}} {
	return [OkResponse $rsp 203 NonAuthoritative $content $ctype]
    }

    # construct an HTTP NoContent response
    proc NoContent {rsp} {
	foreach el {content-type -content -fd} {
	    catch [list dict unset rsp $el]
	}

	dict set rsp -code 204
	dict set rsp -rtype NoContent

	return $rsp
    }

    # construct an HTTP ResetContent response
    proc ResetContent {rsp {content ""} {ctype ""}} {
	return [OkResponse $rsp 205 ResetContent $content $ctype]
    }

    # construct an HTTP PartialContent response
    # TODO - actually support this :)
    proc PartialContent {rsp {content ""} {ctype ""}} {
	return [OkResponse $rsp 206 PartialContent $content $ctype]
    }

    # set the title <meta> tag, assuming we're returning fragment content
    proc title {r title} {
	if {[string length $title] > 80} {
	    set title [string range $title 0 80]...
	}
	dict set r -title $title
	return $r
    }

    # sysPage - generate a 'system' page
    proc sysPage {rsp title content} {
	dict set rsp content-type "x-text/system"
	set rsp [title $rsp $title]
	dict set rsp -content "[<h2> $title]\n$content"
	dict lappend rsp -headers "[<style> type text/css {
	  html * { padding:0; margin:0; }
	  body * { padding:10px 20px; }
	  body * * { padding:0; }
	  body { font:small sans-serif; }
	  body>div { border-bottom:1px solid #ddd; }
	  h1 { font-weight:normal; }
	  h2 { margin-bottom:.8em; }
	  h2 span { font-size:80%; color:#666; font-weight:normal; }
	  h3 { margin:1em 0 .5em 0; }
	  table { 
		  border:1px solid #ccc; border-collapse: collapse; background:white; }
	  tbody td, tbody th { vertical-align:top; padding:2px 3px; }
	  thead th { 
		  padding:1px 6px 1px 3px; background:#fefefe; text-align:left; 
		  font-weight:normal; font-size:11px; border:1px solid #ddd; }
	  tbody th { text-align:right; color:#666; padding-right:.5em; }
	  table.errorinfo { margin:5px 0 2px 40px; }
	  table.errorinfo td, table.dict td { font-family:monospace; }
	  #summary { background: #ffc; }
	  #summary h2 { font-weight: normal; color: #666; }
	  #errorinfo { background:#eee; }
	  #details { background:#f6f6f6; padding-left:120px; }
	  #details h2, #details h3 { position:relative; margin-left:-100px; }
	  #details h3 { margin-bottom:-1em; }
	}]"
	return $rsp
    }

    # construct an HTTP response containing a server error page
    proc ServerError {rsp message {eo ""}} {
	Debug.error {Server Error: '$message' ($eo) [dumpMsg $rsp]} 2
	set content ""

	dict set rsp -code 500
	dict set rsp -rtype Error
	dict set rsp -dynamic 1
	    
	if {[catch {
	    if {$eo ne ""} {
		append content [<h2> "Error Code '[dict get? $eo -errorcode]'"]
		catch {dict unset eo -errorcode}
		
		append content [<pre> [armour [dict get? $eo -errorinfo]]]
		catch {dict unset eo -errorinfo}

		#append table [<thead> "[<th> Variable] [<th> Value]"] \n
		append table <tbody>

		foreach {n1 v1} [dict get? $eo -errorstack] {
		    append table [<tr> "[<td> $n1] [<td> [armour $v1]]"] \n
		}

		dict unset eo -errorstack

		dict for {n v} $eo {
		    append table [<tr> "[<td> $n] [<td> [<pre> [armour $v]]]"] \n
		}
		append table </tbody>
		append content [<table> class errorinfo $table] \n
	    }
	    
	    catch {append content [<p> "Caller: [<code> [armour [info level -1]]]"]}
	    set message [armour $message]
	    catch {dict unset rsp expires}
	    if {[string length $message] > 80} {
		set tmessage [string range $message 0 80]...
	    } else {
		set tmessage $message
	    }

	    # make this an x-system type page
	    set rsp [sysPage $rsp "Server Error: $tmessage" [subst {
		[<div> id summary [tclarmour $message]]
		[<div> id errorinfo [tclarmour $content]]
		[tclarmour [dump $rsp]]
	    }]]
 
	    # Errors are completely dynamic - no caching!
	    set rsp [NoCache $rsp]
	} r1 eo1]} {
	    Debug.error {Recursive ServerError $r1 ($eo1) from '$message' ($eo)}
	} else {
	    Debug.http {ServerError [dumpMsg $rsp 0]}
	}

	return $rsp
    }

    # construct an HTTP NotImplemented response
    proc NotImplemented {rsp {message ""}} {
	if {$message eq ""} {
	    set message "This function not implemented"
	} else {
	    append message " - Not implemented."
	}

	set rsp [sysPage $rsp "Not Implemented" [<p> $message]]

	dict set rsp -code 501
	dict set rsp -rtype NotImplemented
	dict set rsp -error $message

	return $rsp
    }

    # construct an HTTP Unavailable response
    proc Unavailable {rsp message {delay 0}} {
	set rsp [sysPage $rsp "Service Unavailable" [<p> $message]]

	dict set rsp -code 503
	dict set rsp -rtype Unavailable
	if {$delay > 0} {
	    dict set rsp retry-after $delay
	}
	return $rsp
    }

    proc GatewayTimeout {rsp message} {
	set rsp [sysPage $rsp "Service Unavailable" [<p> $message]]

	dict set rsp -code 504
	dict set rsp -rtype GatewayUnavailable

	return $rsp
    }

    # construct an HTTP Bad response
    proc Bad {rsp message {code 400}} {
	set rsp [sysPage $rsp "Bad Request" [<p> $message]]

	dict set rsp -code $code
	dict set rsp -rtype Bad
	dict set rsp -error $message

	return $rsp
    }

    # construct an HTTP NotFound response
    proc NotFound {rsp {content ""} {ctype "x-text/system"}} {
	if {$content ne ""} {
	    dict set rsp -content $content
	    dict set rsp content-type $ctype
	} elseif {![dict exists $rsp -content]} {
	    set uri [dict get $rsp -uri]
	    set rsp [sysPage $rsp "$uri Not Found" [<p> "The entity '$uri' doesn't exist."]]
	}

	dict set rsp -code 404
	dict set rsp -rtype NotFound

	return $rsp
    }

    # construct an HTTP Forbidden response
    proc Forbidden {rsp {content ""} {ctype "x-text/html-fragment"}} {
	if {$content ne ""} {
	    dict set rsp -content $content
	    dict set rsp content-type $ctype
	} elseif {![dict exists $rsp -content]} {
	    set rsp [sysPage $rsp "Access Forbidden" [<p> "You are not permitted to access this page."]]
	}

	dict set rsp -code 403
	dict set rsp -rtype Forbidden

	return $rsp
    }

    proc BasicAuth {realm} {
	return "Basic realm=\"$realm\""
    }

    proc Credentials {r args} {
	if {![dict exists $r authorization]} {
	    return ""
	}
	set cred [join [lassign [split [dict get $r authorization]] scheme]]
	package require base64
	if {[llength $args]} {
	    return [{*}$args $userid $password]
	} else {
	    return [split [::base64::decode $cred] :]
	}
    }

    proc CredCheck {r checker} {
	lassign [Credentials $r] userid password
	return [{*}$checker $userid $password]
    }

    # construct an HTTP Unauthorized response
    proc Unauthorized {rsp {challenge ""} {content ""} {ctype "x-text/html-fragment"}} {
	if {$challenge ne ""} {
	    dict set rsp WWW-Authenticate $challenge
	}
	if {$content ne ""} {
	    dict set rsp -content $content
	    dict set rsp content-type $ctype
	} elseif {![dict exists $rsp -content]} {
	    set rsp [sysPage $rsp Unauthorized [<p> "You are not permitted to access this page."]]
	}

	dict set rsp -code 401
	dict set rsp -rtype Unauthorized

	return $rsp
    }

    # construct an HTTP Conflict response
    proc Conflict {rsp {content ""} {ctype "x-text/system"}} {
	if {$content ne ""} {
	    dict set rsp -content $content
	    dict set rsp content-type $ctype
	} elseif {![dict exists $rsp -content]} {
	    set rsp [sysPage $rsp Conflict [<p> "Conflicting Request"]]
	}

	dict set rsp -code 409
	dict set rsp -rtype Conflict
	return $rsp
    }

    # construct an HTTP PreconditionFailed response
    proc PreconditionFailed {rsp {content ""} {ctype "x-text/system"}} {
	if {$content ne ""} {
	    dict set rsp -content $content
	    dict set rsp content-type $ctype
	}

	dict set rsp -code 412
	dict set rsp -rtype PreconditionFailed
	return $rsp
    }

    # construct an HTTP NotModified response
    proc NotModified {rsp} {
	# remove content-related stuff
	foreach n [dict keys $rsp content-*] {
	    if {$n ne "content-location"} {
		dict unset rsp $n
	    }
	}

	# discard some fields
	set rsp [dict ni $rsp transfer-encoding -chunked -content]

	# the response MUST NOT include other entity-headers
	# than Date, Expires, Cache-Control, Vary, Etag, Content-Location
	set result [dict filter $rsp key -*]

	variable rq_headers
	set result [dict merge $result [dict in $rsp $rq_headers]]

	variable notmod_headers
	set result [dict merge $result [dict in $rsp $notmod_headers]]

	# tell the other end that this isn't the last word.
	if {0 && ![dict exists $result expires]
	    && ![dict exists $result cache-control]
	} {
	    dict set result cache-control "must-revalidate"
	}

	dict set result -code 304
	dict set result -rtype NotModified

	return $result
    }

    # internal redirection generator
    proc genRedirect {title code rsp to {content ""} {ctype "text/html"} args} {
	set to [Url redir $rsp $to {*}$args]

	if {$content ne ""} {
	    dict set rsp -content $content
	    dict set rsp content-type $ctype
	} else {
	    dict set rsp -content [<html> {
		[<head> {[<title> $title]}]
		[<body> {
		    [<h1> $title]
		    [<p> "The page may be found here: <a href='[armour $to]'>[armour $to]"]
		}]
	    }]
	    dict set rsp content-type "text/html"
	}

	if {0} {
	    if {![string match {http:*} $to]} {
		# do some munging to get a URL
		dict set rsp location $rsp [Url redir $rsp $to]
	    } else {
		dict set rsp location $to
	    }
	}

	dict set rsp location $to
	dict set rsp -code $code
	dict set rsp -rtype $title

	dict set rsp -dynamic 1	;# don't cache redirections

	return $rsp
    }

    # discover Referer of request
    proc Referer {req} {
	if {[dict exists $req referer]} {
	    return [dict get $req referer]
	} else {
	    return ""
	}
    }

    # construct an HTTP Redirect response
    proc Redirect {rsp {to ""} {content ""} {ctype "text/html"} args} {
	if {$to eq ""} {
	    set to [dict get $rsp -url]
	}
	return [Http genRedirect Redirect 302 $rsp $to $content $ctype {*}$args]
    }

    # construct a simple HTTP Redirect response with extra query
    proc Redir {rsp to args} {
	return [Http genRedirect Redirect 302 $rsp $to "" "" {*}$args]
    }

    # construct an HTTP Redirect response to Referer of request
    proc RedirectReferer {rsp {content ""} {ctype ""} args} {
	set ref [Referer $rsp]
	if {$ref eq ""} {
	    set ref /
	}
	return [Http genRedirect Redirect 302 $rsp $ref $content $ctype {*}$args]
    }

    # construct an HTTP Found response
    proc Found {rsp to {content ""} {ctype "text/html"} args} {
	return [Http genRedirect Redirect 302 $rsp $to $content $ctype {*}$args]
    }

    # construct an HTTP Relocated response
    proc Relocated {rsp to {content ""} {ctype "text/html"} args} {
	return [Http genRedirect Relocated 307 $rsp $to $content $ctype {*}$args]
    }
    
    # construct an HTTP SeeOther response
    proc SeeOther {rsp to {content ""} {ctype "text/html"} args} {
	return [Http genRedirect SeeOther 303 $rsp $to $content $ctype {*}$args]
    }

    # construct an HTTP Moved response
    proc Moved {rsp to {content ""} {ctype "text/html"} args} {
	return [Http genRedirect Moved 301 $rsp $to $content $ctype {*}$args]
    }
    
    # loadContent -- load a response's file content 
    #	used when the content must be transformed
    #
    # Arguments:
    #	rsp	a response dict
    #
    # Side Effects:
    #	loads the content of a response file descriptor
    #	Possibly close socket

    proc loadContent {rsp} {
	# if rsp has -fd content and no -content
	# we must read the entire file to convert it
	if {[dict exists $rsp -fd]} {
	    if {![dict exists $rsp -content]} {
		if {[catch {
		    set fd [dict get $rsp -fd]
		    fconfigure $fd -translation binary
		    read $fd
		} content eo]} {
		    # content couldn't be read - serious error
		    set rsp [Http ServerError $rsp $content $eo]
		} else {   
		    dict set rsp -content $content
		}

		if {![dict exists $rsp -fd_keep_open]} {
		    # user can specify fd is to be kept open
		    catch {close $fd}
		    dict unset rsp -fd
		} else {
		    seek $fd 0	;# re-home the fd
		}
	    }
	} elseif {![dict exists $rsp -content]} {
	    error "expected content"
	}

	return $rsp
    }

    # dump the context
    proc dump {req {short 1}} {
	catch {
	    set table [<thead> [<tr> "[<th> Variable] [<th> Value]"]]\n
		append table <tbody>
	    foreach n [lsort [dict keys $req -*]] {
		if {$short && ($n eq "-content")} continue
		append table [<tr> "[<td> $n] [<td> [armour [dict get $req $n]]]"] \n
	    }
		append table </tbody>
	    append c [<h3> Metadata] \n
	    append c [<table> class dict $table] \n
	    
	    set table [<thead> [<tr> "[<th> Variable] [<th> Value]"]]\n
		append table <tbody>
	    foreach n [lsort [dict keys $req {[a-zA-Z]*}]] {
		append table [<tr> "[<td> $n] [<td> [armour [dict get $req $n]]]"] \n
	    }
		append table </tbody>
	    append c [<h3> HTTP] \n
	    append c [<table> class dict $table] \n

	    set table [<thead> [<tr> "[<th> Variable] [<th> Value]"]]\n
	    array set q [Query flatten [Query parse $req]]
	    foreach {n} [lsort [array names q]] {
		append table [<tr> "[<td> [armour $n]] [<td> [armour $q($n)]]"] \n
	    }
		append table <tbody>
		append table </tbody>
	    append c [<h3> Query] \n
	    append c [<table> class dict $table] \n
	} r eo

	return [<div> id details $c]
    }

    # add a Vary field
    proc Vary {rsp args} {
	foreach field $args {
	    dict set rsp -vary $field 1
	}
	return $rsp
    }

    # add a Vary field
    proc UnVary {rsp args} {
	foreach field $args {
	    catch {dict unset rsp -vary $field}
	}
	return $rsp
    }

    # add a Refresh meta-data field
    proc Refresh {rsp time {url ""}} {
	catch {dict unset rsp cache-control}
	if {$url == ""} {
	    dict set rsp refresh $time
	} else {
	    dict set rsp refresh "${time};url=$url"
	}
	return $rsp
    }

    # nonRouting - predicate to determine if an IP address is routable
    proc nonRouting? {ip} {
	return [expr {$ip eq ""
		      || $ip eq "unknown"
		      || [catch {::ip::type $ip} type]
		      || $type ne "normal"
		  }]
    }

    # expunge - remove metadata from reply dict
    proc expunge {reply} {
	foreach n [dict keys $reply content-*] {
	    dict unset reply $n
	}

	# discard some fields
	return [dict ni $reply transfer-encoding -chunked -content]
    }

    # find etag in if-match field
    proc if-match {req etag} {
	if {![dict exists $req if-match]} {
	    return 1
	}
	set etag \"[string trim $etag \"]\"

	set im [split [dict get $req if-match] ","]
	set result [expr {$im eq "*" || $etag in $im}]
	Debug.cache {if-match: $result - $etag in $im}
	return $result
    }

    # find etag in if-range field
    proc if-range {req etag} {
	if {![dict exists $req if-range]} {
	    return 1
	}
	set etag \"[string trim $etag \"]\"
	set im [split [dict get $req if-range] ","]
	set result [expr {$im eq "*" || $etag in $im}]
	Debug.cache {if-match: $result - $etag in $im}
	return $result
    }

    proc if-none-match {req etag} {
	if {![dict exists $req if-none-match]} {
	    return 0
	}
	set etag \"[string trim $etag \"]\"
	set im [split [dict get $req if-none-match] ","]
	set result [expr {$etag ni $im}]
	Debug.cache {if-none-match: $result - $etag in $im}
	return $result
    }

    # find etag in if-none-match field
    proc any-match {req etag} {
	if {![dict exists $req if-none-match]} {
	    return 0
	}
	set etag \"[string trim $etag \"]\"
	set im [split [dict get $req if-none-match] ","]
	set result [expr {$etag in $im}]
	Debug.cache {any-match: $result - $etag in $im}
	return $result
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}
# vim: ts=8:sw=4:noet
