# Sscgi - Simple Common Gateway Interface Server
# Derived from http://wiki.tcl.tk/19670 by Mark Janssen (http://wiki.tcl.tk/14766)

if {[info exists argv0] && ($argv0 eq [info script])} {
    lappend auto_path [file dirname [info script]]
}

package provide Sscgi 1.0
package require Debug
package require Url

Debug define scgi 10

set ::API(Utilities/Scgi) {
    {
	Implements the SCGI interface.
    }
}


namespace eval ::Scgi {

    # listen - handle incoming connections
    proc listen {port} {
	socket -server [namespace code Connect] $port
    }

    # Connect - a client has connected
    proc Connect {sock ip port args} {
	Debug.scgi {Connect $sock $ip $port $args}
	fconfigure $sock -blocking 0 -translation {binary crlf}
	fileevent $sock readable [namespace code [list read_length $sock -sock $sock -ipaddr $ip -rport $port {*}$args]]
    }

    proc Disconnect {id error {eo ""}} {
    }

    proc read_length {sock args} {
	set length {}
	while {1} {
	    set c [read $sock 1]
	    if {[eof $sock]} {
		close $sock
		return
	    }
	    if {$c eq ":"} {
		fileevent $sock readable [namespace code [list read_headers $sock $length {} {*}$args]]
		return
	    }
	    append length $c
	}
    }

    proc read_headers {sock length read_data args} {
	append read_data [read $sock]
	
	if {[string length $read_data] < $length+1} {
	    # we don't have the complete headers yet, wait for more
	    fileevent $sock readable [namespace code [list read_headers $sock $length $read_data] {*}$args]
	    return
	} else {
	    set headers [string range $read_data 0 $length-1]
	    set headers [lrange [split $headers \0] 0 end-1]
	    set body [string range $read_data $length+1 end]
	    set content_length [dict get $headers CONTENT_LENGTH]
	    read_body $sock $headers $content_length $body {*}$args
	}
    }
    
    proc read_body {sock headers content_length body args} {
	append body [read $sock]
	if {[string length $body] < $content_length} {
	    # we don't have the complete body yet, wait for more
	    fileevent $sock readable [namespace code [list read_body $sock $headers $content_length $body {*}$args]]
	    return
	}
	Debug.scgi {SCGI $sock: $headers ($args)}

	if {[dict exists $args -dispatch]} {
	    # perform some translations of various fields
	    dict set args -entity $body
	    dict set args -socket $sock
	    dict set args -content_length $content_length
	    if {[catch {
		{*}[dict get $args -dispatch] [dict merge $args [translate $headers]]
	    } r eo]} {
		Debug.error {SCGI Error: $r ($eo)}
	    }
	} else {
	    handle_request $sock $headers $body
	}
    }

    variable trans	;# translation map

    lappend trans AUTH_TYPE -auth_type ;# If the server supports user authentication, and the script is protects, this is the protocol-specific authentication method used to validate the user.
    lappend trans CONTENT_LENGTH content-length ;# The length of the said content as given by the client.
    lappend trans CONTENT_TYPE content-type ;# For queries which have attached information, such as HTTP POST and PUT, this is the content type of the data.
    lappend trans DOCUMENT_ROOT -docroot ;# server's docroot
    lappend trans GATEWAY_INTERFACE -cgi	;# The revision of the CGI specification to which this server complies. Format: CGI/revision
    lappend trans PATH_INFO -pathinfo ;# The extra path information, as given by the client. In other words, scripts can be accessed by their virtual pathname, followed by extra information at the end of this path. The extra information is sent as PATH_INFO. This information should be decoded by the server if it comes from a URL before it is passed to the CGI script.
    lappend trans PATH_TRANSLATED -translated ;# The server provides a translated version of PATH_INFO, which takes the path and does any virtual-to-physical mapping to it.
    lappend trans QUERY_STRING -query ;# The information which follows the ? in the URL which referenced this script. This is the query information. It should not be decoded in any fashion. This variable should always be set when there is query information, regardless of command line decoding.
    lappend trans REDIRECT_STATUS -status
    lappend trans REMOTE_ADDR -ripaddr ;# The IP address of the remote host making the request.
    lappend trans REMOTE_HOST	-rhost ;# The hostname making the request. If the server does not have this information, it should set REMOTE_ADDR and leave this unset.
    lappend trans REMOTE_IDENT -ident ;# If the HTTP server supports RFC 931 identification, then this variable will be set to the remote user name retrieved from the server. Usage of this variable should be limited to logging only.
    lappend trans REMOTE_USER -user ;# If the server supports user authentication, and the script is protected, this is the username they have authenticated as.
    lappend trans REQUEST_METHOD -method ;# The method with which the request was made. For HTTP, this is "GET", "HEAD", "POST", etc.
    lappend trans SCRIPT_NAME	-path ;# A virtual path to the script being executed, used for self-referencing URLs.

