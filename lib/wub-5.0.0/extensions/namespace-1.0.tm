package require extend

package provide namespace 1.0

# Extra useful namespace commands

extend namespace {
    # return a flattened namespace hierarchy containing all
    # descendents of the given namespace
    proc tree {namespace} {
	set result {}
	foreach ns [namespace children $namespace] {
	    lappend result $ns
	    lappend result {*}[tree $namespace]
	}
	return $result
    }

    proc vdump {namespace} {
	foreach v [info vars $namespace::*] {
	    if {[catch {set x $v}]} {
		puts 'array $v - [array get $v]'
	    } else {
		puts "$v - '$x'"
	    }
	}
    }
}
