
# @@ Meta Begin
# Package pngtcl 1.4.12
# Meta activestatetags ActiveTcl Public
# Meta as::author      {Jan Nijtmans}
# Meta as::build::date 2015-03-10
# Meta as::origin      http://sourceforge.net/projects/tkimg
# Meta description     A variant of the libpng system library made suitable
# Meta description     for direct loading as a Tcl package.
# Meta license         BSD
# Meta platform        win32-x86_64
# Meta require         {Tcl 8.4}
# Meta require         zlibtcl
# Meta summary         png Support
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.4]} return

package ifneeded pngtcl 1.4.12 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.4
        package require zlibtcl

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            load [file join {@} pngtcl1412.dll]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide pngtcl 1.4.12

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
