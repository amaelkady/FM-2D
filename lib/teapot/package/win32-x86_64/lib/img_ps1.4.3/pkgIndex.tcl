
# @@ Meta Begin
# Package img::ps 1.4.3
# Meta activestatetags ActiveTcl Public Img
# Meta as::build::date 2015-03-10
# Meta as::origin      http://sourceforge.net/projects/tkimg
# Meta category        Tk Image Format
# Meta description     This is support for the ps & pdf image formats.
# Meta license         BSD
# Meta platform        win32-x86_64
# Meta require         {img::base 1.4-2}
# Meta require         {Tcl 8.4}
# Meta require         {Tk 8.4}
# Meta subject         ps pdf
# Meta summary         ps & pdf Image Support
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.4]} return

package ifneeded img::ps 1.4.3 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require img::base 1.4-2
        package require Tcl 8.4
        package require Tk 8.4

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            load [file join {@} tkimgps143.dll]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide img::ps 1.4.3

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
