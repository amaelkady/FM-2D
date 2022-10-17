# Asynchronous SMTP Client
#
# Colin McCormack, colin@chinix.com

if {[info exists argv0] && ([info script] eq $argv0)} {
    lappend ::auto_path [file dirname [file normalize [info script]]]
    lappend ::auto_path ../Wub/Utilities
}

package require Dict
package require Coroonet
package require mime

package require Debug
Debug define smtp 10

package provide SMTP 3.0

set ::API(Utilities/SMTP) {
    {
	SMTP client - for sending email
    }
}

set ::SMTP_status {
    211 {System status, or system help reply}
    214 {Help message}
    220 {Service ready}
    221 {Service closing transmission channel}
    250 {Requested mail action okay, completed}
    251 {User not local; will forward to <forward-path>}
    252 {Cannot VRFY user, but will accept message and attempt delivery}

    354 {Start mail input; end with <CRLF>.<CRLF>}

    421 {Service not available, closing transmission channel}
    450 {Requested mail action not taken: mailbox unavailable}
    451 {Requested action aborted: error in processing}
    452 {Requested action not taken: insufficient system storage}

    500 {Syntax error, command unrecognized}
    501 {Syntax error in parameters or arguments}
    502 {Command not implemented}
    503 {Bad sequence of commands}
    504 {Command parameter not implemented}
    
    550 {Requested action not taken: mailbox unavailable}
    551 {User not local; please try <forward-path>}
    552 {Requested mail action aborted: exceeded storage allocation}
    553 {Requested action not taken: mailbox name not allowed}
    554 {Transaction failed or no SMTP service here}
}

class create ::SMTP {
    method parseaddresses {header value {limit 0}} {
	if {[catch {::mime::parseaddress $value} x eo]} {
	    error "can't parse address '$value': '$x'"
	}
	if {$limit && [llength $x] > $limit} {
	    error "too many $header addresses (limit of $limit)"
	}
	
	set result {}
	foreach aprops $x {
	    if {[dict get? $aprops error] ne ""} {
		error "error in address $header: [dict get $aprops error]"
	    } else {
		lappend result [dict get $aprops proper]
	    }
	}
	return $result
    }

    # expect a response
    method response {socket} {
	set code ""; set response {}
	while {1} {
	    set line [my get $socket]
	    if {0 && [catch {my get $socket} line eo]} {
		# we have an error
		if {[dict exists $eo -timeout]} {
		    return [list TIMEOUT [dict get $eo -timeout]]
		} else {
		    return [list ERROR [list $line $eo]]
		}
	    }

	    Debug.smtp {S: $line} 20
	
	    if {[string length $line] < 3} {
		error "SMTP response too short: '$line'"
	    }
	
	    # decode the response code
	    if {[scan [string range $line 0 2] %d lcode] != 1} {
		error "SMTP unrecognizable code: '$line'"
	    } elseif {$code ne "" && $code ne $lcode} {
		error "SMTP code changed from $code to $lcode"
	    } else {
		set code $lcode
	    }

	    # accumulate response
	    lappend response [string trim [string range $line 4 end]]

	    # check for response continuation
	    if {[string index $line 3] ne "-"} break
	}

	Debug.smtp {RESPONSE: $code ([dict get? $::SMTP_status $code]) $response}

	# response complete - return response
	return [list $code [join $response]]
    }

    # send a command
    method send {socket timeout args} {
	my timer $timeout
	Debug.smtp {SEND: $args}
	puts $socket [join $args]
	set result [my response $socket]
	my cancel
	return $result
    }

    # send the email's body
    method senddata {socket timeout msg} {
	# replace all '.'s that start their own line with '..'s, and
	# then write the mime body out to the filehandle.
	# Do not forget to deal with bare LF's here too (SF bug #499242).
	
	# Detect and transform bare LF's into proper CR/LF
	# sequences.
	    
	Debug.smtp {Sending Data [string length $msg]}

	my timer $timeout
	set msg [string map {\n. \n..} $msg]
	puts $socket "${msg}\n."
	set result [my response $socket]
	my cancel

	return $result
    }

