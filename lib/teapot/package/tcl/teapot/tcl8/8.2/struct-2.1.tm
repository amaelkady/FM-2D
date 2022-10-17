# ACTIVESTATE TEAPOT-PKG BEGIN TM -*- tcl -*-
# -- Tcl Module

# @@ Meta Begin
# Package struct 2.1
# Meta activestatetags ActiveTcl Public Tcllib
# Meta as::build::date 2015-03-09
# Meta as::origin      http://sourceforge.net/projects/tcllib
# Meta license         BSD
# Meta platform        tcl
# Meta require         {Tcl 8.2}
# Meta require         {struct::graph 2.0}
# Meta require         {struct::list 1.4}
# Meta require         {struct::matrix 2.0}
# Meta require         {struct::pool 1.2.1}
# Meta require         {struct::prioqueue 1.3}
# Meta require         {struct::queue 1.2.1}
# Meta require         {struct::record 1.2.1}
# Meta require         {struct::set 2.1}
# Meta require         {struct::skiplist 1.3}
# Meta require         {struct::stack 1.2.1}
# Meta require         {struct::tree 2.0}
# @@ Meta End


# ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

package require Tcl 8.2
package require struct::graph 2.0
package require struct::list 1.4
package require struct::matrix 2.0
package require struct::pool 1.2.1
package require struct::prioqueue 1.3
package require struct::queue 1.2.1
package require struct::record 1.2.1
package require struct::set 2.1
package require struct::skiplist 1.3
package require struct::stack 1.2.1
package require struct::tree 2.0

# ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

# ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

package provide struct 2.1

# ACTIVESTATE TEAPOT-PKG END DECLARE
# ACTIVESTATE TEAPOT-PKG END TM
package require Tcl 8.2
package require struct::graph     2.0
package require struct::queue     1.2.1
package require struct::stack     1.2.1
package require struct::tree      2.0
package require struct::matrix    2.0
package require struct::pool      1.2.1
package require struct::record    1.2.1
package require struct::list      1.4
package require struct::set       2.1
package require struct::prioqueue 1.3
package require struct::skiplist  1.3

namespace eval ::struct {
    namespace export *
}

package provide struct 2.1
