# Chan - reflected channels in TclOO
package require OO

package require Debug
Debug define chan 10
Debug define connections 10

package provide Chan 1.0

# Chan.tcl - reflected channels
class create ::IChan {
    # Event management.
    method blocking {mychan mode} {
	if {[catch {
	    ::chan configure $chan -blocking $mode
	} r eo]} {
	    Debug.chan {$mychan blocking $chan $mode -> error $r ($eo)}
	} else {
	    Debug.chan {$mychan blocking $chan $mode -> $r}
	    return $r
	}
    }

    method watch {mychan eventspec} {
	Debug.chan {$mychan watch $chan $eventspec}
	if {"read" in $eventspec} {
	    ::chan event $chan readable [list [self] readable $mychan]
	} else {
	    ::chan event $chan readable ""
	}

	if {"write" in $eventspec} {
	    ::chan event $chan writable [list [self] writable $mychan]
	} else {
	    ::chan event $chan writable ""
	}
    }

    # Internals. Methods. Event generation.
    method readable {mychan} {
	Debug.chan {$mychan readable $chan - [chan pending input $chan]}
	::chan postevent $mychan read
	return
    }

    method writable {mychan} {
	Debug.chan {$mychan writable $chan - [chan pending output $chan]}
	::chan postevent $mychan write
	return
    }

    # Basic I/O
    method read {mychan n} {
	Debug.chan {$mychan read $chan begin eof: [chan eof $chan], blocked: [chan blocked $chan]}
	set used [clock milliseconds]
	if {[catch {::chan read $chan $n} result eo]} {
	    Debug.error {$mychan read $chan $n -> error $result ($eo)}
	} else {
	    Debug.chan {$mychan read $chan $n -> [string length $result] bytes: [string map {\n \\n} "[string length $result] bytes '[string range $result 0 20]...[string range $result end-20 end]"]'}
	    Debug.chan {$mychan read $chan eof     = [chan eof     $chan]}
	    Debug.chan {$mychan read $chan blocked = [chan blocked $chan]}
	    Debug.chan {$chan configured: ([chan configure $chan])}

	    # ![chan configure $chan -blocking] - optimization -> save the
	    # -blocking information in a flag, as it passes through method
	    # 'blocking'.
	    set gone [catch {chan eof $chan} eof]
	    if {![string length $result] &&
		!$gone && !$eof &&
		![chan configure $chan -blocking]
	    } {
		Debug.error {$mychan EAGAIN}
		return -code error EAGAIN
	    }
	}
	Debug.chan {$mychan read $chan result: [string length $result] bytes}
	return $result
    }

    method write {mychan data} {
	Debug.chan {$mychan write $chan [string length $data] / [chan pending output $chan] / [chan pending output $mychan]}
	set used [clock milliseconds]
	::chan puts -nonewline $chan $data
	return [string length $data]
    }

    # Setting up, shutting down.
    method initialize {mychan mode} {
	Debug.chan {$mychan initialize $chan $mode}
	Debug.chan {$chan configured: ([chan configure $chan])}
	return [list initialize finalize blocking watch read write cget cgetall configure]
    }

    method configure {mychan option value} {
	if {$option eq "-user"} {
	    set user $value
	} else {
	    chan configure $fd $option $value
	}
    }

    method finalize {mychan} {
	Debug.chan {$mychan finalize $chan}
	catch {next $mychan}
	catch {::chan close $chan}
	catch {my destroy}
    }

    method cget {mychan option} {
	switch -- $option {
	    -self {
		return [self]
	    }
	    -fd {
		return $chan
	    }
	    -used {
		return $used
	    }
	    -created {
		return $created
	    }
	    -user {
		return $user
	    }
	}
	if {[catch {next $mychan $option} result eo]} {
	    #puts stderr "cget: $result ($eo)"
	    return [::chan configure $chan $option]
	} else {
	    return $result
	}
    }

    method cgetall {mychan} {
	if {[catch {
	    next $mychan
	} result eo]} {
	    set result {}
	}

	lappend result -self [self] -fd $chan -used $used -created $created -user $user
	Debug.chan {[self] cgetall $mychan -> $result}
	return $result
    }

    variable chan used user created
    constructor {args} {
	# Initialize the buffer, current read location, and limit
	set chan ""

	# process object args
	set objargs [dict filter $args key {[a-zA-Z]*}]
	foreach {n v} $objargs {
	    if {$n in [info class variables [info object class [self]]]} {
		set $n $v
	    }
	}

	# set some configuration data
	set created [clock milliseconds]
	set used 0
	set user ""	;# user data - freeform

	catch {next {*}$args}

	if {![llength $objargs]} {
	    my destroy	;# this wasn't really a connected socket, just set classvars
	    return
	}

	# validate args
	if {$chan eq [self]} {
	    error "recursive chan!  No good."
	} elseif {$chan eq ""} {
	    error "Needs a chan argument"
	}
	#rename [self] [namespace qualifiers [self]]::$chan	;# rename the object to the $chan.
    }

    destructor {
	Debug.chan {[self] destroyed}
	if {[catch {::chan close $chan} e eo]} {
	    Debug.chan {failed to close $chan [self] because '$e' ($eo)}
	}
	next
    }
}

class create ::CaptureChan {
    variable capture file fd

