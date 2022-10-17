package require Debug
Debug define simplicio 10

package require Url
package require Query
package require Http
package require Html
package require Color
package require fileutil
package require Image

package provide Simplicio 1.0
set ::API(Domains/Simplicio) {
    {experimental SVG iconset}
}

namespace eval ::Simplicio {
    variable xml {<?xml version="1.0" encoding="UTF-8" standalone="no"?>}
    variable svg {<svg xmlns="http://www.w3.org/2000/svg" width="64px" height="64px">}

    variable style "fill:#%color;fill-opacity:1;fill-rule:nonzero;stroke:none"
    variable icons [fileutil::cat [file join [file normalize [file dirname [info script]]] simplicio-icons.tcl]]

    proc rotate {color rot} {
	lassign [Color webToHsv $color] hue sat val
	set nhue [expr {($hue + $rot) % 360}]
	return [string trimleft [Color hsvToWeb $nhue $sat $val] #]
    }

    variable cache {}
    proc render {name args} {
	set width 64; set height 64
	set hue ""
	if {$args ne {}} {
	    dict with args {}
	}

	variable cache
	if {[dict exists $cache $name $hue $width,$height]} {
	    return [dict get $cache $name $hue $width,$height]
	}

	variable style
	variable icons
	variable ignore

	set content ""
	foreach {color path} [dict get $icons $name] {
	    if {$color ni $ignore && [info exists hue] && $hue>0} {
		set color [rotate $color $hue]
	    }
	    append content [<path> style [string map [list %color $color] $style] d $path {}] \n
	}

	set xscale [expr {$width/64.0}]
	set yscale [expr {$height/64.0}]
	lappend gargs transform "scale($xscale,$yscale)"

	set content [<g> {*}$gargs $content]
	set content [<svg> xmlns http://www.w3.org/2000/svg width ${width}px height ${height}px $content]
	Debug.simplicio {width:$width height:$height / $args / $content}

	dict set cache $name $hue $width,$height $content

	return $content
    }

    variable ignore {ec2024 f1b326 279f48 5ebb67 292f6d a7cae3 a7cae3 292f6d 000000}

    proc get {icon} {
	variable icons
	return [dict get $icons $icon]
    }

    proc all {r} {
	variable icons
	variable ignore
	set content {}
	
	foreach n [lsort -dictionary [dict keys $icons]] {
	    set line {}
	    lappend line $n
	    lappend line [<object> width 64px height 64px data $n ""]
	    for {set i 60} {$i < 360} {incr i 60} {
		lappend line [<object> width 64px height 64px data $n?hue=$i ""]
	    }
	    foreach {col svg} [dict get $icons $n] {
		if {$col in $ignore} {
		    lappend line *[lindex [Color webToHsv $col] 0]/$col
		    continue
		} else {
		    lappend line [lindex [Color webToHsv $col] 0]/$col
		}
	    }
	    lappend content [<td> [join $line </td><td>]]
	}

	append table [<caption> "Simplicio Icons: [dict size $icons]"] \n
	append table <tr>[join $content </tr>\n</tr>]</tr> \n

	return [Http Ok $r [<table> $table]]
    }

    proc do {r} {
	# calculate the suffix of the URL relative to $mount
	variable mount
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	# catalog
	if {$suffix eq "/"} {
	    return [all $r]
	}

	set suffix [file rootname $suffix]
	set ext [dict get $r -extension]
	set want [Mime MimeOf $ext]
	dict set r accept $want
	#puts stderr "WANT: $want from $ext"

	# check existence of icon
	variable icons
	set iname [file rootname [file tail $suffix]]
	
	if {![dict exists $icons $iname]} {
	    # path isn't inside our domain suffix - error
	    return [Http NotFound $r]
	}

	set query [Query parse $r]
	dict set r -Query $query
	Debug.simplicio {args: ([Query flatten $query]) '$query'}
	set icon [render $iname {*}[Query flatten $query]]

	variable expires
	set r [Http Cache $r $expires]
	return [Http Ok $r $icon image/svg+xml]
    }

    variable expires "next week"
    variable mount /simplicio/
    proc create {junk args} { return [new {*}$args] }
    proc new {args} {
	variable {*}[Site var? Simplicio]	;# allow .ini file to modify defaults
	variable {*}$args
	return ::Simplicio
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}
