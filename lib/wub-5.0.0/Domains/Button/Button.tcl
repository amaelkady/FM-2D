# Button.tcl - generate a lovely custom aqua-style svg button
package require Debug
Debug define button 10
package require fileutil
package require Color

package provide Button 1.0

set ::API(Domains/Button) {
    {Pretty Buttons for Wub}
}

set ::Button_dir [file normalize [file dirname [info script]]]

oo::class create Button {
    method rehue {svn newhue} {
	# scan svn for colors
	set colors [lsort -nocase -unique [regexp -inline -all {(#[a-fA-F0-9]{6})} $svn]]
	set cnt 0; set sum 0
	set hueof {}
	foreach c $colors {
	    if {[string tolower $c] eq "#ffffff"} continue
	    set hsv [Color webToHsv $c]
	    lassign $hsv hue saturation
	    if {$saturation > 4} {
		dict set hueof $c $hue
		incr sum $hue
		incr cnt
	    }
	}
	set newhue [expr {$newhue - $sum/$cnt}]	;# calculate color shift

	set map {}
	foreach c [dict keys $hueof] {
	    dict set map $c [Color rehueweb $c $newhue]
	}
	Debug.button {rehue: $newhue - hues: $map}
	return [string map $map $svn]	;# substitute colours
    }

    method getFile {name} {
	variable files
	if {![info exists files($name)]} {
	    set files($name) [::fileutil::cat -- $name]
	}
	return $files($name)
    }

    method / {r args} {
	Debug.button {[dict get $r -extra] - $args}
	set opts {}
	foreach n {width height} {
	    set v [dict args.$n?]
	    if {$v ne ""} {
		lappend opts $n ${v}px
	    }
	}
	set fn [file join $::Button_dir [string map [list [file separator] /] [dict get $r -extra]]]
	set hue [dict args.hue?]
	if {$hue eq ""} {
	    variable expires
	    set r [Http Cache $r $expires]
	    return [Http CacheableFile $r $fn image/svg+xml]
	}

	set svn [my getFile $fn]
	if {[string is integer -strict $hue]
	    || [string is xdigit -strict $hue]
	} {
	    if {[string length $hue] > 3} {
		lassign [Color webToHsv $hue] hue
	    }
	} else {
	    lassign [Color webToHsv [Color nameToWeb $hue]] hue
	}
	set svn [my rehue $svn $hue]

	variable expires
	set r [Http Cache $r $expires]
	return [Http Ok $r $svn image/svg+xml]
    }

    superclass Direct
    constructor {args} {
	variable expires "next week"
	variable {*}[Site var? Button]	;# allow .ini file to modify defaults
	variable {*}$args
	next? {*}$args
    }
}
