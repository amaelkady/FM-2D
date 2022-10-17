# record - support for record-as-dict

package provide record 1.0

package require struct::set

namespace eval ::record {
    proc delta {from to} {
	lassign [::struct::set intersect3 \
		     [dict keys $from] \
		     [dict keys $to]] \
	    both del add

	set delta [dict create]

	foreach k $add {
	    dict set delta $k [dict get $to $k]
	}

	foreach k $both {
	    if {[dict get $from $k] ne [dict get $to $k]} {
		dict set delta $k [dict get $to $k]
	    }
	}

	#foreach k $del {
	#    dict set delta $k {}
	#}

	puts stderr "record delta: ($from) to ($to) -> $delta"

	return $delta
    }

    proc readonly {from to key} {
	if {[dict exists $from $key] 
	    &&
	    ([dict get $from $key] ne "")
	    &&
	    ([dict get $from $key] ne [dict get $to $key])} {
	    error "'$key' is a read-only field in $from."
	}
    }
}

namespace eval ::record {
    namespace export -clear *
    namespace ensemble create -subcommands {}
}
