
# @@ Meta Begin
# Package Itk 3.4
# Meta activestatetags ActiveTcl Public
# Meta as::author      {Michael McLennan}
# Meta as::build::date 2015-03-11
# Meta as::origin      http://sourceforge.net/projects/incrTcl
# Meta category        Megawidget infrastructure
# Meta description     {[incr Tk]} is a framework for building mega-widgets
# Meta description     using the {[incr Tcl]} object system. Mega-widgets
# Meta description     are high-level widgets like a file browser or a tab
# Meta description     notebook that act like ordinary Tk widgets but are
# Meta description     constructed using Tk widgets as component parts,
# Meta description     without having to write C code. In effect, a
# Meta description     mega-widget looks and acts exactly like a Tk widget,
# Meta description     but is considerably easier to implement.
# Meta license         BSD
# Meta platform        win32-x86_64
# Meta require         {Tcl 8.4}
# Meta require         {Tk 8.4}
# Meta require         {Itcl 3.4}
# Meta subject         Tk megawidget OO
# Meta summary         Megawidget framework based on {[incr Tcl]}
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.4]} return

package ifneeded Itk 3.4 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.4
        package require Tk 8.4
        package require Itcl 3.4

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            set ::env(ITK_LIBRARY) {@}
            load [file join {@} itk34.dll] Itk

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide Itk 3.4

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
