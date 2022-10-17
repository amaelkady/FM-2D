package provide nx::help 1.0
package require nx

namespace eval ::nx {
    
    proc help {args} {
	set l [llength $args]
	if {$l == 0} {
	    nsf::log info "Usage: help /nsf-tcl command/"
	    return
	}
	if {[nsf::is object [lindex $args 0]]} {
	    set obj [nsf::dispatch [lindex $args 0] eval self]
	    if {$l == 1} {
		nsf::log info "$obj /method/ ..."
		return
	    } 
	    set w [lrange $args 1 end]
	    set h [$obj ::nsf::methods::object::info::lookupmethod $w]
	    if {$h eq ""} {
		nsf::log warn "$obj has no method \"$w\""
		return
	    }
	    set origin [nsf::cmd::info origin $h]
	    if {$origin eq ""} {
		#
		# Since "info object ..." is not a true ensemble, we
		# have to use the definition handle.
		#
		set origin [nsf::cmd::info definitionhandle $h]
	    }
	    if {[nsf::is object $origin]} {
		nsf::log info "$obj $w [join [lsort [nsf::cmd::info submethods $origin]] |] ..."
	    } else {
		nsf::log info "$obj $w [nsf::cmd::info syntax -context $obj $h]"
	    }
	    return
	}
	#
	# catch-all
	#
	set cmd [namespace origin [lindex $args 0]]
	nsf::log info "[lindex $args 0] [nsf::cmd::info syntax $cmd]"
	return
    }
}

return

nx::help nx::Object
nx::help nx::Object configure
nx::help nx::Object create
nx::help nx::Object new
nx::help nx::Object newx
nx::help nx::Object info
nx::help nx::Object info precedence
nx::help nx::Object info vars
nx::help nx::Object info object
nx::help nx::Object info object mixin
nx::help nx::Object info object methods
nx::help nsf::cmd::info 
