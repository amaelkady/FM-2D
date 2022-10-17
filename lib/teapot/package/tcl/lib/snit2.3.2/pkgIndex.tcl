
# @@ Meta Begin
# Package snit 2.3.2
# Meta activestatetags ActiveTcl Public Tcllib
# Meta as::build::date 2015-03-09
# Meta as::origin      http://sourceforge.net/projects/tcllib
# Meta category        Snit's Not Incr Tcl, OO system
# Meta description     Snit's Not Incr Tcl
# Meta license         BSD
# Meta platform        tcl
# Meta recommend       Tk
# Meta require         {Tcl 8.5}
# Meta subject         C++ {object oriented} type {widget adaptors} widget
# Meta subject         BWidget {Incr Tcl} object adaptors class {mega widget}
# Meta subject         Snit
# Meta summary         snit
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.5]} return

package ifneeded snit 2.3.2 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.5

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            source [file join {@} snit2.tcl]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide snit 2.3.2

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
