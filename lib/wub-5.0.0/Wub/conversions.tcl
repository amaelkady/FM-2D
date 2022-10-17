# conversions - Code to implement some standard mime conversions

package require struct::list
package require Html

Debug define jsloader 10
Debug define cssloader 10

package provide conversions 1.0

namespace eval ::conversions {
    # HTML DOCTYPE header
    variable htmlhead {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">}
    set htmlhead {<!DOCTYPE HTML>}

    # convert an HTML fragment to HTML
    proc .x-text/html-fragment.text/html {rsp} {
	Debug.convert {x-text/html-fragment conversion: $rsp}
	#puts stderr "FRAGMENT: $rsp"
	set rspcontent [dict get $rsp -content]

	if {[string match "<!DOCTYPE*" $rspcontent]} {
	    # the content is already fully HTML
	    return [Http Ok $rsp $rspcontent text/html]	;# content is already fully HTML
	}

	# if response is wrapped HTML fragment
	# (signified by existence of a -wrapper element)
	# then run an extra conversion phase over it.
	set wrapper [dict get? $rsp -wrapper]
	if {$wrapper ne ""} {
	    set wtype [dict get? $wrapper -type]
	    if {$wtype eq ""} {
		set wtype .style/sinorca.x-text/html-fragment
	    }
	    dict set wrapper content $rspcontent
	    dict set rsp -content $wrapper
	    dict set rsp content-type $wtype
	    
	    # expect there's a conversion from $wtype to html-fragment
	    set rsp [::convert convert $rsp]
	    set content [dict get $rsp -content]
	    if {[string match "<!DOCTYPE*" $content]} {
		return [Http Ok $rsp $content text/html]	;# content is already fully HTML
	    }
	}

	dict set rsp -raw 1

	variable htmlhead
	set content "${htmlhead}\n"
	    
	append content <html> \n
	append content <head> \n
	
	if {[dict exists $rsp -title]} {
	    append content [<title> [armour [dict get $rsp -title]]] \n
	}

	if {[dict exists $rsp -headers]} {
	    append content [join [dict get $rsp -headers] \n] \n
	}

	# add script and style preloads
	set preloads {}

	if {[dict exists $rsp -style]} {
	    dict for {n v} [dict get $rsp -style] {
		if {[string match !* $n]} {
		    lappend preloads $v
		} else {
		    lappend preloads [<stylesheet> $n {*}$v]
		    Debug.cssloader {$n $v}
		}
	    }
	}
	if {$preloads ne {}} {
	    append content [join $preloads \n] \n
	}
	
	append content </head> \n
	
	append content <body> \n
	append content $rspcontent
	
	# stuff to start on google api
	if {[dict exists $rsp -google]} {
	    append google "google.setOnLoadCallback(function() \{" \n
	    append google [join [dict get $rsp -google] \n] \n
	    append google "\});" \n
	    append content [<script> $google]
	}
	
	# add script postscripts
	if {[dict exists $rsp -script]} {
	    dict for {n v} [dict get $rsp -script] {
		if {[string match !* $n]} {
		    append content \n $v \n
		} else {
		    append content \n [<script> src $n {*}$v] \n
		    Debug.jsloader {$n $v}
		}
	    }
	}

	# add script postloads - can't remove this until WubWikit's fixed
	if {[dict exists $rsp -postload]} {
	    append content \n [join [dict get $rsp -postload] \n] \n
	}
		
	append content </body> \n
	append content </html> \n

	Debug.convert {x-text/html-fragment DONE: $rsp}
	#puts stderr "FRAGMENT done: $rsp"
	return [Http Ok $rsp $content text/html]
    }

    # STX CSS component dict
    variable stxCSS {
	rel stylesheet
	type text/css
	href /css/stx.css
	media screen
	title screen
    }

    # convert STX to an HTML fragment
    proc .x-text/stx.x-text/html-fragment {rsp} {
	package require stx2html

	set code [catch {
	    stx2html::translate [dict get $rsp -content]
	} result eo]

	if {$code} {
	    return [Http ServerError $rsp $result $eo]
	} else {
	    variable stxCSS
	    dict lappend rsp -headers [<link> {*}$stxCSS]
	    return [Http Ok $rsp $result x-text/html-fragment]
	}
    }

    # an in-band redirection
    proc .x-system/redirect.text/html {rsp} {
	set to [dict get $rsp -content]
	return [Http Redirect $rsp $to]
    }

    # convert system text to an HTML fragment
    proc .x-text/system.x-text/html-fragment {rsp} {
	# split out headers
	set headers ""
	set body [split [string trimleft [dict get $rsp -content] \n] \n]
	set start 0
	set headers {}

	foreach line $body {
	    set line [string trim $line]
	    if {[string match <* $line]} break

	    incr start
	    if {$line eq ""} continue

	    # this is a header line
	    set val [lassign [split $line :] tag]
	    if {$tag eq "title"} {
		dict append rsp -title $val
	    } else {
		dict lappend rsp -headers [<$tag> [string trim [join $val]]]
	    }
	}

	set content "[join [lrange $body $start end] \n]\n"

	return [Http Ok $rsp $content x-text/html-fragment]
    }

    # convert a form into fragmentary html
    proc .x-text/form.x-text/html-fragment {rsp} {
	package require Form

	# grab the form
	set form [dict get $rsp -content]
	set form [string map [list %REFERER% [dict get? $rsp referer]] $form] ;# subst REFERER
	dict set form -record [Query flatten [Query parse $rsp]] ;# reflect query in -record

	# this file is dynamic - prevent caching
	catch {dict unset rsp -modified}
	catch {dict unset rsp -depends}

	# process and return the form
	return [Http NoCache [Http Ok $rsp [Form html $form] x-text/html-fragment]]
    }

    # convert an aggregate into an HTML fragment
    proc .multipart/x-aggregate.x-text/html-fragment {rsp} {
	Debug.convert {multipart/x-aggregate conversion: $rsp}
	set result ""
	set content [dict get $rsp -content]

	foreach c [dict get $content -components] {
	    if {![dict exists $content -content $c]} continue

	    set component [dict get $content -content $c]
	    dict set component accept x-text/html-fragment
	    Debug.convert {multipart/x-aggregate conversion: component $component}
	    set component [[dict get $rsp -hostobj] call Convert transform $component]
	    append result [dict get $component -content] \n
	}

	return [Http Ok $rsp $result x-text/html-fragment]
    }

    variable safe 0		;# make safe interpreters?

    if {0} {proc interp_create {} {
	variable safe
	if {$safe} {
	    set interp [interp create -safe]
	} else {
	    set interp [interp create]
	}

	return $interp
    }}

    proc tmls {code rsp} {
	Debug.convert {tmls $code: $rsp}

	if {[dict get $rsp content-type] ne "application/x-climb-list"} {
	    Debug.error {template tmls got strange response: $code - $rsp}
	}

	if {[catch {
	    # recover original template from climb_list
	    set tmls [lassign [dict get $rsp -content] c1 otype template]

	    set interp [dict get $rsp -interp]
	    dict unset rsp -interp

	} r eo]} {
	    Debug.convert {.tml error: $r ($eo)}
	}

	# source each tml in reverse order.
	foreach {script ttype c} [struct::list reverse $tmls] {
	    Debug.convert {.tml evaluating $c - $ttype - ($script)}
	    set code [catch {
		$interp eval $script
	    } result eo]

	    if {$code} {
		Debug.convert {.tml eval error: $r ($eo)}
	    }
	}

	# perform template substitution
	Debug.convert {template ($template)}
	#puts stderr "template ($template)"
	set code [catch {
	    $interp eval subst [list $template]
	} result eo]

	set rsp [$interp eval set ::response]	;# get response dict

	interp delete $interp	;# destroy interpreter

	if {$code} {
	    # error in substitution
	    if {[dict exists $rsp -code]} {
		return -code [dict get $rsp -code] -response $rsp $result
	    } else {
		do respond ServerError $rsp $result $eo
	    }
	} else {
	    # completed substutition
	    dict set rsp -content $result
	    set dynamic [dict get $rsp -dynamic]

	    if {$dynamic} {
		return [Http Ok [Http NoCache $rsp] $result]
	    } else {
		#dict unset rsp -dynamic
		return [Http CacheableContent $rsp \
			    [clock seconds] $result]
	    }
	}
    }

    proc .x-application/tcl-template {rsp} {
	# create an interp or use the request's -interp
	if {![dict exists $req -interp]} {
	    set interp [interp_create]
	    interp alias $interp Httpd {} [dict get $req -http] 
	    interp alias $interp Host {} ::[dict get $req -hostobj]
	    interp alias $interp Self {} $self

	    foreach cmd {Http Query Entity Cookies} {
		interp alias $interp $cmd {} $cmd
	    }
	} else {
	    # use the pre-existing interp
	    set interp [dict get $req -interp]
	}

	# set up response in interp
	catch {dict unset rsp -code}	;# let subst set -code value
	dict set rsp -dynamic 1	;# default: not dynamic
	dict set rsp content-type x-text/html-fragment ;# default mime type

	$interp eval set ::response [list $rsp]

	#trace add command $interp {rename delete} trace_pmod

	# template signals dynamic content with this
	interp alias $interp Template_Dynamic \
	    $interp dict set ::response -dynamic 1
	interp alias $interp Template_Static \
	    $interp dict set ::response -dynamic 0

	dict set rsp -interp $interp
	set x [Url parse [dict get $rsp -url]]
	set path [dict get $x -path]
	dict set x -path [file join [file dirname $path] .tml]

	# load .tml files up to root
	do all $rsp [Url uri $x] ::conversions::tmls
    }

    proc .x-application/directory.x-text/dict {rsp} {
	set suffix [file dirname [dict get $rsp -suffix]]
	set prefix [dict get $rsp -prefix]
	set root [dict get $rsp -root]
	set fulldir [file join $root [string trim $suffix /]]

	set files {}
	dict for {file stat} [dict get $rsp -content] {
	    lappend files [list $file [dict get $stat mtime] [dict get $stat size]]
	}

	array set query [Query flatten [Query parse $rsp]]
	if {[info exists query(sort)]} {
	    set sort [string tolower $query(sort)]
	} else {
	    set sort name
	}

	array set sorter {name sort=name date sort=date size sort=size}

	if {[info exists query(reverse)]} {
	    set order -decreasing
	} else {
	    set order -increasing
	    append sorter($sort) "&reverse"
	}

	switch -- $sort {
	    name {
		set files [lsort -index 0 $order -dictionary $files]
	    }
	    date {
		set files [lsort -index 1 $order -integer $files]
	    }
	    size {
		set files [lsort -index 2 $order -integer $files]
	    }
	}

	set dp [file join $prefix $suffix]
	set url [string trimright [dict get $rsp -url] /]
	Debug.convert {dirList: $dp - $url - $suffix - ($files)}
	
	set dirlist "<table class='dirlist' border='1'>\n"
	append dirlist "<thead>" \n
	append dirlist "<tr><th>Name</th>" \n
	append dirlist "<th>Modified</th>" \n
	append dirlist "<th>Size</th></tr>" \n

	set pdir [string trimright [file dirname ${dp}] /]
	append dirlist "<tr><td><a href='${pdir}/'>..</a></td></tr>" \n
	append dirlist "</thead>" \n

	append dirlist "<tbody>" \n
	foreach file $files {
	    lassign $file name date size
	    append dirlist "<tr>\n"
	    append dirlist "<td><a href='${dp}/$name'>$name</a></td>" \n
	    append dirlist "<td>[Http Date $date]</td>" \n
	    append dirlist "<td>$size</td>" \n
	    append dirlist "</tr>" \n
	}
	append dirlist "</tbody>" \n
	append dirlist "</table>" \n

	if {$suffix eq ""} {
	    set dir /
	} else {
	    set dir $suffix
	}

	dict append rsp -title "${dir} Directory"
	append result "<h1>$dir</h1>" \n
	append result $dirlist \n

	return [Http Ok $rsp $result x-text/system]
    }

    # convert a directory list
    proc .x-application/directory.x-text/table {rsp} {
	set content {}
	foreach name [glob -directory [dict get $req -directory] *] {
	    switch -- [file type $name] {
		link {
		    set file [file readlink $name]
		}
		file - directory {
		    set file $name
		}
		default {
		    continue
		}
	    }
	    catch {unset attr}
	    file lstat $file attr
	    dict set rsp -content [file tail $name] \
		[dict merge [file attributes $file] [array get attr]]
	}
	dict set content-type x-text/table
	return $rsp
    }

    proc .x-tclobj/resultset.x-tclobj/dict {r} {
	set resultset [dict get $r -content]
	set result [$resultset allrows -as dicts]
	return [Http pass $r $result x-tclobj/dict]
    }

    proc .x-tclobj/huddle.text/yaml {r} {
	package require yaml
	set result [::yaml::huddle2yaml [dict get $r -content]]
	return [Http pass $r $result text/yaml]
    }

    proc .x-tclobj/huddle.application/json {r} {
	set result [huddle jsondump [dict get $r -content]
	return [Http pass $r $result application/json]
    }

    proc .x-tclobj/dict.x-tclobj/huddle {r} {
	package require huddle
	set huddle [dict get? $r -huddle]
	if {$huddle eq ""} {
	    set huddle dict
	}
	set result [huddle compile $huddle [dict get $r -content]]
	return [Http pass $r $result x-tclobj/huddle]
    }

    # convert a directory list
    proc .x-multipart/dirlist.x-text/system {rsp} {
	set suffix [file dirname [dict get $rsp -suffix]]
	set prefix [dict get $rsp -prefix]
	set root [dict get $rsp -root]
	set fulldir [file join $root [string trim $suffix /]]

	set files {}
	dict for {file stat} [dict get $rsp -content] {
	    lappend files [list $file [dict get $stat mtime] [dict get $stat size]]
	}

	array set query [Query flatten [Query parse $rsp]]
	if {[info exists query(sort)]} {
	    set sort [string tolower $query(sort)]
	} else {
	    set sort name
	}

	array set sorter {name sort=name date sort=date size sort=size}

	if {[info exists query(reverse)]} {
	    set order -decreasing
	} else {
	    set order -increasing
	    append sorter($sort) "&reverse"
	}

	switch -- $sort {
	    name {
		set files [lsort -index 0 $order -dictionary $files]
	    }
	    date {
		set files [lsort -index 1 $order -integer $files]
	    }
	    size {
		set files [lsort -index 2 $order -integer $files]
	    }
	}

	set dp [file join $prefix $suffix]
	set url [string trimright [dict get $rsp -url] /]
	Debug.convert {dirList: $dp - $url - $suffix - ($files)}
	
	set dirlist "<table class='dirlist' border='1'>\n"
	append dirlist "<thead>" \n
	append dirlist "<tr><th>Name</th>" \n
	append dirlist "<th>Modified</th>" \n
	append dirlist "<th>Size</th></tr>" \n

	set pdir [string trimright [file dirname ${dp}] /]
	append dirlist "<tr><td><a href='${pdir}/'>..</a></td></tr>" \n
	append dirlist "</thead>" \n

	append dirlist "<tbody>" \n
	foreach file $files {
	    lassign $file name date size
	    append dirlist "<tr>\n"
	    append dirlist "<td><a href='${dp}/$name'>$name</a></td>" \n
	    append dirlist "<td>[Http Date $date]</td>" \n
	    append dirlist "<td>$size</td>" \n
	    append dirlist "</tr>" \n
	}
	append dirlist "</tbody>" \n
	append dirlist "</table>" \n

	if {$suffix eq ""} {
	    set dir /
	} else {
	    set dir $suffix
	}

	dict append rsp -title "${dir} Directory"
	append result [<h1> $dir] \n
	append result $dirlist \n

	return [Http Ok $rsp $result x-text/system-text]
    }
}
