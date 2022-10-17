# spelunker.tcl - dive into namespaces accumulating the reachable string rep lengths
# of variables.
package provide Spelunker 1.0

namespace eval Spelunker {
    variable title Spelunker
    proc sum {{ns ""}} {
	set local 0

	# calculate local space
	foreach var [info vars ::${ns}::*] {
	    if {[catch {string length [set $var]} len]} {
		foreach {n v} [array get $var] {
		    incr local [string length $n]
		    incr local [string length $v]
		}
	    } else {
		incr local $len
	    }
	}

	set children {}
	set total $local
	foreach child [namespace children ::${ns}] {
	    set sumc [sum $child] 
	    lassign [lindex $sumc 0] c l childsum
	    incr total $childsum
	    lappend children [list $child $l $childsum]
	    lappend children {*}[lrange $sumc 1 end]
	}
	return [list [list $ns $local $total] {*}$children]
    }
    
    proc sumcsv {} {
	package require csv
	::csv::joinlist [sum]
    }
    
    namespace export -clear *
    namespace ensemble create -subcommands {}
}
# vim: ts=8:sw=4:noet
