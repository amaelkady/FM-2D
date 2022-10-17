if {[info exists ::tcl_platform(debug)]} {
    package ifneeded tdom 0.8.3 "[list load [file join $dir tdom083g.dll] tdom]; [list source [file join $dir tdom.tcl]]"
} else {
    package ifneeded tdom 0.8.3 "[list load [file join $dir tdom083.dll] tdom]; [list source [file join $dir tdom.tcl]]"
}
