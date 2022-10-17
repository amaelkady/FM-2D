# color manipulation, from http://wiki.tcl.tk/19711

package provide Color 1.0

set ::API(Utilities/Color) {
    {
	Color manipulation utility
    }
}

namespace eval ::Color {
    variable colors {
	indianred CD5C5C lightcoral F08080 salmon FA8072
	darksalmon E9967A lightsalmon FFA07A crimson DC143C
	red FF0000 firebrick B22222 darkred 8B0000
	pink FFC0CB lightpink FFB6C1 hotpink FF69B4 deeppink FF1493
	mediumvioletred C71585 palevioletred DB7093
	coral FF7F50 tomato FF6347 orangered FF4500
	darkorange FF8C00 orange FFA500
	gold FFD700 yellow FFFF00 lightyellow FFFFE0
	lemonchiffon FFFACD lightgoldenrodyellow FAFAD2 
	papayawhip FFEFD5 moccasin FFE4B5 peachpuff FFDAB9
	palegoldenrod EEE8AA
	khaki F0E68C darkkhaki BDB76B
	lavender E6E6FA thistle D8BFD8 plum DDA0DD
	violet EE82EE orchid DA70D6 fuchsia FF00FF
	magenta FF00FF mediumorchid BA55D3 mediumpurple 9370DB
	blueviolet 8A2BE2 darkviolet 9400D3 darkorchid 9932CC
	darkmagenta 8B008B purple 800080 indigo 4B0082
	slateblue 6A5ACD darkslateblue 483D8B mediumslateblue 7B68EE
	greenyellow ADFF2F chartreuse 7FFF00 lawngreen 7CFC00
	lime 00FF00 limegreen 32CD32 palegreen 98FB98
	lightgreen 90EE90 mediumspringgreen 00FA9A springgreen 00FF7F
	mediumseagreen 3CB371 seagreen 2E8B57 forestgreen 228B22
	green 008000 darkgreen 006400 yellowgreen 9ACD32
	olivedrab 6B8E23 olive 808000 darkolivegreen 556B2F
	mediumaquamarine 66CDAA darkseagreen 8FBC8F lightseagreen 20B2AA
	darkcyan 008B8B teal 008080 aqua 00FFFF
	cyan 00FFFF lightcyan E0FFFF paleturquoise AFEEEE
	aquamarine 7FFFD4 turquoise 40E0D0 mediumturquoise 48D1CC
	darkturquoise 00CED1 cadetblue 5F9EA0 steelblue 4682B4
	lightsteelblue B0C4DE purwablue 9BE1FF powderblue B0E0E6
	lightblue ADD8E6 skyblue 87CEEB lightskyblue 87CEFA
	deepskyblue 00BFFF dodgerblue 1E90FF cornflowerblue 6495ED
	royalblue 4169E1 blue 0000FF mediumblue 0000CD
	darkblue 00008B navy 000080 midnightblue 191970
	cornsilk FFF8DC blanchedalmond FFEBCD bisque FFE4C4
	navajowhite FFDEAD wheat F5DEB3 burlywood DEB887
	tan D2B48C rosybrown BC8F8F sandybrown F4A460
	goldenrod DAA520 darkgoldenrod B8860B peru CD853F
	chocolate D2691E saddlebrown 8B4513 sienna A0522D
	brown A52A2A maroon 800000 white FFFFFF
	snow FFFAFA honeydew F0FFF0 mintcream F5FFFA
	azure F0FFFF aliceblue F0F8FF ghostwhite F8F8FF
	whitesmoke F5F5F5 seashell FFF5EE beige F5F5DC
	oldlace FDF5E6 floralwhite FFFAF0 ivory FFFFF0
	antiquewhite FAEBD7 linen FAF0E6 lavenderblush FFF0F5
	mistyrose FFE4E1 gainsboro DCDCDC lightgrey D3D3D3
	silver C0C0C0 darkgray A9A9A9 gray 808080
	dimgray 696969 lightslategray 778899 slategray 708090
	darkslategray 2F4F4F black 000000
    }

    proc nameToWeb {x} {
	variable colors
	set x [string tolower $x]
	if {[dict exists $colors $x]} {
	    return #[dict get $colors $x]
	} else {
	    return $x
	}
    }

    proc rgbToWeb {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	lassign $args r g b
	return "\#[format %02x $r][format %02x $g][format %02x $b]"
    }

    proc hsvToWeb {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	lassign $args h s v
	return [rgbToWeb [hsvToRgb $h $s $v]]
    }