    method read {mychan n} {
	set result [next $mychan $n]
	if {$capture && $fd ne ""} {
	    puts -nonewline $fd $result; flush $fd
	}
	return $result
    }

    method capture {{on 1}} {
	set capture $on
    }

    # set capture on/off
    constructor {args} {
	# process class parameters
	set fd ""
	set capture 0

	set classargs [dict filter $args key {-*}]
	foreach {n v} $classargs {
	    switch -- [string trim $n -] {
		capture {
		    set capture $v	;# set capture on/off
		}
		file {
		    # construct the capture file
		    set file $v
		    set fd [open $v a]
		    ::chan configure $fd -buffering none -translation binary
		}
	    }
	}
	next {*}$args
    }

    destructor {
	if {$fd ne ""} {
	    chan close $fd
	}
	next
    }
}

class create ::Socket {
    method socket {} {return $chan}
    method endpoints {} {return $endpoints}

    method configure {mychan option value} {
	set others {}
	switch -glob -- $option {
	    max* {
		set ip [dict get? $endpoints peer ip]
		classvar maxconnections
		dict set $maxconnections $ip $value
	    }
	    default {
		return [next $mychan $option $value]
	    }
	}
    }

    method cgetall {mychan} {
	set result {}
	foreach n {-connections -maxconnections} {
	    lappend result $n [my cget $mychan $n]
	}
	return $result
    }

    method cget {mychan option} {
	switch -- $option {
	    -maxconnections {
		classvar maxconnections
		set ip [dict get? $endpoints peer ip]
		if {[dict exists $maxconnections $ip]} {
		    return [dict get $maxconnections $ip]
		} else {
		    return [dict get $maxconnections ""]
		}
	    }

	    -connections {
		classvar connections
		set ip [dict get? $endpoints peer ip]
		return [dict values [dict get $connections $ip]]
	    }

	    default {
		error "No such option $option"
	    }
	}
    }

    method maxconnections {args} {
	classvar maxconnections
	lassign $args ip value
	if {$value eq "" && [string is integer -strict $value]} {
	    dict set maxconnections "" $value
	} else {
	    dict set maxconnections $ip $value
	}
    }

    #mixin CaptureChan IChan	;# run the capture refchan
    mixin IChan		;# mixin the identity channel
    variable chan endpoints

