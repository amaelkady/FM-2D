package require Tcl 8.5

package provide extend 1.0

# extend a command with a new subcommand
proc extend {cmd body} {
    if {![namespace exists ${cmd}]} {
	set wrapper [string map [list %C $cmd %B $body] {
	    namespace eval %C {}
	    rename %C %C::%C
	    namespace eval %C {
		proc _unknown {junk subc args} {
		    return [list %C::%C $subc]
		}
		namespace ensemble create -unknown %C::_unknown -prefixes 0
	    }
	}]
    }

    append wrapper [string map [list %C $cmd %B $body] {
	namespace eval %C {
	    %B
	    namespace export -clear *
	}
    }]
    uplevel 1 $wrapper
}
