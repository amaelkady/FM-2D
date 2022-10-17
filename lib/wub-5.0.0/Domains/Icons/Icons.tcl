# icons package - nice set of free icons
# http://www.freeiconsweb.com/Free_web_development_icons_04.html
# License says it's free.

package require Debug
Debug define icons 10

package require RAM
package require fileutil

package provide Icons 1.0

set ::API(Domains/Icons) {
    {provides a set of nice icons}
}

namespace eval ::Icons {
    variable mount /icons/
    variable icons; array set icons {}
    variable home [file join [file dirname [file normalize [info script]]] images]

    # map symbolic name to icon in array
    foreach {name icon} {
	oend oend.gif
	ostart ostart.gif
	plus 001_01.gif
	minus 001_02.gif
	bplus 001_03.gif
	bminus 001_04.gif
	cross 001_05.gif
	tick 001_06.gif
	square 001_07.gif
	dsquare 001_08.gif
	bullseye 001_09.gif
	dbullseye 001_10.gif
	attention 001_11.gif
	bmail 001_12.gif
	rmail 001_13.gif
	heart 001_14.gif
	star 001_15.gif
	hstar 001_16.gif
	wstar 001_17.gif
	thumbsup 001_18.gif
	thumbsdown 001_19.gif
	home 001_20.gif
	rightb 001_21.gif
	downb 001_22.gif
	leftb 001_23.gif
	upb 001_24.gif
	right 001_25.gif
	down 001_26.gif
	left 001_27.gif
	up 001_28.gif
	hcross 001_29.gif
	exclam 001_30.gif
	magnifier_button 001_37.gif
	magnifier 001_38.gif
	recycle 001_39.gif
	world 001_40.gif
	key 001_41.gif
	lock 001_42.gif
	folder 001_43.gif
	factory 001_44.gif
	pencil 001_45.gif
	trash 001_49.gif

	cart 001_46.gif
	bcartplus 001_47.gif
	bcart 001_48.gif

	bubble 001_50.gif
	silhouette 001_54.gif
	male 001_55.gif
	female 001_56.gif
	people 001_57.gif

	rss_orange 001_31.gif
	tag_orange 001_34.gif
	end_orange 001_51.gif
	sq_right_orange 001_58.gif

	rss_blue 001_33.gif
	tag_blue 001_35.gif
	end_blue 001_53.gif
	sq_right_blue 001_60.gif

	rss_green 001_32.gif
	tag_green 001_36.gif
	end_green 001_52.gif
	sq_right_green 001_59.gif
    } {
	set ext [file extension $icon]
	set icons($name$ext) [list [::fileutil::cat -translation binary [file join $home $icon]] image/[string trim $ext .]]
    }

    foreach file [glob [file join $home ?*.*]] {
	set icon [file tail $file]
	if {[string match .* $icon]} continue
	if {![string match 001* $icon]} {
	    set ext [file extension $icon]
	    set icons($icon) [list [::fileutil::cat -translation binary $file] image/[string trim $ext .]]
	}
    }

    #Debug.icons {Icons: [array names icons]}
    proc add {name icon mime} {
	variable icons
	set icons($name) [list $icon $mime]
    }

    variable dirparams {
	sortable 1
	evenodd 1
	class table
	tparam {title table}
	hclass header
	hparam {title column}
	thparam {class thead}
	fclass footer
	tfparam {class tfoot}
	rclass row
	rparam {title row}
	eclass el
	eparam {title element}
	footer {}
    }

    proc all {rsp} {
	Debug.icons {dir $rsp}
	variable icons; variable mount
	set idict {}
	foreach name [lsort -dictionary [array names icons]] {
	    dict set idict $name [list name $name icon [<img> src [file join $mount $name]]]
	}
	variable dirparams
	set report [Report html $idict {*}$dirparams headers {name icon}]
	Debug.icons "Report: $report"
	return [Http Ok $rsp $report x-text/html-fragment]
    }

    proc do {rsp} {
	variable mount

	# compute suffix
	if {[dict exists $rsp -suffix]} {
	    # caller has munged path already
	    set suffix [dict get $rsp -suffix]
	    Debug.icons {-suffix given $suffix}
	} else {
	    # assume we've been parsed by package Url
	    # remove the specified prefix from path, giving suffix
	    set path [dict get $rsp -path]
	    set suffix [Url pstrip $mount $path]
	    Debug.icons {-suffix not given - calculated '$suffix' from '$mount' and '$path'}
	    if {($suffix ne "/") && [string match "/*" $suffix]} {
		# path isn't inside our domain suffix - error
		return [Http NotFound $rsp]
	    }
	}

	# this stuff just doesn't change.
	if {[dict exists $rsp if-modified-since]} {
		return [Http NotModified $rsp]
	}
	
	# catalog
	if {$suffix eq "/"} {
	    return [all $rsp]
	}

	variable icons
	Debug.icons {exists $suffix [info exists icons($suffix)]}
	if {![info exists icons($suffix)]} {
	    # path isn't inside our domain suffix - error
	    return [Http NotFound $rsp]
	}

	dict set rsp accept image/*
	lassign $icons($suffix) icon mime

	variable expires
	return [Http Ok [Http Cache $rsp $expires] $icon $mime]
    }

    proc new {args} {
	variable expires "next week"
	variable {*}$args
	variable {*}[Site var? Icons]	;# allow .ini file to modify defaults
	return ::Icons
    }
    proc create {junk args} {
	return [new {*}$args]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}