    constructor {args} {
	Debug.chan {Socket construction ($args)}
	classvar maxconnections connections

	# process class parameters
	set chan [dict get? $args chan]
	set peer [dict get? $args peer]
	set socket [dict get? $args socket]

	set classargs [dict filter $args key {-*}]
	foreach {n v} $classargs {
	    switch -glob -- [string trim $n -] {
		max* {
		    if {$chan ne ""} {
			dict set maxconnections $peer $v
		    } else {
			dict set maxconnections "" $v
		    }
		    dict unset args $n
		}
		default {
		    lappend cargs $n $v
		}
	    }
	}

	if {$chan eq ""} {
	    return
	}

	set errs 0; set tries 0; set errmsgs {}
	incr errs [catch {::chan configure $chan -blocking 0 -buffering none -encoding binary -eofchar {{} {}} -translation {binary binary}} e eo]
	lappend errmsgs $e

	# get the endpoints for this connected socket
	set epn {socket -sockname peer -peername}
	if {$peer ne ""} {
	    dict unset epn peer
	    dict set endpoints peer ip $peer
	}
	if {$socket ne ""} {
	    dict unset epn socket
	    dict set endpoints socket ip $peer
	}

	foreach {n cn} $epn {
	    incr tries
	    Debug.log {Socket configure $cn for $chan}
	    if {[catch {::chan configure $chan $cn} ep eo]} {
		incr errs
		lappend errmsgs $ep
	    } else {
		lassign [split $ep] ip name port
		foreach pn {ip name port} {
		    dict set endpoints $n $pn [set $pn]
		}
		set $n $ip
	    }
	}

	if {$errs} {
	    Debug.error {[self] $errs errors out of $tries tries - give up ($errmsgs).}
	    error $errmsgs
	    #[self] destroy
	}
	if {![dict exists $endpoints peer]} {
	    Debug.error {[self] don't have peer endpoint in $endpoints}
	    error "[self] don't have peer endpoint in $endpoints"
	    #[self] destroy
	}
	Debug.chan {Socket configured $chan to [::chan configure $chan]}

	# keep tally of connections from a given peer
	dict set connections $peer $port [self]
 
	# determine maxconnections for this ip
	if {![info exists maxconnections]} {
	    dict set maxconnections "" 20	;# an arbitrary maximum
	}
	if {[dict get? $maxconnections $peer] ne ""} {
	    set mc [dict get $maxconnections $peer]
	} else {
	    # default maxconnections
	    set mc [dict get $maxconnections ""]
	}

	# check overconnections
	set x [dict get $connections $peer]
	if {[dict size $x] > $mc} {
	    Debug.connections {$peer has connections [dict size $x] > $mc from ([dict get $x]) / [llength [chan names]] open fds}
	    #error "Too Many Connections from $name $peer"
	} else {
	    Debug.connections {$peer connected from port $port ([dict size $x] connections) / [llength [chan names]] open fds}
	}
	if {[llength [chan names]] > 400} {
	    Debug.error {Waaaay too many open fds:  [llength [chan names]]}
	}
    }

    method finalize {mychan} {
	catch {my destroy}
    }

    destructor {
	# remove connection record for connected ip
	if {![info exists endpoints]} return

	classvar connections
	if {![info exists connections]} return	;# huh?

	if {![catch {dict get $endpoints peer} ep]} {
	    dict with ep {
		if {[dict exists $connections $ip]} {
		    catch {dict unset connections $ip $port}
		    catch {set remain [dict get $connections $ip]}
		    Debug.connections {$ip port $port disconnected ([dict size $remain]) remaining}
		}
	    
		if {![dict size $remain]} {
		    dict unset connections $ip
		    Debug.connections {total: [dict size $connections]}
		}
	    }
	}
    }
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    set fd [open [info script] r]
    set fd0 [IChan new chan $fd]
    set fdr [::chan create {read write} $fd0]
    set lc 0
    while {[gets $fdr line] != -1 && ![eof $fdr]} {
	puts "[incr lc]: $line"
    }
}
