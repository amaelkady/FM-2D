# Tcl package index file, version 1.0

if {![package vsatisfies [package provide Tcl] 8.6]} return
if {[string length [package provide Itcl]] && ![package vsatisfies [package provide Itcl] 4.1]} return
package ifneeded itk 4.1.0 [list load [file join $dir "itk410.dll"] Itk]
package ifneeded Itk 4.1.0 [list load [file join $dir "itk410.dll"] Itk]
