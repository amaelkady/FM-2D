if {[package vsatisfies 8.5 8.5]} {
if {![package vsatisfies [package provide Tcl]  8.5]} {return}
} elseif {[package vcompare [package provide Tcl]  8.5]} {return}
package ifneeded trofs 0.4.6  [list load [file join $dir trofs046.dll]]\;[list source [file join $dir procs.tcl]]
