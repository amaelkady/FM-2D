package require stx
package require Form
package provide stx2html 1.1
package require Html

namespace eval stx2html {
    variable features; array set features {}
    variable toc; array set toc {}
    variable toccnt {}
    variable tagstart 0	;# number to start tagging TOC sections
    variable title ""	;# title of page
    variable img_properties {}

    variable class [list class editable]
    variable exclude {+dlist +dt +li}

    proc id {lc} {
	variable exclude
	lassign $lc id start end data
	if {0 && [info exists start]
	    && [lindex [info level -1] 0] ni $exclude
	} {
	    variable class
	    set data [join $data "&\#x0A"]
	    set result [list id $id {*}$class data $data]
	} else {
	    set result [list id $id]
	}

	return $result
    }

    proc tagstart {what} {
	variable tagstart $what
    }
    
    # redefine subst - we only ever want commands in this application
    proc subst {what} {
	set result [::subst -nobackslashes -novariables $what]
	Debug.STX {subst: $what -> '$result'}
	return $result
    }
    
    proc +cdata {lc args} {
	Debug.STX {cdata: $args}
	return [join $args]
    }

    proc +normal {lc para args} {
	Debug.STX {+normal: $lc '$para' '$args'}
	return "[<p> {*}[id $lc] [subst $para]]\n[join $args]"
    }

    proc +pre {lc para args} {
	Debug.STX {pre: $lc '$para' '$args'}
	return "[<pre> {*}[id $lc] $para]\n[join $args]\n"
    }

    # process .special lines
    proc +special {lc para args} {
	Debug.STX {special: $lc '$para' '$args'}
	set para [string map {
	    "\x87" ;
	    "\x89" \{
	    "\x8A" \}
	    "\x8B" $
	} $para]
	set para [string map {
	    "&lt;" <
	    "&gt;" >
	} $para]
	Debug.STX {special: $para}

	set p [join [lassign [split $para] cmd]]
	set cmd [string trimleft [string tolower $cmd] .]
	if {[llength [info commands "_$cmd"]] == 1} {
	    # substitute function value into output
	    set para [_$cmd {*}$p]
	} else {
	    # add to features array
	    variable features
	    set features($cmd) $p
	    set para "<!-- special: $cmd $p -->\n"
	    #set para [<p> [::stx::char $para]]
	}
	return "$para\n[join $args]\n"
    }

    # give contents of features array to caller
    proc features {} {
	variable features
	return [array get features]
    }

    proc _title {args} {
	variable title [join $args]
	return ""
    }

    proc _message {args} {
	Debug.STX {STX Message: [join $args]}
	return ""
    }

    proc _comment {args} {
	return "<!-- [join $args] -->\n"
    }

    proc _notoc {args} {
	variable features
	set features(NOTOC) 1
	return ""
    }

    proc _toc {args} {
	variable features
	set features(TOC) 1
	catch {unset features(NOTOC)}
	return "\x81TOC\x82"
    }

    proc +header {lc level args} {
	Debug.STX {+header lc:$lc level:$level tag:$tag args:($args)}
	variable toc
	variable toccnt
	while {[llength $toccnt] <= $level} {
	    lappend toccnt 0
	}
	set toccnt [lrange $toccnt 0 $level]

	lset toccnt $level [expr [lindex $toccnt $level] + 1]
	set tag [lindex $lc 0]	;# ignore the tag, use the id
	set toc([join [lrange $toccnt 1 $level] .]) [list [join $args] $tag]

	set p [subst [join $args]]
	variable title
	if {$title eq ""} {
	    set title $p
	}

	return "[<h$level> {*}[id $lc] $p]\n"
    }

    proc +hr {lc} {
	Debug.STX {hr: $lc}
	return [<hr> {*}[id $lc] style {clear:both;}]
    }

    proc +indent {lc para} {
	Debug.STX {indent: $lc '$para'}
	return [<p> {*}[id $lc] [subst $para]]
    }

    proc +table {lc args} {
	Debug.STX {table: $lc '$args'}
	return [<table> {*}[id $lc] [join $args \n]]\n
    }

    proc +row {lc args} {
	Debug.STX {row: $lc '$args'}
	set els {}
	foreach el $args {
	    lappend els [subst $el]
	}
	return [<tr> {*}[id $lc] [<td> [join $els </td><td>]]]
    }

    proc +hrow {lc args} {
	Debug.STX {hrow: $lc '$args'}
	set els {}
	foreach el $args {
	    lappend els [subst $el]
	}
	return [<tr> {*}[id $lc] [<th> [join $els </th><th>]]]
    }

    proc +dlist {lc args} {
	Debug.STX {dlist: $lc '$args'}
	return [<dl> {*}[id $lc] [join $args \n]]\n
    }

