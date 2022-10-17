# OO.tcl - helpers for tclOO
package require TclOO
namespace import oo::*

package provide OO 1.0

set ::API(Utilities/OO) {
    {
	Helpers for TclOO - adds some nice to have functionality
    }
}

proc ::oo::Helpers::classvar {name args} {
    set ns [info object namespace [uplevel 1 {self class}]]
    foreach v [list $name {*}$args] {
	uplevel 1 [list namespace upvar $ns $v $v]
    }
}

proc ::oo::Helpers::next? {args} {
    if {[llength [uplevel self next]]} {
	uplevel 1 [list next {*}$args]
    }
}

proc ::oo::define::classmethod {name {args {}} {body {}}} {
    set class [lindex [info level -1] 1]
    set classmy [info object namespace $class]::my
    if {[llength [info level 0]] == 4} {
        uplevel 1 [list self method $name $args $body]
    }
    uplevel 1 [list forward $name $classmy $name]
}

proc oo::define::Variable args {
    set currentclass [lindex [info level 1] 1]
    set existing [uplevel 1 [list info class variables $currentclass]]
    switch [lindex $args 0] {
        -append {
            set vars $existing
            lappend vars {*}[lrange $args 1 end]
        }
        -prepend {
            set vars [lrange $args 1 end]
            lappend vars {*}$existing
        }
        -remove {
            set vars $existing
            foreach var [lrange $args 1 end] {
                set idx [lsearch -exact $vars $var]
                if {$idx >= 0} {
                    set vars [lreplace $vars $idx $idx]
                }
            }
        }
        -set - default {
            set vars [lrange $args 1 end]
        }
    }
    uplevel 1 [list variables {*}$vars]
    return
}

# lets you do this:
# oo::class create foo {
#     Variable x y
#     Variable -append p d q
#     method bar args {
#         lassign $args x y p d q
#     }
#     method boo {} {
#         return $x,$y|$p,$d,$q
#     }
# }

proc oo::define::Var {args} {
    uplevel 1 [list Variable -append {*}[dict keys $args]]
    # now have to arrange to have these values assigned at constructor time.
}
