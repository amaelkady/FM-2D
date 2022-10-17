
# @@ Meta Begin
# Package struct::stack 1.5.3
# Meta activestatetags ActiveTcl Public Tcllib
# Meta as::build::date 2015-03-09
# Meta as::origin      http://sourceforge.net/projects/tcllib
# Meta category        Tcl Data Structures
# Meta description     Create and manipulate stack objects
# Meta license         BSD
# Meta platform        tcl
# Meta recommend       {TclOO 0.6.1 0.6.1-}
# Meta recommend       tcllibc
# Meta require         {Tcl 8.2}
# Meta subject         tree queue matrix graph
# Meta summary         struct::stack
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.2]} return

package ifneeded struct::stack 1.5.3 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.2

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            source [file join {@} stack.tcl]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide struct::stack 1.5.3

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
