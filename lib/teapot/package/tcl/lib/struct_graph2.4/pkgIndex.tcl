
# @@ Meta Begin
# Package struct::graph 2.4
# Meta activestatetags ActiveTcl Public Tcllib
# Meta as::build::date 2015-03-09
# Meta as::origin      http://sourceforge.net/projects/tcllib
# Meta category        Tcl Data Structures Tcl Data Structures
# Meta description     Create and manipulate directed graph objects Create
# Meta description     and manipulate directed graph objects
# Meta license         BSD
# Meta platform        tcl
# Meta recommend       tcllibc
# Meta require         {Tcl 8.4}
# Meta require         struct::list
# Meta require         struct::set
# Meta subject         graph loop subgraph edge arc node serialization
# Meta subject         vertex adjacent neighbour degree cgraph cgraph graph
# Meta summary         struct::graph struct::graph_v1
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.4]} return

package ifneeded struct::graph 2.4 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.4
        package require struct::list
        package require struct::set

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            source [file join {@} graph.tcl]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide struct::graph 2.4

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