    proc webToRgb {x} {
	set x [nameToWeb $x]
	set x [string trim $x \#]
	while {[string length $x] < 6} {
	    set x 0$x
	}

	set r 0x[string range $x 0 1]
	set g 0x[string range $x 2 3]
	set b 0x[string range $x 4 5]

	set r [expr {$r}]
	set g [expr {$g}]
	set b [expr {$b}]

	return [list $r $g $b]
    }

    proc webToHsv {x} {
	return [rgbToHsv [webToRgb $x]]
    }

    proc rgbToHsv {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	lassign $args r g b

	set sorted [lsort -real [list $r $g $b]]
	set temp [lindex $sorted 0]
	set v [lindex $sorted 2]

	set value $v
	set bottom [expr {$v-$temp}]
	if {$bottom == 0} {
	    set hue 0
	    set saturation 0
	    set value $v
	} else {
	    if {$v == $r} {
		set top [expr {$g-$b}]
		if {$g >= $b} {
		    set angle 0
		} else {
		    set angle 360
		}
	    } elseif {$v == $g} {
		set top [expr {$b-$r}]
		set angle 120
	    } elseif {$v == $b} {
		set top [expr {$r-$g}]
		set angle 240
	    }
	    set hue [expr { round( 60 * ( double($top) / $bottom ) + $angle ) }]
	}

	if {$v == 0} {
	    set saturation 0
	} else {
	    set saturation [expr { round( 255 - 255 * ( double($temp) / $v ) ) }]
	}
	return [list $hue $saturation $value]
    }
    
    proc hsvToRgb {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	lassign $args h s v

	set Hi [expr { int( double($h) / 60 ) % 6 }]
	set f [expr { double($h) / 60 - $Hi }]
	set s [expr { double($s)/255 }]
	set v [expr { double($v)/255 }]
	set p [expr { double($v) * (1 - $s) }]
	set q [expr { double($v) * (1 - $f * $s) }]
	set t [expr { double($v) * (1 - (1 - $f) * $s) }]
	switch -- $Hi {
	    0 {
		set r $v
		set g $t
		set b $p
	    }
	    1 {
		set r $q
		set g $v
		set b $p
	    }
	    2 {
		set r $p
		set g $v
		set b $t
	    }
	    3 {
		set r $p
		set g $q
		set b $v
	    }
	    4 {
		set r $t
		set g $p
		set b $v
	    }
	    5 {
		set r $v
		set g $p
		set b $q
	    }
	    default {
		error "Wrong Hi value in hsvToRgb procedure! This should never happen!"
	    }
	}
	set r [expr {round($r*255)}]
	set g [expr {round($g*255)}]
	set b [expr {round($b*255)}]
	return [list $r $g $b]
    }

    proc hlsToRgb {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	lassign $args h l s

	# h, l and s are floats between 0.0 and 1.0, ditto for r, g and b
	# h = 0   => red
	# h = 1/3 => green
	# h = 2/3 => blue
    
	set h6 [expr {($h-floor($h))*6}]
	set r [expr {  $h6 <= 3 ? 2-$h6
		       : $h6-4}]
	set g [expr {  $h6 <= 2 ? $h6
		       : $h6 <= 5 ? 4-$h6
		       : $h6-6}]
	set b [expr {  $h6 <= 1 ? -$h6
		       : $h6 <= 4 ? $h6-2
		       : 6-$h6}]
	set r [expr {$r < 0.0 ? 0.0 : $r > 1.0 ? 1.0 : double($r)}]
	set g [expr {$g < 0.0 ? 0.0 : $g > 1.0 ? 1.0 : double($g)}]
	set b [expr {$b < 0.0 ? 0.0 : $b > 1.0 ? 1.0 : double($b)}]
	
	set r [expr {(($r-1)*$s+1)*$l}]
	set g [expr {(($g-1)*$s+1)*$l}]
	set b [expr {(($b-1)*$s+1)*$l}]
	return [list $r $g $b]
    }

    variable c2angle
    foreach c {red yellow green cyan blue magenta orange} {
	dict set c2angle $c [lindex [rgbToHsv [webToRgb $c]] 0]
    }

    variable angle
    foreach {n v} $c2angle {
	dict set angle $v $n
    }

    proc nearest {hue} {
	variable angle
	set delta 100000
	set close ""
	foreach {v n} $angle {
	    if {abs($hue - $v) <= $delta} {
		set close $n
		set delta [expr {abs($hue - $v)}]
	    }
	}
	return $close
    }

    proc rehueweb {c hue} {
	lassign [Color webToHsv $c] h s v
	set h [expr {($h + $hue)%360}]
	return [Color hsvToWeb $h $s $v]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

if {[info exists argv0] && ($argv0 eq [info script])} {

    set vcolors {
	%HIGHLIGHT_BG #F0F0F0
	%LIGHTER #F8F8F8
	%SUBHEAD #FDA05E
	%LEFT #FF9800
	%HR #999999
	
	%HEADER_LEFT #4088b8
	%HEADER_FG #003399
	%HEADER_BG #8CA8E6
	%H1 #999999

	%FOOTER_BG #6381DC

	%TOOLTIP #CCCCCC
	%VISITED #003399
	%LINK #0066CC

	%FADE #c8c8c8
	%BLUR #c8c8c8

	%TABLE_BG #CDCDCD
	%TABLE_HBG #E6EEEE
	%TABLE_BBG #3D3D3D
	%TABLE_ODD #F0F0F6
    }
    foreach {n v} $vcolors {
	set rgb [Color webToRgb $v]
	set hsv [Color rgbToHsv $rgb]
	if {$rgb ne [Color hsvToRgb $hsv]} {
	    #puts "$rgb ne [Color hsvToRgb $hsv]"
	}
	puts "<p style='background:$v'>$n $v ($hsv) [Color nearest [lindex $hsv 0]]</p>"
    }
}
