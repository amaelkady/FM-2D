# Metakit --
#
# A Wub domain to return contents of a metakit.

package require TclOO
namespace import oo::*

package require Debug
Debug define metakit 10

package require csv
package require View

package require Html
package require Report

package provide Metakit 1.0

set ::API(Domains/Metakit) {
    {
	Domain to present metakit views

	== Note: the views themselves are not constructed by this domain ==
    }
}

class create ::Metakit {
    variable db views csv limit rparams limit

    method do {r} {
	# calculate the suffix of the URL relative to $mount
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	# use suffix to determine which view
	lassign [split $suffix .] view ext

	# ensure the view is permitted
	if {$view ni $views} {
	    return [NotFound $r]
	}

	# use query to determine fieldset
	set display {}
	set select {}
	set flags {}

	# get relevant field descriptors from the query
	set q [Query parse $r]
	foreach {n v m} [Query nvmlist $q] {
	    catch {unset meta}
	    array set meta $m
	    if {[info exists meta(unassigned)]} {
		if {[string match {-*} $n]} {
		    # set flag
		    dict set flags $n 1
		} else {
		    # just a display field
		    dict set display $meta(-count) $n
		}
	    } else {
		# select clause element
		dict set select $n $v
	    }
	}

	# get display fields in query order
	set d_fields {}
	foreach {n} [lsort -integer [dict keys display]] {
	    lappend d_fields [dict get $display $n]
	}

	# calculate the selector from select clause elements
	set selector {}
	dict for {n v} $select {
	    switch -glob -- $n {
		*% {
		    # keyword match
		    lappend selector -keyword [string trim $n %] $v
		}
		*[*] {
		    # glob match
		    lappend selector -globnc [string trim $n *] $v
		}
		default {
		    lappend selector $n $v
		}
	    }
	}
	
	$view select {*}$selector as sV
	set dict [$sV dict {*}$d_fields]

	switch -- [string tolower $ext] {
	    html {
		set result [Report html $dict {*}$rparams headers $d_fields]
		return [Http Ok $r $result text/x-html-fragment]
	    }

	    default {
		set result [::csv::join $d_fields]\n
		dict foreach {n v} $dict {
		    append result [::csv::join [dict values $v]] \n
		}
		return [Http Ok $r $result text/csv]
	    }
	}
    }

    constructor {args} {
	set db ""	;# Metakit db name
	set views {}	;# views which can be accessed by the domain
	set rparams {
	    sortable 1
	    evenodd 0
	    class table
	    tparam {title ""}
	    hclass header
	    hparam {title "click to sort"}
	    thparam {class thead}
	    fclass footer
	    tfparam {class tfoot}
	    rclass row
	    rparam {}
	    eclass el
	    eparam {}
	    footer {}
	}
	set limit 0
	variable {*}[Site var? Metakit]	;# allow .ini file to modify defaults

	foreach {n v} $args {
	    set [string trimleft $n -] $v
	}
    }
}
