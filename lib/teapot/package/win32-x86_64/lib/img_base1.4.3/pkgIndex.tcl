
# @@ Meta Begin
# Package img::base 1.4.3
# Meta activestatetags ActiveTcl Public Img
# Meta as::author      {Jan Nijtmans}
# Meta as::build::date 2015-03-10
# Meta as::origin      http://sourceforge.net/projects/tkimg
# Meta category        Tk photo image
# Meta description     Base package containing common utilities used across
# Meta description     all Img format packages
# Meta license         BSD
# Meta platform        win32-x86_64
# Meta require         {Tcl 8.4}
# Meta require         {Tk 8.4}
# Meta subject         Tk Image support
# Meta summary         Img common utilities
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.4]} return

package ifneeded img::base 1.4.3 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.4
        package require Tk 8.4

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            load [file join {@} tkimg143.dll]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide img::base 1.4.3

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
