# Image.tcl - image utilities
package require Debug
Debug define image 10

package require Url
package require Query
package require Http
package require Color
package require fileutil

package provide Image 1.0

set ::API(Utilities/Image) {
    {
	image utility - conversions etc
    }
}

namespace eval ::Image {
    # called for some of the suspended/offline conversions
    proc converting {fd r ct output args} {
	set result [read $fd]
	Debug.image {CONVERSION: '$result'}

	if {[chan eof $fd]} {
	    # the process has finished

	    if {[catch {chan close $fd} res eo]} {
		Debug.image {CONVERT ERROR: $res}
		set r [Http ServerError $r $res $eo]
	    } else {
		# grab the output
		set image [::fileutil::cat -translation binary -- $output]
		Debug.image {CONVERTED: $res [string length $image] bytes to $ct format}
		set r [Http Ok $r $image $ct]
	    }

	    # clean up the temp files
	    #file delete $output
	    foreach f $args {
		#file delete $f
	    }

	    Httpd Resume $r
	}
    }

    variable conversions 0

    variable convert ""
    if {![catch {exec /usr/bin/which convert} f]} {
	Debug.image {Raster image conversions by $f}
	variable convert $f

	proc raster2raster {r type} {
	    variable tmpdir
	    variable convert
	    set in [::fileutil::tempfile svg]
	    set out [::fileutil::tempfile out]
	    ::fileutil::writeFile -translation binary -- $in [dict get $r -content]
	    dict set r content-type image/svg+xml
	    set cfd [open |[list $convert $in $type:$out] r+]
	    chan configure $cfd -blocking 0
	    chan event $cfd readable [namespace code [list converting $cfd $r $type $out $in]]
	    return [Httpd Suspend $r]
	}

	# generate raster conversions
	foreach it {png jpeg gif} {
	    foreach jt {png jpeg gif} {
		if {$jt eq $it} continue
		proc .image/$it.image/$jt {r} [string map [list %I $jt] {
		    return [raster2raster $r %I]
		}]
	    }
	}
	incr conversions
    } else {
	Debug.image {Raster image conversions by 'convert' unavailable}
    }

    if {![catch {exec /usr/bin/which rsvg-convert} f]} {
	Debug.image {SVG->Raster image conversions by $f}
	variable rsvg $f

	proc .image/svg+xml.image/png {r} {
	    Debug.image {IMAGE: svg->image/png}
	    variable tmpdir
	    variable rsvg
	    set svg [::fileutil::tempfile svg]
	    set out [::fileutil::tempfile out]
	    ::fileutil::writeFile $svg [dict get $r -content]
	    dict set r content-type image/svg+xml
	    Debug.image {WITH: $rsvg -o $out $svg}
	    set cfd [open |[list $rsvg -o $out $svg] r+]
	    chan configure $cfd -blocking 0
	    chan event $cfd readable [namespace code [list converting $cfd $r image/png $out $svg]]
	    return [Httpd Suspend $r]
	}

	if {$convert ne ""} {
	    proc SVG2raster {r type} {
		Debug.image {IMAGE: svg->$type}
		variable rsvg
		variable convert
		set svg [::fileutil::tempfile svg]
		set out [::fileutil::tempfile out]
		::fileutil::writeFile $svg [dict get $r -content]
		dict set r content-type image/svg+xml
		Debug.image {WITH: $rsvg $svg | $convert - $type:$out}
		set cfd [open |[list $rsvg $svg | $convert - $type:$out] r+]
		chan configure $cfd -blocking 0
		chan event $cfd readable [namespace code [list converting $cfd $r image/$type $out $svg]]
		return [Httpd Suspend $r]
	    }
	    
	    proc .image/svg+xml.image/jpeg {r} {
		return [SVG2raster $r jpeg]
	    }
	    proc .image/svg+xml.image/gif {r} {
		return [SVG2raster $r gif]
	    }
	}
	incr conversions
    } elseif {![catch {exec /usr/bin/which inkscape} f]} {
	variable inkscape $f
	proc .image/svg+xml.image/png {r} {
	    variable tmpdir
	    variable inkscape
	    set svg [::fileutil::tempfile svg]
	    set png [::fileutil::tempfile png]
	    ::fileutil::writeFile $svg [dict get $r -content]
	    dict set r content-type image/svg+xml
	    set cfd [open |[list $inkscape --export-png=$png --without-gui $svg] r+]
	    chan configure $cfd -blocking 0
	    chan event $cfd readable [namespace code [list converting $cfd $r image/png $png $svg]]
	    return [Httpd Suspend $r]
	}

	if {$convert ne ""} {
	    proc SVG2raster {r type} {
		variable tmpdir
		variable inkscape
		variable convert
		set svg [::fileutil::tempfile svg]
		set png [::fileutil::tempfile png]
		set out [::fileutil::tempfile out]
		::fileutil::writeFile -- $svg [dict get $r -content]
		dict set r content-type image/svg+xml
		set cfd [open |[list $inkscape --export-png=$png --without-gui $svg && $convert $png $type:$out] r+]
		chan configure $cfd -blocking 0
		chan event $cfd readable [namespace code [list converting $cfd $r $type $out $png $svg]]
		return [Httpd Suspend $r]
	    }
	    
	    proc .image/svg+xml.image/jpeg {r} {
		return [SVG2raster $r jpeg]
	    }
	    proc .image/svg+xml.image/gif {r} {
		return [SVG2raster $r gif]
	    }
	}
	incr conversions
    } else {
	Debug.image {SVG->Raster image conversions unavailable}
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}

    if {$conversions} {
	::convert namespace ::Image	;# register image conversions
    }
}