    method smtp_protocol {socket msg smtp} {
	dict set status success 0

	# get initial HELO
	lassign [my response $socket] code response
	dict set status connect [list $code $response]
	switch -glob -- $code {
	    2* {
		Debug.smtp {SMTP connected: $code $response}
	    }
	    4* -
	    55* {
		Debug.smtp {SMTP failed connection: $code $response}
		return $status
	    }
	    default {
		Debug.error {failed connection: $code $response}
		return $status
	    }
	}

	dict with smtp {
	    lassign [my send $socket 60000 EHLO $client] code response
	    dict set status EHLO [list $code $response]

	    switch -glob -- $code {
		2* {
		    # successful connection unpack the ehlo extended features into esmtp()
		    set offers [split [lassign [split $response] server]]
		    set offered {}
		    for {set i 0} {$i < [llength $offers]} {incr i} {
			set value 1
			set eopt [string toupper [lindex $offers $i]]
			if {$eopt in {SIZE}} {
			    set value [lindex $offers [incr i]]
			}
			dict set offered $eopt $value
		    }
		    Debug.smtp {OFFERED: $offered}

		    foreach {ext cmd} {multiple ONEX queue QUED} {
			if {[dict exists $offered $cmd]
			    && [dict get $smtp $ext]
			} {
			    my send $socket 300 $socket $cmd
			    dict set status $cmd [list $code $response]
			}
		    }
 
		    # TODO: TLS and AUTH here.
		
		    set fargs {}

		    # RFC 1870 -  SMTP Service Extension for Message Size Declaration
		    if {[llength [dict keys $offered SIZE*]]} {
			lappend fargs "SIZE=[string length $msg]"
		    }

		    foreach ext {xverp} {
			set EXT [string toupper $ext]
			if {[set $ext] && [dict exists $offered $EXT]} {
			    lappend fargs $EXT
			}
		    }
		    
		    Debug.smtp {extensions requested: $fargs}

		    set fs FROM:<$sender>
		    lassign [my send $socket 6000 $mode $fs {*}$fargs] code response
		    dict set status "$mode $sender [join $fargs]" [list $code $response]
		    
		    switch -glob -- $code {
			2* {}
			4* -
			55* {
			    Debug.smtp {SMTP failed $mode: $code $response}
			    return $status
			}
			default {
			    Debug.error {failed $mode: $code $response}
			    return $status
			}
		    }
		    
		    set bad {}; set good {}	;# accumulate success and failure
		    foreach recipient [dict get? $smtp recipients] {
			lassign [my send $socket 3600 RCPT "TO:<$recipient>"] code response
			dict set status RCPT $recipient [list $code $response]

			set ex [dict get? $::SMTP_status $code]
			switch -glob -- $code {
			    250 -
			    251 {
				lappend good $recipient [list $code $ex $response]
			    }
			    
			    4* -
			    55* {
				lappend bad $recipient [list $code $ex $response]
				Debug.smtp {failed RCPT $code $ex $response}
			    }
			    
			    default {
				lappend bad $recipient [list $code $ex $response]
				Debug.error {SMTP failed RCPT $code $ex $response}
			    }
			}
		    }
		    
		    if {![dict size $good] || ([dict size $bad] && !$atleastone)} {
			# no recipients - reset the connection
			lassign [my send $socket 300 RSET] code response
			dict set status RSET [list $code $response]
			return $status
		    }

		    # recipients were acceptable - send text
		    lassign [my send $socket 300 DATA] code response
		    dict set status DATA [list $code $response]
		    switch -glob -- $code {
			3* {
			    lassign [my senddata $socket 3000 $msg] code response
			    puts stderr "sent data: $code"
			    dict set status data [list $code $response]
			    
			    switch -glob -- $code {
				2* {
				    lassign [my send $socket 300 QUIT] code response
				    dict set status QUIT [list $code $response]
				    dict set status success 1
				    return $status	;# we're done
				}
				55* {
				    Debug.smtp {SMTP failed data $code $ex $response}
				    return $status
				}
				default {
				    Debug.error {SMTP failed data $code $response}
				    return $status
				}
			    }
			}
			
			4* -
			55* {
			    Debug.smtp {SMTP failed DATA $code $ex $response}
			    return $status
			}
			default {
			    Debug.error {SMTP failed DATA $code $ex $response}
			    return $status
			}
		    }
		}
		4* -
		55* {
		    Debug.smtp {failed EHLO: $code $response}
		    return $status	;# failed or deferred connection - next server
		}
		default {
		    Debug.error {SMTP failed EHLO: $code $response}
		    return $status	;# failed or deferred connection - next server
		}
	    }
	}
    }

