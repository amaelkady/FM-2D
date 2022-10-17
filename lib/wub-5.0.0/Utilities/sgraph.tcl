# sgraph
# simple graph code, sufficient to give minimal acyclic paths between nodes
# Thanks Richard Suchenwi for:
#	http://wiki.tcl.tk/2473 and http://wiki.tcl.tk/2603

package provide sgraph 1.0

namespace eval ::sgraph {
    proc lpop _L {
	upvar 1 $_L L
	set L [lassign $L res]
	set res
    }

    proc neighbors {g node} {
	if {[dict exists $g $node]} {
	    return [dict get $g $node]
	} else {
	    return {}
	}
    }

    proc path {g from to} {
	if {$from eq $to} {
	    return {}
	} elseif {[string match $to $from]} {
	    return {}
	}

	set length 999999	;# simulated infinity
	set todo $from		;# list of things to try
	while {[llength $todo]} {
	    set try [lpop todo]	;# first thing to do
	    set last [lindex $try end]
	    #puts stderr "sgraph path: ($try) ($last)"
	    foreach node [neighbors $g $last] {
		if {($node eq $to)
		    || [string match $to $node]
		} {
		    if {[llength $try] < $length} {
			set length [llength $try]
		    }
		    lappend try $node
		    return $try    ;# found a path
		} elseif {[lsearch $try $node] >= 0} {
		    continue ;# detected a cycle
		} elseif {[llength $try] < $length} {
		    lappend todo [concat $try [list $node]]
		} else {
		} ;# lappend and lpop make a FIFO queue
	    }
	}

	return {}
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}
