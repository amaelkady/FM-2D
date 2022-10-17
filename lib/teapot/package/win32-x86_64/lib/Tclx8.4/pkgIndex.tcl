
# @@ Meta Begin
# Package Tclx 8.4
# Meta activestatetags ActiveTcl Public
# Meta as::author      {Karl Lehenbauer} {Mark Diekhans} {Jeff Hobbs}
# Meta as::build::date 2015-03-10
# Meta as::origin      http://sourceforge.net/projects/tclx
# Meta category        
# Meta description     Extends Tcl by providing new operating system
# Meta description     interface commands, extended file control, scanning
# Meta description     and status commands and many others. Considered by
# Meta description     many to be a must-have for large Tcl apps.
# Meta license         BSD
# Meta platform        win32-x86_64
# Meta require         {Tcl 8.4}
# Meta subject         file scanning operating-system
# Meta summary         Extended Tcl
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.4]} return

package ifneeded Tclx 8.4 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.4

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            set ::env(TCLX_LIBRARY) {@}
            load [file join {@} tclx84.dll] Tclx

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide Tclx 8.4

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
