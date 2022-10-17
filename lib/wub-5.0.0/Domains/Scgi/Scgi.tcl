# Scgi.tcl - SCGI client ... a domain which wraps a SCGI server ... bizarre

package require Http
package require OO

package require Debug
Debug define scgi 10

package provide Scgi 1.0

set ::API(Domains/Scgi) {
    {
	SCGI client domain ... a domain which wraps a SCGI server
    }
    grace {how long (in mS) to give the SCGI server to respond (default: 2 minutes)}
    host {what host is the SCGI server on? (default: localhost)}
    port {what port is the SCGI server on? (default: 8085)}
    run {what command script should be executed first? (default: none)}
}

class create ::Scgi {
    # response - collect and process response from SCGI client
    method response {r scgi {accum ""}} {
	set gone [catch {chan eof $scgi} eof]
	if {$gone || $eof} {
	    # the channel's gone - we presume it's completed the request
	    Httpd disassociate $scgi
	    catch {chan close $scgi}

	    # split input into headers and body
	    set delim [string first "\xd\xa\xd\xa" $accum]
	    set headers [split [string map {\xd\xa \xa} [string range $accum 0 $delim]] \n]
	    set body [string range $accum $delim+4 end]

	    set response {}
	    foreach header $headers {
		set val [join [lassign [split $header :] name] :]
		set name [string toupper $name]
		dict set response $name [string trim $val]
	    }
	    Debug.scgi {[self] got headers ($response) and body length [string length $body]}

	    # response status
	    if {[dict exists $response STATUS]} {
		set stguff [join [lassign [split [dict get $response STATUS]] status]]
		Debug.scgi {[self] status:$status guff: '$stguff'}
		dict set r -code $status
	    } else {
		Debug.scgi {[self] No status sent}
		dict set r -code 503
	    }

	    # entity (if any)
	    if {[string length $body]} {
		dict set r content-length [string length $body]
		dict set r -content $body
		dict set r content-type [dict get? $response CONTENT-TYPE]
	    } else {
		dict set r content-length 0
	    }

	    #set redirect [dict get? $response REDIRECT_STATUS] - for redirect?

	    Httpd Resume $r $cache	;# reply to client
	    
	} else {
	    # read some more response from scgi
	    append accum [read $scgi]
	    chan event $scgi readable [list [self] response $r $scgi $accum]
	}
    }

    method enc {name value} {
	return "$name\0$value\0"
    }

    # connected - connected to SCGI
    method connected {r scgi} {
	Debug.scgi {connected $scgi}
	chan event $scgi writable {}

	set gone [catch {chan eof $scgi} eof]
	if {$gone || $eof} {
	    # the channel's gone before we even connected - resume with error
	    Debug.error {[self] SCGI unavailable}
	    variable host; variable port
	    Httpd Resume [Http Unavailable $r "SCGI ${host}:$port unavailable"] 0
	}

	set rq ""
	# enc the content-length header first
	if {[dict exists $r content-length]} {
	    append rq [my enc CONTENT_LENGTH [dict get $r content-length]]
	} else {
	    append rq [my enc CONTENT_LENGTH 0]
	}
	if {[dict exists $r -entity]} {
	    append eq [my enc CONTENT_TYPE [dict get? $r content-type]]
	    # For queries which have attached information, such as HTTP POST and PUT,
	    # this is the content type of the data.
	}

	append rq [my enc SCGI 1]
	append rq [my enc SERVER_SOFTWARE [string map {" " /} $::Httpd::server_id]]
	append rq [my enc SERVER_NAME [dict get? $r -host]]

	variable extra
	foreach {n v} $extra {
	    append rq [my enc $n $v]
	}

	set protocol [string toupper [dict get? $r -scheme]]
	append protocol /[dict get? $r -version]
	append rq [my enc SERVER_PROTOCOL $protocol]
	# name and revision of the information protcol this request came in with.
	# Format: protocol/revision

	# calculate the suffix of the URL relative to $mount
	variable mount; lassign [Url urlsuffix $r $mount] result r suffix path

	append rq [my enc PATH_INFO /$suffix]
	append rq [my enc PATH_TRANSLATED /$suffix]

	set url [Url url $r]
	set url [Url parse $url]
	Debug.scgi {sending URL: ($url)}
	variable host; variable port; variable prefix
	dict set url -host $host
	dict set url -port $port
	dict set url -path $prefix/$suffix

	Debug.scgi {sending URL: ($url)}
	#append rq [my enc REQUEST_URI [Url url $url]]
	append rq [my enc REQUEST_METHOD [dict get? $r -method]]
	# method with which the request was made.
	# For HTTP, this is "GET", "HEAD", "POST", etc.

	if {[dict get? $url -query] ne ""} {
	    append rq [my enc QUERY_STRING [dict get? $url -query]]
	    # information which follows the ? in the URL which referenced this script.
	    # This is the query information. It should not be decoded in any fashion.
	    # This variable should always be set when there is query information,
	    # regardless of command line decoding.
	}

	append rq [my enc REMOTE_ADDR [dict get? $r -ipaddr]]
	# IP address of the remote host making the request.

	# Header lines received from the client, if any, are placed
	# into the environment with the prefix HTTP_ followed by the header name.
	# If necessary, the server may choose to exclude any or all of these headers
	# if including them would exceed any system environment limits.
	foreach field [dict get $r -clientheaders] {
	    if {[dict exists $r $field]} {
		append rq [my enc HTTP_[string map {- _} [string toupper $field]] [dict get $r $field]]
	    }
	}

	Debug.scgi {[self] sending request ([string length $rq]:$rq)}
	chan configure $scgi -blocking 0 -translation {binary binary} -buffering none
	puts $scgi "[string length $rq]:$rq,"	;# send the header
	puts $scgi [dict get? $r -entity]	;# send the entity

	# collect all input until the chan closes
	chan event $scgi readable [list [self] response $r $scgi]
    }

    method do {r} {
	Debug.scgi {do: [dict get $r -uri]}

	# open a connection to the appropriate port, let it all happen from there.
	variable port
	variable host
	set scgi [socket -async $host $port]
	Debug.scgi {do: socket: $scgi}
	#chan event $scgi readable [list [self] connected $r $scgi]
	chan event $scgi writable [list [self] connected $r $scgi]
	dict set r -scgi $scgi

	Httpd associate $scgi	;# set connection's file information to reflect the scgi socket

	variable grace
	Debug.scgi {do: suspending $grace}
	return [Httpd Suspend $r $grace]	;# wait for something to happen
    }

    variable cache
    constructor {args} {
	Debug.scgi {construct: $args}
	set cache 0
	variable grace [expr {2 * 60 * 60 * 1000}]	;# 2 minutes grace to respond
	variable host localhost	;# what host is the SCGI server on?
	variable port 8085	;# what port does the SCGI server run on?
	variable prefix ""
	variable extra {}	;# extra request fields
	variable run {}		;# what command do you want us to run?
	variable {*}$args

	if {[llength $run]} {
	    exec {*}$run	;# run the server process ... hmmm
	}

	next? {*}$args
    }
}

# vim: ts=8:sw=4:noet