    proc +dt {lc term} {
	return [<dt> {*}[id $lc] [subst $term]]
    }

    proc +dd {lc def} {
	return [<dd> {*}[id $lc] [subst $def]]
    }

    proc +dl {lc term def} {
	Debug.STX {+dl: $lc $term / $def}
	return "[+dt $lc $term]\n[+dd $lc $def]\n"
    }

    # make list item
    proc +li {lc content args} {
	Debug.STX {+li: ($lc) '$content' '$args'}
	return [<li> {*}[id $lc] "[subst $content] [join $args]"]
    }

    # translate unordered list
    proc +ul {lc args} {
	Debug.STX {+ul: $lc '$args'}
	return [<ul> {*}[id $lc] [join $args \n]]
    }

    proc +ol {lc args} {
	Debug.STX {ol: $lc '$args'}
	return [<ol> {*}[id $lc] [join $args \n]]
    }

    # This is a NOOP to convert local references to HTML
    # the application should supply its own version to the translate call
    proc local {what} {
	# org code
	set body [join [lassign [split $what] href]]
	if {$body eq ""} {
	    set body $what
	}
	return [<a> href $href $body]

	return $what

	# org code
	set what [split $what]
	return [<a> href [lindex $what 0] [join [lrange $what 1 end]]]
    }

