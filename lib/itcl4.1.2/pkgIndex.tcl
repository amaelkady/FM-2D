if {[package vsatisfies 8.0 [package provide Tcl]]} { 
    set add 80
} else {
    set add [expr { [info exists ::tcl_platform(threaded)] ? {t} : {} }]
}
if {[info exists ::tcl_platform(debug)] && $::tcl_platform(debug) && \
        [file exists [file join $dir itcl412${add}g.dll]]} {
    package ifneeded Itcl 4.1.2 [list load [file join $dir itcl412${add}g.dll] Itcl]
    package ifneeded itcl 4.1.2 [list load [file join $dir itcl412${add}g.dll] Itcl]
} else {
    package ifneeded Itcl 4.1.2 [list load [file join $dir itcl412${add}.dll] Itcl]
    package ifneeded itcl 4.1.2 [list load [file join $dir itcl412${add}.dll] Itcl]
}
unset add
