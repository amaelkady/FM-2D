package require extend

package provide interp 1.0

# Extra useful dict commands
extend interp {

    # namespace tree for subinterp
    proc __nstree {interp {prefix ""}} {
	set result {}
	foreach ns [$interp eval namespace children $prefix] {
	    lappend result $ns
	    lappend result {*}[__nstree $interp $ns]
	}
	return $result
    }

    proc serialize {interp} {
	$interp eval {unset -nocomplain errorCode; unset -nocomplain errorInfo}
	set result {}
	foreach v [$interp eval info globals] {
	    if {[string match tcl* $v]} continue
	    if {[$interp eval array exists $v]} {
		lappend result "array set $v [list [$interp eval array get $v]]"
	    } else {
		lappend result "set $v [list [$interp eval set $v]]"
	    }
	}

	foreach ns [__nstree $interp] {
	    set subresult {}
	    foreach v [$interp eval info vars ${ns}::*] {
		if {[array exists $v]} {
		    lappend subresult "array set [namespace tail $v] [list [$interp eval array get $v]]"
		} else {
		    lappend subresult "set [namespace tail $v] [list [$interp eval set $v]]"
		}
	    }
	    lappend result [list namespace eval $ns [join $subresult {; }]]
	}
	return [join $result "; "]
    }
}
