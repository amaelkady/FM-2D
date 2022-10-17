if {![package vsatisfies [package provide Tcl] 8.3]} {return}
package ifneeded tls 1.7.16 "source \[file join [list $dir] tls.tcl\] ; tls::initlib [list $dir] tls1716t.dll"
