# mjanssen

namespace eval ::trace {
    
    namespace export breakpoint

    proc breakpoint {args} { puts "bp"}

    proc _trigger {command op} {
	puts "breakpoint: [lindex $command end]"
	set clevel [uplevel 1 {info level}]
	set proc [lindex [uplevel 1 "info level 0"] 0]
	while 1 {
	    puts -nonewline "(level #${clevel}) > "
	    flush stdout
	    gets stdin cmd
	    if {$cmd ne "c"} {
		catch {puts [uplevel 1 $cmd]} err
		if {$err ne "" } {
		    puts $err
		}
		
	    } else {
		break
	    }
	}
    }

    proc on {} {
	trace add execution breakpoint enter ::trace::_trigger
    }

    proc off {} {
	trace remove execution breakpoint enter ::trace::_trigger
    }
}

package provide trace 0.1

#Test

if {[info exists argv0] && ([info script] eq $argv0)} {
    package require trace

    proc test {a} {
	::trace::breakpoint $a
	puts $a
    }

    ::trace::on
    test 5
    ::trace::off
    test 6
}
