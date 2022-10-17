# WebSocketD - implement the web socket protocol
#

package require Debug
Debug define websockets 10
package require md5

package provide WebSockets 1.0

oo::class create WebSockets {
    # Each frame of data starts with a 0x00 byte and ends with a 0xFF byte,
    # with the UTF-8 text in between.

    method send {args} {
	corovars socket
	variable closing
	if {$closing} {
	    error "Closing"
	}
	puts -nonewline $socket "\0[join $args]\ff"
    }

    method read {} {
	corovars socket

	variable inbuf
	variable framing
	variable callback

	while {![catch {chan eof $socket} eof] && !$eof} {
	    set byte [chan read $socket 1]
	    if {![string length $byte]} break	;# no data to read

	    if {$framing} {
		# we're in framing mode - only \0 will do
		if {$byte ne "\0"} {
		    my destroy
		} else {
		    set framing 0	;# got our opening \0 - get data
		}
	    } elseif {$byte eq "\xff"} {
		# finished frame - got data in inbuf
		set framing 1
		{*}$callback $inbuf
	    } else {
		# collecting data
		append inbuf $data
	    }
	}
    }

    method close {} {
	corovars socket
	variable closing 1
	puts -nonewline $socket "\xff\x00"
    }

    method chdecode {k} {
        # Sec-WebSocket-Key1: 18x 6]8vM;54 *(5:  {   U1]8  z [  8
        # Sec-WebSocket-Key2: 1_ tx7X d  <  nw  334J702) 7]o}` 0
	# take the digits from the value to obtain a number
	# (in this case 1868545188 and 1733470270 respectively),
	# then divide that number by the number of space characters in the value
	# (in this case 12 and 10)
	# to obtain a 32-bit number (155712099 and 173347027).
	set digits [string trimleft [join [regexp -inline -all {[0-9]} $k] ""] 0]
	set nrspaces [expr {[string length $k] - [string length [string map {" " ""} $k]]}]

	return [expr {$digits / $nrspaces}]
    }
    # chdecode "18x 6]8vM;54 *(5:  {   U1]8  z [  8" == 155712099
    # chdecode "1_ tx7X d  <  nw  334J702) 7]o}` 0" == 173347027

    # challenge - calculate response to challenge
    method challenge {k1 k2 k3} {
	set k1 [chdecode $k1]
	set k2 [chdecode $k2]
	set rsp [binary format I3 [list $k1 $k2]]
	append rsp $k3
	return [::md5::md5 $rsp]
    }

    method handshake {r} {
	corovars socket
	# set socket to receive key3
	chan configure $sock -blocking 1 -encoding binary -translation {binary binary}
	set key3 [read $socket 8]	;# read Key3

	# reset socket to header config, having read the entity
	chan configure $socket -blocking 0 -encoding binary -translation {crlf binary}

	# Expecting
	# Host: example.com
	# Connection: Upgrade
	# Sec-WebSocket-Key2: 12998 5 Y3 1  .P00
	# Sec-WebSocket-Protocol: sample
	# Upgrade: WebSocket
	# Sec-WebSocket-Key1: 4 @1  46546xW%0l 1 5
	# Origin: http://example.com

	Debug.websockets {handshake request: $r}

	# construct a handshake response
	dict set r upgrade WebSocket
	dict set r connection upgrade
	dict set r sec-websocket-origin [dict r.origin]
	dict set r sec-websocket-location ws://example.com/demo

	# select a protocol
	set protocols [split [r.sec-websocket-protocol]]
	if {[llength $protocols]} {
	    # pick a default sub-protocol
	    dict set r sec-websocket-protocol [lindex $protocols 0]
	    dict set r -protocols $protocols
	}

	# response may/should include cookies - leave that to the domain

	# calculate whacky response to challenge
	set response [my challenge [dict r.sec-websocket-key1] [dict r.sec-websocket-key2] $key3]
	dict set r -content $response
	dict set r -websocket [self]
	variable uniq; incr uniq
	dict set r -websocketid [::md5::md5 -hex $uniq[clock microseconds]]

	Debug.websockets {handshake processing: $r}

	# process the request as a standard HTTP request
	# users must detect -websocket and deal accordingly
	catch {
	    Httpd do REQUEST [Httpd pre $r]
	} rsp eo	;# process the request
	Httpd watchdog

	# handle response code from processing request
	if {[dict get $eo -code]} {
	    Debug.websockets {handshake error: $rsp ($eo)}
	    Httpd send [Http ServerError $r $rsp $eo]
	    catch {close $sock}
	    my destroy
	}

	# send the handshake response to client
	set r [Http Switching $rsp $response]
	Debug.websockets {handshake response: $r}
	Httpd send $r

	# at this point, we should have complete control of the socket
	# set it up to handle read/write events and deliver them
	variable callback [dict get $r -callback]
	
	chan configure $socket -blocking 0 -encoding utf-8 -translation {crlf crlf} -buffering none
	chan event $socket readable [self] read
    }

    destructor {
	corovars socket
	catch {chan close $socket}
	variable callback
	if {[info exists callback]} {
	    catch {{*}$callback CLOSE}
	}
    }

    constructor {args} {
	variable {*}$args
	variable closing 0	;# we're not yet closing
	variable framing 1	;# we will be reading frames
	variable uniq 0
    }
}
