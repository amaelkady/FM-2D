# WebSocket.tcl - a domain to apply a lambda to a websocket
package require Debug
Debug define websocket 10

package provide WebSocket 1.0

set ::API(Domains/WebSocket) {
    {WebSocket - a WebSocket Domain}
}

set ::WebSocket_dir [file normalize [file dirname [info script]]]

class create ::WebSocket {
    method gone {interp ws wsid args} {
	# interpreter has gone
	catch {{*}$ws destroy}
    }

    method wscoro {r lambda} {
    }

    method / {r} {
	Debug.websocket {/ $r}
	set ws [dict r.-websocket?]
	if {$ws ne ""} {
	    # we have a websocket handshake - construct a coro with it
	    variable lambda
	    set wsid [dict r.-websocketid]
	    set interp [interp create WSI_$wsid]
	    trace add command $interp delete [list [self] gone $interp [info coroutine] $ws $wsid]

	    $interp alias tx $ws send
	    $interp eval [list coroutine ::app apply [list {r lambda} {
		proc rx {} {
		    set args [lassign [::yieldm] cmd]
		    if {$cmd eq "close"} {
			catch {::close}	;# inform the app
			::exit
		    } else {
			return [join $args]
		    }
		}
		::apply [list r $lambda] $r
	    } [namespace current]] $r $lambda]

	    dict r.-callback [list $interp eval ::app]
	    return $r
	} else {
	    # we have a request to start up a generic websocket
	    variable mount

	    # collect up the JS for client event handling
	    set opts {}
	    foreach v {open close events} {
		variable $v
		if {[info exists $v] && [set $v] ne ""} {
		    lappend opts $v [set $v]
		}
	    }

	    variable var
	    variable js
	    set url [string map {http ws} [dict r.-url]]
	    set r [jQ websocket $r $var $url {*}$opts $js]

	    variable html
	    return [Http Ok $r $html x-text/html-fragment]
	}
    }

    superclass Direct
    constructor {args} {
	variable var ws
	variable open ""
	variable close ""
	variable events ""
	variable js ""
	variable lambda ""
	variable html ""
	variable {*}$args
	next {*}$args
    }
}
