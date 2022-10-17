if {[catch {package require Tcl 8.5b1}]} return
package ifneeded TclOO 1.0.2  [list load [file join $dir TclOO102.dll] TclOO]