    lappend trans SERVER_ADDR -addr	;# The address to which the request was sent.
    lappend trans SERVER_NAME -host ;# The server's hostname, DNS alias, or IP address as it would appear in self-referencing URLs.
    lappend trans SERVER_PORT -port	;# The port number to which the request was sent.
    lappend trans SERVER_PROTOCOL -protocol ;# The name and revision of the information protcol this request came in with. Format: protocol/revision
    lappend trans SERVER_SOFTWARE -server ;# The name and version of the information server software answering the request (and running the gateway). Format: name/version

    # translate - translate headers into Wub form
    proc translate {headers} {
	variable trans

	set result {}
	foreach {from to} $trans {
	    if {[dict exists $headers $from]} {
		lappend result $to [dict get $headers $from]
		dict unset headers $from
	    }
	}

	foreach {n v} $headers {
	    if {[string match HTTP_* $n]} {
		lappend result [string map {_ -} [string range $n 5 end]] $v
		dict unset headers $n
	    }
	}

	catch {dict unset result -chunked}	;# we don't do chunked

	lappend result -scgi [list $headers]
	lappend result -scheme http
	lappend result -url [Url url $result]
	return $result
    }

    # Send - send a reply down the wire
    proc Send {reply} {
	if {[catch {
	    set sock [dict get $reply -sock]

	    # wire-format the reply transaction
	    lassign [Http Send $reply -cache 0] reply header content empty cache
	    set header "Status: $header" ;# add the SCGI signifier

	    # send reply to actual server
	    puts $sock $header
	    puts $sock ""	;# terminate with an empty line
	    if {!$empty} {
		puts $sock $content
	    }
	    close $sock
	} r eo]} {
	    Debug.error {SCGI Sending Error: '$r' ($eo)}
	} else {
	    #Debug.log {Sent: ($header) ($content)}
	}
    }

    # handle_request - generate some test responses
    proc handle_request {sock headers body} {
	package require html
	array set Headers $headers
	
	#parray Headers
	puts $sock "Status: 200 OK"
	puts $sock "Content-Type: text/html"
	puts $sock ""
	puts $sock "<HTML>"
	puts $sock "<BODY>"
	puts $sock [::html::tableFromArray Headers]
	puts $sock "</BODY>"
	puts $sock "<H3>Body</H3>"
	puts $sock "<PRE>$body</PRE>"
	if {$Headers(REQUEST_METHOD) eq "GET"} {
	    puts $sock {<FORM METHOD="post" ACTION="/scgi">}
	    foreach pair [split $Headers(QUERY_STRING) &] {
		lassign [split $pair =] key val
		puts $sock "$key: [::html::textInput $key $val]<BR>"
	    }
	    puts $sock "<BR>"
	    puts $sock {<INPUT TYPE="submit" VALUE="Try POST">}
	} else {
	    puts $sock {<FORM METHOD="get" ACTION="/scgi">}
	    foreach pair [split $body &] {
		lassign [split $pair =] key val
		puts $sock "$key: [::html::textInput $key $val]<BR>"
	    }
	    puts $sock "<BR>"
	    puts $sock {<INPUT TYPE="submit" VALUE="Try GET">}
	}
	
	puts $sock "</FORM>"
	puts $sock "</HTML>"
	close $sock
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    ### Stand-alone configuration
    puts stderr "Listening"
    Scgi::listen 8088
    vwait forever
}

#### Wub Listener interface
# Listener listen -host $host -port $listener_port -httpd Scgi -dispatch {Backend Incoming}
# vim: ts=8:sw=4:noet
