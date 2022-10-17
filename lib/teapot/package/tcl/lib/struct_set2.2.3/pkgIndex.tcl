
# @@ Meta Begin
# Package struct::set 2.2.3
# Meta activestatetags ActiveTcl Public Tcllib
# Meta as::build::date 2015-03-09
# Meta as::origin      http://sourceforge.net/projects/tcllib
# Meta category        Tcl Data Structures
# Meta description     Procedures for manipulating sets
# Meta license         BSD
# Meta platform        tcl
# Meta recommend       tcllibc
# Meta require         {Tcl 8.0}
# Meta subject         {symmetric difference} set membership inclusion
# Meta subject         emptiness cardinality union exclusion intersection
# Meta subject         difference
# Meta summary         struct::set
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.0]} return

package ifneeded struct::set 2.2.3 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.0

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            source [file join {@} sets.tcl]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide struct::set 2.2.3

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