    # make reference content
    proc +ref {num} {
	variable refs
	set what [dict get $refs $num]
	set body [string trim [join [lassign [split $what :] proto] :]]
	set proto [string trim $proto]
	Debug.STX {2HTML ref($num) '$proto' '$body'}

	switch -glob -- $proto {
	    http {
		set text [string trim [join [lassign [split $body] href]]]
		set href [string trim $href]
		if {$text eq ""} {
		    set text http:$body
		}
		if {![string match /* $href]} {
		    set what [<a> href $href $text]
		} else {
		    set what [<a> href http:$href $text]
		}
	    }

	    acronym {
		set body [split $body "|"]
		set text [string trim [join [lrange $body 1 end]]]
		set body [string trim [lindex $body 0]]
		set what [<acronym> title $text $body]
	    }

	    \# {
		set body [split $body]
		set text [string trim [join [lrange $body 1 end]]]
		set body [string trim [lindex $body 0]]
		set what [<a> name $body $text]
	    }

	    image {
		set body [split $body]
		set text [string trim [join [lrange $body 1 end]]]
		set body [string trim [lindex $body 0]]
		if {[string match /* $body]} {
		    set body "http:$body"
		}
		if {$text eq ""} {
		    set text $body
		}
		variable img_properties
		set what [<img> src $body class image {*}$img_properties alt $text]
	    }

	    left {
		set body [split $body]
		set text [string trim [join [lrange $body 1 end]]]
		set body [string trim [lindex $body 0]]
		if {[string match /* $body]} {
		    set body "http:$body"
		}
		if {$text eq ""} {
		    set text $body
		}
		variable img_properties
		set what [<img> src $body class imageleft {*}$img_properties style "float:left" alt $text]
	    }

	    right {
		set body [split $body]
		set text [string trim [join [lrange $body 1 end]]]
		set body [string trim [lindex $body 0]]
		if {[string match /* $body]} {
		    set body "http:$body"
		}
		if {$text eq ""} {
		    set text $body
		}
		variable img_properties
		set what [<img> src $body class imageleft {*}$img_properties style "float:right" alt $text]
	    }

	    fieldset {
		catch {Form fieldsetS {*}$body {}} what eo
	    }
	    /fieldset {
		set what </fieldset>
	    }

	    form {
		catch {Form formS {*}$body {}} what eo
	    }

	    /form {
		set what </form>
	    }

	    selectset {
		set body [string map [list "\x89" \{ "\x8A" \}] $body]
		set opts [join [lindex $body end] \n]

		if {[catch {<${proto}> {*}[lrange $body 0 end-1] $opts} what eo]} {
		    append what ($eo)
		}
		append what \n
	    }

	    radioset - checkset {
		set body [string map [list "\x89" \{ "\x8A" \}] $body]
		set opts {}
		foreach {opt val} [lindex $body end] {
		    lappend opts [list $opt $val]
		}
		set opts [join $opts \n]

		if {[catch {<${proto}> {*}[lrange $body 0 end-1] $opts} what eo]} {
		    append what ($eo)
		}
		append what \n
	    }

	    password - text - hidden - file - image - textarea -
	    button - reset - submit - radio - checkbox - legend {
		catch {<${proto}> {*}$body} what eo
		append what \n
	    }

	    default {
		variable local
		Debug.STX {local resolution: $local ($what)}
		set what [$local $what]
	    }
	}

	return $what
    }

    # make content underlined
    proc underline {args} {
	return [<span> style {text-decoration:underline;} [join $args]]
    }

    # make content underlined
    proc strike {args} {
	return [<span> style {text-decoration:line-through;} [join $args]]
    }

    # make content subscript
    proc subscript {args} {
	return [<span> style {vertical-align:sub;} [join $args]]
    }

    # make content superscript
    proc superscript {args} {
	return [<span> style {vertical-align:super;} [join $args]]
    }

    # make content big
    proc big {args} {
	return [<span> style {font-size:bigger;} [join $args]]
    }

    # make content strong
    proc strong {args} {
	return [<span> style {font-weight:bold;} [join $args]]
    }

    # make content italic
    proc italic {args} {
	return [<span> style {font-style:italic;} [join $args]]
    }

    # make content italic
    proc smallcaps {args} {
	return [<span> style {font-variant:small caps;} [join $args]]
    }

    proc toc {} {
	variable toc
	set result "<table class='TOC'>\n"
	append result "<thead><tr><td colspan='2'>Table Of Contents</td></tr></thead>"
	foreach sect [lsort -dictionary [array names toc]] {
	    append body [<tr> "[<td> class TOCnum [<a> href \#[lindex $toc($sect) 1] $sect]] [<td> [join [lindex $toc($sect) 0]]] \n"]
	}
	append result [<tbody> $body] \n
	append result </table> \n
	return $result
    }
    
    proc +scope {num} {
	variable scope
	set what [dict get $scope $num]
	Debug.STX {scope: $num ($what)}
	variable script
	if {$script} {
	    return [interp eval istx subst [list $what]]
	} else {
	    return "evaluation disabled"
	}
    }
    
    # convert structured text to html
    proc trans {text args} {
	Debug.STX {trans args: $args}

	variable features
	array unset features
	set features(NOTOC) 1

	variable local ::stx2html::local

	variable toc; array unset toc

	variable title ""
	variable toccnt {}
	variable tagstart	;# number to start tagging TOC sections

	variable script
	variable node2lc {}

	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	set args [dict merge {class editable} $args]

	dict with args {}
	#{locallink ::stx2html::local} {offset 0}

	lassign [stx::translate $text local $local {*}$args] stx tree l2n
	Debug.STX {TRANSLATE: $stx}

	variable refs [$tree get root refs]
	variable scope [$tree get root scope]
	set content [lindex [namespace inscope ::stx2html subst [list $stx]] 0]

	if {0} {
	    set content ""; set content1 ""; set content2 ""
	    if {[catch {stx::translate $text} content eo]} {
		return "<p>STX Error translate: '$text'<br>-> $eo</p>"
	    }
	    if {[catch {
		namespace inscope ::stx2html subst [list $content]
	    } content1 eo]} {
		return "<p>STX Error subst: $content<br>-> $eo</p>"
	    }
	    if {[catch {lindex $content1 0} content eo]} {
		return "<p>STX Error lindex: '$content1'<br>-> $eo</p>"
	    }
	}

	if {![info exists features(NOTOC)]} {
	    if {[info exists features(TOC)]} {
		set content [string map [list "\x81TOC\x82" [toc]] $content]
	    } elseif {[array size toc] > 3} {
		set content "[toc]\n$content"
	    }
	} else {
	    set content [string map [list "\x81TOC\x82" ""] $content]
	}

	set content [string map [list "\x88" "&\#" "\x89" "\{" "\x8A" "\}" "\x8B" "$" "\x87" "\;" "\x84" "&#91\;" "\x85" "&#93\;" "\\" ""] $content]
	return [list $content $tree $l2n]
    }

    proc translate {text args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	Debug.STX {translate args: ($args)}
	lassign [trans $text {*}$args] content
	return $content
    }

    proc Translate {text args} {
	variable features
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	lassign [trans $text {*}$args] content tree l2n
	Debug.STX {Translate: $content}
	return [list $content [array get features] $tree $l2n]
    }

    variable packages {Form}
    variable script 0
    variable home [file dirname [file normalize [info script]]]
    variable path [list [info library] /usr/share/tcltk/tcl[info tclversion]/ [file dirname $home]/Utilities/ [file dirname $home]/extensions/ /usr/lib/tcllib1.10/textutil/]
    #puts stderr "PATH:$path"
    proc init {args} {
	if {$args ne {}} {
	    variable {*}$args
	}

	variable script
	variable packages
	variable path
	variable home

	if {$script && ![interp exists istx]} {
	    # create our scope interpreter
	    #puts stderr "Creating Safe istx"
	    variable path
	    ::safe::interpCreate istx -accessPath $path
	    #puts stderr "Initing Safe istx"
	    foreach p $packages {
		#puts stderr "Installing $p"
		interp eval istx [list package require $p]
		#puts stderr "Installed $p"
	    }
	    #puts stderr "Created Safe istx"
	}
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

stx2html init
