# timer - a timer object
package require TclOO
namespace import oo::*

package provide Timer 1.0

class create Timer {
    method dump {} {
	my variable timer
	return [list $timer]
    }

    method running? {} {
	my variable timer
	if {[catch {::after info $timer} info]} {
	    return 0
	} else {
	    return 1
	}
    }

    variable cmd
    variable at

    # cancel any timers
    method cancel {} {
	my variable timer
	if {$timer != ""} {
	    catch {::after cancel $timer}
	    set timer ""
	}
    }

    # start a new timer
    method after {when args} {
	my cancel
	my variable timer at cmd
	if {$timer ne ""} {
	    # still have a timer running - cancel it
	    my cancel
	}
	set at $when
	set cmd $args
	set timer [::after $when {*}$args]
    }

    constructor {{when ""} args} {
	my variable timer ""
	if {$when ne ""} {
	    self after $when {*}$args
	}
    }

    # restart timer
    method restart {} {
	my variable at cmd
	my after $at {*}$cmd
    }

}

if {[info exists argv0] && ($argv0 eq [info script])} {
    Timer create T
    T after 3000 {puts moop}
    T cancel
    T after 3000 {puts moop}
    puts [T dump]
    set forever 0
    vwait forever
}
