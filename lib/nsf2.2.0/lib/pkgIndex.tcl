package ifneeded nx::help 1.0 [list source [file join $dir nx-help.tcl]]
package ifneeded nx::pp 1.0 [list source [file join $dir nx-pp.tcl]]
package ifneeded nx::shell 1.1 [list source [file join $dir nx-shell.tcl]]
package ifneeded nx::test 1.0 [list source [file join $dir nx-test.tcl]]
package ifneeded nx::trait 0.4 [list source [file join $dir nx-traits.tcl]]
package ifneeded nx::trait::callback 1.0 [list source [file join $dir nx-callback.tcl]]
package ifneeded nx::volatile 1.0 [list source [file join $dir nx-volatile.tcl]]
package ifneeded nx::zip 1.1 [list source [file join $dir nx-zip.tcl]]
# -*- Tcl -*-
namespace eval ::nsf {
  set traitIndex(nx::trait::callback) {script {package require nx::trait::callback}}
} 

