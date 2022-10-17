
# @@ Meta Begin
# Package struct::tree 2.1.2
# Meta activestatetags ActiveTcl Public Tcllib
# Meta as::build::date 2015-03-09
# Meta as::origin      http://sourceforge.net/projects/tcllib
# Meta license         BSD
# Meta platform        tcl
# Meta recommend       tcllibc
# Meta require         {Tcl 8.2}
# Meta require         struct::list
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.2]} return

package ifneeded struct::tree 2.1.2 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.2
        package require struct::list

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            source [file join {@} tree.tcl]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide struct::tree 2.1.2

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