    method smtp {msg smtp} {
	dict set smtp sender [::mime::getheader $msg sender]
	set message [mime::buildmessage $msg]

	Debug.smtp {servers: [dict get? $smtp servers]}
	set status {}
	foreach server [dict get? $smtp servers] {
	    set done 0
	    if {[catch {
		# try connecting to server
		set socket [socket -async {*}[lrange [list {*}$server 25] 0 1]]
		fconfigure $socket -buffering line -translation {auto crlf}

		set result [my smtp_protocol $socket $message $smtp]
		set done [dict get $result success]
		Debug.smtp {$server status: ($result)}

		dict set status [lindex $server 0] $result
	    } e eo]} {
		dict set status [lindex $server 0] error [list $e $eo]
		Debug.smtp {error: $e ($eo)}
	    }
	    catch {close $socket}

	    if {$done} break
	}

	# clean up and indicate completion
	dict with smtp {
	    if {$cleantoken} {
		mime::finalize $msg
	    }

	    # call the completion command
	    if {[info exists completion] && $completion ne ""} {
		Debug.smtp {complete command ($completion): $status}
		if {[catch {
		    {*}$completion $status
		} result eo]} {
		    Debug.error {SMTP completion error: $eo}
		}
	    }
	    
	    # touch the sync variable
	    if {[info exists syncvar] && $syncvar ne ""} {
		Debug.smtp {complete sync with $syncvar}
		set $syncvar $status
	    }
	}

	Debug.smtp {complete}
    }

    # send a message
    method sendmessage {args} {
	if {[llength $args]%2} {
	    set msg [lindex $args end]
	    set args [lrange $args 0 end-1]
	} else {
	    error {Usage: SMTP mime .. options .. $mime}
	}

	Debug.smtp {args: $args}

	# pack all mime headers into mime $msg, all protocol vars into $smtp
	set smtp {}
	foreach {n v} $args {
	    set n [string tolower $n]
	    switch -- $n {
		content-type - content-transfer-encoding -
		content-md5 - mime-version {
		    error "header $n cannot be user-specified."
		}

		sender -
		from {
		    set e [my parseaddresses $n $v 1]
		    Debug.smtp {parse '$n' $v -> $e}
		    ::mime::setheader $msg $n $e -mode append
		}

		reply-to -
		in-reply-to -
		subject -
		precedence -
		comments -
		keywords -
		message-id -
		date {
		    ::mime::setheader $msg $n $v -mode write	;# set the header
		}
	    
		to -
		cc -
		bcc {
		    foreach e [my parseaddresses $n $v] {
			Debug.smtp {parse '$n' $v -> $e}
			::mime::setheader $msg $n $e -mode append	;# append the header
		    }
		}

		mode {
		    if {$v ni {MAIL SEND SOML SAML}} {
			error "$n must be one of: MAIL SEND SOML SAML"
		    }
		    dict set smtp $n $v	;# this is a protocol element
		}

		default {
		    dict set smtp $n $v	;# this is a protocol element
		}
	    }
	}
	Debug.smtp {args: $smtp}
	set smtp [dict merge $defaults $smtp]	;# use default protocols
	if {[dict get? $smtp servers] eq ""} {
	    error "Must specify at least one server"
	}

	if {[dict get? $smtp sender] ne ""} {
	    ::mime::setheader $msg sender [dict get $smtp sender] -mode write
	}

	set c "[catch {::mime::getheader $msg sender}],[catch {::mime::getheader $msg from}]"
	Debug.smtp {sender,from: $c}
	switch -- $c {
	    1,1 {
		# no Sender or From - use username
		::mime::setheader $msg sender $::tcl_platform(user) -mode write
		::mime::setheader $msg from $::tcl_platform(user) -mode write
	    }
	    1,0 {
		::mime::setheader $msg sender [::mime::getheader $msg from] -mode write
	    }
	    0,1 {
		::mime::setheader $msg from [::mime::getheader $msg sender] -mode write
	    }
	}

	# gather all unique recipients
	set recipients {}
	foreach n [dict get? $smtp recipients] {
	    dict set recipients $n 1
	}
	foreach n {to cc bcc} {
	    if {![catch {::mime::getheader $msg $n} r]} {
		foreach v $r {
		    dict set recipients $v 1
		}
		if {$n eq "bcc"} {
		    ::mime::setheader $msg bcc {} -mode delete	;# delete the Bcc
		}
	    }
	}
	dict set smtp recipients [dict keys $recipients]

	# If there's no date header, get the date from the mime message.
	if {[catch {::mime::getheader $msg date}]} {
	    ::mime::setheader $msg date [::mime::parsedatetime -now proper] -mode write
	}
	
	# If there's no message-id header construct one
	if {[catch {::mime::getheader $msg message-id}]} {
	    ::mime::setheader $msg message-id [::mime::uniqueID] -mode write
	}

	# If there's no message-id header construct one
	if {[catch {::mime::getheader $msg content-type}]} {
	    ::mime::setheader $msg message-id text/plain -mode write
	}

	set tmp [::mime::getheader $msg]
	Debug.smtp {sendmessage headers:($tmp) smtp:($smtp)}

	# start smtp coroutine - use msg token as its name
	return [sender [incr id] $msg $smtp]
    }
    
    # send a mime-encoded message
    method mime {args} {
	return [my sendmessage atleastone 1 queue 1 {*}$args]
    }

    # send a plain-text email
    method simple {args} {
	if {[llength $args]%2} {
	    set msg [lindex $args end]
	    set args [lrange $args 0 end-1]
	} else {
	    error {Usage: SMTP simple .. options .. $msg}
	}

	set x $args	;# protect args - it's not strictly a dict
	set ctype [dict get? $x content-type]
	if {$ctype eq ""} {
	    set ctype text/plain
	}
	set token [mime::initialize -canonical $ctype -string $msg]
	lappend args cleantoken 1

	return [my sendmessage atleastone 1 queue 1 {*}$args $token]
    }

    destructor {
	my cancel
    }

    variable defaults id
    mixin Coroonet

    constructor {args} {
	dict set defaults client [info hostname] ;# our identity - announced in HELO
	dict set defaults syncvar ""	;# var upon which to sync, default: local
	dict set defaults completion ""	;# command to invoke upon completion
	dict set defaults servers ""		;# list of mail servers to process the request.
	dict set defaults multiple 0	;# Multiple messages will be sent using this token.
	dict set defaults cleantoken 0	;# finalise the mime token after sending?

	# A boolean specifying whether or not to send the
	# message at all if any of the recipients are 
	# invalid.  A value of false means that ALL recipients must be
	# valid in order to send the message.  A value of
	# true means that as long as at least one recipient
	# is valid, the message will be sent.
	dict set defaults atleastone 0
	
	# A boolean specifying whether or not the message
	# being sent should be queued for later delivery.
	dict set defaults queue 0
	
	# send mail using Postfix's XVERP
	# (http://www.postfix.org/VERP_README.html)
	dict set defaults xverp 0

	# request delivery status notification
	dict set defaults dsn 0
	
	# mail sending mode - one of MAIL SEND SOML SAML
	dict set defaults mode MAIL
	
	# Maximum number of seconds to allow the SMTP server
	# to accept the message. If not specified, the default
	# is 120 seconds.
	dict set defaults maxsecs 120
	
	# A boolean flag. If the server supports it and we
	# have the package, use TLS to secure the connection.
	dict set defaults usetls 0
    
	# A command to call if the TLS negotiation fails for
	# some reason. Return 'insecure' to continue with
	# normal SMTP or 'secure' to close the connection and
	# try another server.
	dict set defaults tlspolicy {}
	
	# needed if your SMTP server requires authentication
	dict set defaults username ""
	dict set defaults password ""

	set defaults [dict merge $defaults $args]
	proc sender {id msg smtp} {
	    dict set smtp id $id
	    dict with smtp {
		coroutine C$id my smtp $msg $smtp
	    }
	    return C$id
	}
    }
}

if {[info exists argv0] && ([info script] eq $argv0)} {
    set client [SMTP new]
    set status [$client simple {*}{
	servers {puretcl.com localhost}
	subject "This is the subject."
	from colin@chinix.com
	sender colin+sender@chinix.com
	to "colin@chinix.com, dobeewap@chinix.com"
	precedence bulk
	xverp 1
	dsn 1
	loglevel debug
	syncvar ::status
    } "This is the message."]

    set ::status {}
    vwait ::status
    puts stderr "RESULT: $::status"
    puts stderr "RESULT: [dict keys $::status]"
}
