Basic {
    type Type

    # a conversion's mime type is always tcl script
    content {
	# determine the mime type of result
	set mime [my getmime [dict get? $r -tuple]]
	return [Http Ok $r [dict get $r -content] $mime]
    }
}

Conversion {
    type Type
}

"Tcl Script" {
    type Type
    content {
	# evaluate tuple of Template as the result of its tcl evaluation
	Debug.tupler {tcl script preprocessing ([dict get $r -content])}
	set tuple [dict get? $r -tuple]
	set content [dict with tuple [dict get $r -content]]
	
	# determine the mime type of result
	set mime [my getmime [dict get? $r -tuple]]
	
	Debug.tupler {tcl script to '$mime' mime type content:($result)}
	return [Http Ok $r $result $mime]
    }
}

Template {
    type Type
    content {
	# evaluate tuple of Template as the result of its tcl evaluation
	Debug.tupler {Template processing ([dict get $r -content])}
	set tuple [dict get $r -tuple]
	set result [dict with tuple {subst [dict get $r -content]}]

	# determine the mime type of result
	set mime [my getmime $tuple]
	if {$mime eq "tuple/template"} {
	    set mime tuple/html
	}
	Debug.tupler {Template to '$mime' mime type content:($result)}
	return [Http Ok $r $result $mime]
    }
}

*rform+jQ {
    type Text
    content {
	inc
    }
}

*rform+style {
    type css
    content {
	* {zoom: 1.0;}

	header {
	    display: block;  
	    clear: both;
	}

	footer {
	    display: block;  
	    text-align: center;
	    margin: 0;
	    clear: left;
	    float: left;
	    width: 100%;
	}
	
	nav {
	    display: block;  
	    float: left;
	    clear: left;
	    width: 10%;
	    padding: 0em 0.5em 0em 0.5em;
	    margin-right: 1em;
	    background: gainsboro;
	    -moz-border-radius-topleft:7px;
	    -moz-border-radius-topright:7px;
	    -moz-border-radius-bottomleft:7px;
	    -moz-border-radius-bottomright:7px;
	}

	aside {
	    display: block;  
	    float: right;
	    clear: right;
	    width: 10%;

	    background: gainsboro;
	    padding: 0em 0.5em 0em 0.5em;
	    margin-left: 1em;
	    -moz-border-radius-topleft:7px;
	    -moz-border-radius-topright:7px;
	    -moz-border-radius-bottomleft:7px;
	    -moz-border-radius-bottomright:7px;
	}
	
	section {
	    display: block;  

	    margin-left: 1em;
	    margin-right: 1em;
	}

	article {
	    display: block;  
	    width: 80%;
	    clear: both;
	}

	input.blur {
	    color:lightgray;
	}

	img.icon {
	    border:0px;
	    width:25px
	}

	div.nav {
	    float:right;
	    background: whitesmoke;
	    padding: 0.3em 0.7em;
	    -moz-border-radius-topleft:5px;
	    -moz-border-radius-topright:5px;
	    -moz-border-radius-bottomleft:5px;
	    -moz-border-radius-bottomright:5px;
	}

	h1, h2, h3, h4, h5, h6 {
	    background: darkslategray;
	    color: whitesmoke;
	    padding: 0.2em 0.5em;
	    -moz-border-radius-topleft:7px;
	    -moz-border-radius-topright:7px;
	    -moz-border-radius-bottomleft:7px;
	    -moz-border-radius-bottomright:7px;
	}

	table {
	    margin: 1em 1em 1em 2em;
	    background: whitesmoke;
	    border-collapse: collapse;
	}
	table td {
	    border: 1px silver solid;
	    padding: 0.2em;
	}
	table th {
	    border: 1px silver solid;
	    padding: 0.2em;
	    background: darkslategray;
	    color: white;
	    text-align: left;
	    -moz-border-radius-topleft:7px;
	    -moz-border-radius-topright:7px;
	    -moz-border-radius-bottomleft:7px;
	    -moz-border-radius-bottomright:7px;
	}
	table tr {
	    background: gainsboro;
	}
	table caption {
	    margin-left: inherit;
	    margin-right: inherit;
	    font-size: 150%;
	}

	fieldset {
	    background: whitesmoke;

	    -moz-border-radius-topleft:7px;
	    -moz-border-radius-topright:7px;
	    -moz-border-radius-bottomleft:7px;
	    -moz-border-radius-bottomright:7px;
	}

	fieldset > legend {
	    background: darkslategray;
	    color: white;
	    -moz-border-radius-topleft:5px;
	    -moz-border-radius-topright:5px;
	    -moz-border-radius-bottomleft:5px;
	    -moz-border-radius-bottomright:5px;
	}

	.button {
	    border: 1px solid #aaa;
	    -webkit-border-radius: 5px;
	    -moz-border-radius: 5px;
	    padding: 2px 5px;
	    margin: 0 3px;
	    cursor: pointer;
	    background: gainsboro;
	}

	.changed {
	    background-color: gainsboro;
	}

	.error {
	    color: red;
	}
    }
}

*rform+styleR {
    type Ref
    mime css
    content {*rform+css}
}

*rform+*edit {
    type "Tcl Script"
    content {
	if {[catch {my fetch [dict get $r -tuple _left]} T]} {
	    # this tuple doesn't exist, try *new
	    set r [Http SeeOther $r [dict get $r -tuple -left]+*new]
	    set result [dict get $r -content]
	} else {
	    Debug.tupler {*rform+*edit: ($T)}
	    set mime ""
	    set type ""
	    set content ""
	    dict with T {
		set content [::textutil::undent [::textutil::untabify $content]]
		set result [subst {
		    [<title> [string totitle "Editing $name"]]
		    [<form> Edit_$id class autoform action save/ {
			[<fieldset> Details_$id title $name {
			    [<legend> $name]
			    [<div> id result {}]
			    [<selectlist> type label "Type:" [my typeselect $type]]
			    [<text> mime label "Mime:" [string totitle $mime]]
			    [<submit> submit style {float:right;} "Save"]
			    [<br>]
			    [<textarea> content class autogrow style {width:99%; height:10em;} [string trim $content]]
			    [<hidden> id $id]
			    [<submit> submit style {float:right;} "Save"]
			}]
		    }]
		}]
	    }
	    
	    set result
	}
    }
}

*rform+*xray {
    type Html
    content {
	<p>Not Implemented</p>
    }
}

*rform+*edit+jQ {
    type Text
    content {
	form .autoform target '#result'
	autogrow .autogrow
    }
}

*rform+*save {
    type Html
    content {
	<p>Not Implemented</p>
    }
}

"Form" {
    type Type
    content {
	Debug.tupler {Form type}
	set form [::Form layout Form_[incr ::form_id] [dict get $r -content]]
	set query [Query flatten [Query parse $r]]
	set form [dict apply query {$form}]	;# subst vars from Query into form
	return [Http Pass $r $form tuple/html]
    }
}

"*rform+Not Found" {
    type Form
    content {
	form action save/ class autoform
	fieldset notfound[incr ::notfoundc] {
	    legend "New Tuple: $name"
	    selectlist type label "Type:" [my typeselect $type]
	    text mime label "Mime:" [string totitle $mime]
	    submit submit style {float:right;} "Save"
	    <br>
	    textarea content class autogrow style {width:99%; height:10em;} [string trim $content]
	    submit submit style {float:right;} "Save"
	}
    }
}

Glob {
    type Type
    content {
	# search tuples for name matching glob, return a List
	set tuple [dict get $r -tuple]
	Debug.tupler {GLOB conversion: [dict size $r] ($tuple)}
	dict with tuple {
	    if {$mime ne "text"} {
		set search [my tuConvert $tuple tuple/text tuple/$mime]
	    } else {
		set search [dict get $r -content]
	    }
	}
	set search [string trim $search]
	set result [my globByName $search]
	
	Debug.tupler {GLOB search: '$search' -> ($result)}
	return [Http Ok $r $result tuple/list]
    }
}

Match {
    type Type
    content {
	# search tuples for name matching glob, return a List
	set tuple [dict get $r -tuple]
	Debug.tupler {Match: [dict size $r] ($tuple)}
	dict with tuple {
	    if {$mime ne "text"} {
		set search [my tuConvert $tuple tuple/text tuple/$mime]
	    } else {
		set search [dict get $r -content]
	    }
	    if {[catch {
		dict size $search
	    }]} {
		error "Match $name - content is not a Tcl Dict"
	    }
	}
	set result {}
	foreach i [my match $search] {
	    lappend result #$i
	}
	Debug.tupler {Match: '$search' -> ($result)}
	return [Http Ok $r $result tuple/list]
    }
}

"Tests+Match" {
    type Match
    mime Text
    content {
	%name Named%
    }
}

Named+List {
    type Conversion
    content {
	# search tuples for name matching regexp, return a List
	set tuple [dict get $r -tuple]
	dict with tuple {
	    if {$mime ni {"basic text"}} {
		set search [my tuConvert $tuple tuple/text]
	    } else {
		set search [dict get $r -content]
	    }
	}
	set search [string trim $search]
	set result [my regexpByName $search]
	return [Http Ok $r $result tuple/list]
    }
}

Javascript {
    type Type
    expiry tomorrow
}

Javascript+Html {
    type Conversion
    content {
	return [Http Ok $r [<script> [dict get $r -content]]] tuple/html]
    }
}

Javascript+Head {
    type Conversion
    content {
	return [Http Ok $r [<script> [dict get $r -content]]] tuple/head]
    }
}

CSS {
    type Type
    expiry tomorrow
}

CSS+Html {
    type Conversion
    content {
	set c [dict get $r -content]
	return [Http Ok $r [<pre> "&lt;style&gt;\n$c\n&lt;/style&gt;"] tuple/html]
    }
}

CSS+Head {
    type Conversion
    content {
	return [Http Ok $r [<stylesheet> [dict get $r -tuple name]] tuple/head]
    }
}

Ref+Html {
    type Conversion
    content {
	set content [dict get $r -content]
	set mime [dict get $r -tuple mime]
	set id [dict get $r -tuple id]

	set c [my tuConvert [dict get $r -content] tuple/text]

	# each ref determines its referenced content's type
	switch -glob -- $mime {
	    css -
	    text/css {
		set content [<stylesheet> {*}$content]
		# should this be in an html body?
	    }

	    javascript -
	    */javascript {
		set content [<script> type text/javascript src {*}$content {}]
	    }

	    transclude/* {
		set content [<div> id T_$id class transclude href {*}$content]
	    }

	    image/* {
		set content [<img> id T_$id src {*}$content]
	    }

	    default {
		set content [<a> id T_$id href {*}$content]
	    }
	}
	return [Http Ok $r $content tuple/html]
    }
}

Ref+Head {
    type Conversion
    content {
	set content [dict get $r -content]
	set mime [dict get $r -tuple mime]
	set id [dict get $r -tuple id]

	switch -glob -- $mime {
	    css -
	    text/css {
		set content [<stylesheet> {*}$content]
	    }

	    javascript -
	    */javascript {
		set content [<script> type text/javascript src {*}$content {}]
	    }

	    default {
		return -code error -kind type -notfound $id "ref of type $mime has no rendering as Head"
	    }
	}

	return [Http Ok $r $content tuple/head]
    }
}

Dict {
    type Type
    content {
	# do some form checking on the dict
	if {[catch {dict size [dict get? $r -content]} e eo]} {
	    return [Http Ok $r [subst {
		[<h2> "Type error"]
		[<p> "'[armour [dict get $r -tuple name]]' is of Type 'Dict', however its content is not a properly-formed dictionary."]
		[<p> "Dictionaries are tcl lists with an even number of elements."]
		[<h2> Content:]
		[<pre> [armour [dict get? $r -content]]]
	    }] tuple/html]
	} else {
	    return [Http Pass $r]
	}
    }
}

List+Dict {
    type Conversion
    content {
	Debug.tupler {list conversion: [dict size $r] ($r)}
	# make a list into a Dict by making tuple name the key
	set result {}
	foreach v [dict get $r -content] {
	    set v [my fetch $v]
	    dict set result [dict get $v name] [dict set $v id]
	}
	return [Http Ok $r [join $result \n] tuple/dict]
    }
}

List+Html {
    type Conversion
    content {
	Debug.tupler {List to Html conversion: ([dict get $r -content])}
	set result ""
	foreach v [dict get $r -content] {
	    set v [my fetch $v]
	    set c [my tuConvert $v tuple/html]
	    Debug.tupler {List to Html: converted $v to ($c)}
	    append result [<li> id T_[dict get $v id] $c] \n
	}
	if {$result ne ""} {
	    set result [<ul> \n$result]\n
	}
	return [Http Ok $r $result tuple/html]
    }
}

Dict+Head {
    type Conversion
    content {
	Debug.tupler {Dict to Head conversion: [dict size $r] ($r)}
	set result {}
	dict for {n v} [dict get $r -content] {
	    set v [my fetch $v]
	    if {[dict get $v type] eq "ref"} {
		# rename refs so their dict-name is their reference
		set n [lindex [dict get $v content] 0]
	    }
	    if {[info exists $result $n]} continue
	    dict set result $n [my tuConvert $v tuple/head]
	}
	#Debug.tupler {dict conversion: ([dict get $r -content]) -> ($result)}
	dict set r -tuple mime "Tcl Dict"
	return [Http Pass $r $result tuple/head]
    }
}

Dict+Html {
    type Conversion
    content {
	Debug.tupler {Dict to Html conversion: [dict size $r] ($r)}
	# we prefer a tabular form, but could use dl instead
	set result {}
	set content 
	dict for {n v} [dict get $r -content] {
	    if {[dict exists $result $n]} continue
	    set v [my fetch $v]
	    set sub [my tuConvert $v tuple/html]
	    lappend result [<tr> "[<th> [armour $n]] [<td> [armour $sub]]"]
	}
	set result [<table> class sortable border 2 [join $result \n]]
	#Debug.tupler {dict conversion: ([dict get $r -content]) -> ($result)}
	return [Http Pass $r $result tuple/html]
    }
}

"Tcl Variable" {
    type Type
    content {
	# evaluate tuple of "Tcl Script" as the result variable resolution
	set mime [my getmime [dict get? $r -tuple]]

	set result [set [dict get $r -content]]
	Debug.tupler {Tcl Variable '$result' of type '$mime'}
	return [Http Ok $r $result $mime]
    }
}

"Tcl Dict" {
    type Type
    content {
	# do some form checking on the dict
	if {[catch {dict size [dict get? $r -content]} e eo]} {
	    return [Http Ok $r [subst {
		[<h2> "Type error"]
		[<p> "'[armour [dict get $r -tuple name]]' is of Type 'Tcl Dict', however its content is not a properly-formed dictionary."]
		[<p> "Dictionaries are tcl lists with an even number of elements."]
		[<h2> Content:]
		[<pre> [armour [dict get? $r -content]]]
	    }] tuple/html]
	} else {
	    return [Http Pass $r]
	}
    }
}

"Tcl Dict+Head" {
    type Conversion
    content {
	Debug.tupler {Tcl Dict to Head conversion: [dict size $r] ($r)}
	set result {}
	set content [dict get $r -content]
	dict for {n v} $content {
	    lappend result [<tr> "[<th> [armour $n]] [<td> [armour $v]]"]
	}
	set result [<table> class sortable border 2 [join $result \n]]
	#Debug.tupler {dict conversion: ([dict get $r -content]) -> ($result)}
	return [Http Pass $r $result tuple/html]
    }
}

"Tcl Dict+Html" {
    type Conversion
    content {
	Debug.tupler {Tcl Dict to Html conversion: [dict size $r] ($r)}
	# we prefer a tabular form, but could use dl instead
	set result {}
	set content [dict get $r -content]
	dict for {n v} $content {
	    lappend result [<tr> "[<th> [armour $n]] [<td> [armour $v]]"]
	}
	set result [<table> class sortable border 2 [join $result \n]]
	#Debug.tupler {dict conversion: ([dict get $r -content]) -> ($result)}
	return [Http Pass $r $result tuple/html]
    }
}

Text {
    type Type
}

Text+Html {
    type Conversion
    content {
	return [Http Ok $r [<pre> [dict get $r -content]] tuple/html]
    }
}

"example text" {
    type Text
    content "this is text/plain"
}

Uppercase+Text {
    type Conversion
    content {
	return [Http Pass $r [dict get $r -content] tuple/text]
    }
}

# Uppercase type - shows transformations - any text is uppercased
Uppercase {
    type Type
    content {
	# this is called each time an Uppercase type tuple is processed
	# for return to a client
	return [Http Pass $r [string toupper [dict get $r -content]]]
    }
}

"Example Uppercase" {
    type Uppercase
    content "this is uppercase"
}

"Example Uppercase2" {
    mime Uppercase
    content "this is uppercase"
}

Tests {
    type Template
    content {
	[<h3> "Tests"]
	[<p> "Here are some tests of Tupler functionality"]
	[Html ulinks {
	    "Creole Test" {Tests+Creole}
	    "Tcl Scripting and component architecture" now
	    "Test component assembly" {Tests+Component}
	    "Test Tcl Variable and Tcl Dict rendering" reflect
	    "Test Uppercase and text/plain" {{Example Uppercase}}
	    "Test 'page not found' page" nothere
	    "XRay of Now page" xray/now
	    "Glob Test" {{Tests+Glob}}
	}]
    }
}

now {
    type Template
    content {
	[<h1> Now]
	[<p> "[clock format [clock seconds]] is the time"]
	[<p> "This page is generated from a Tcl Script, and assembled from components for [<a> href xray/now+style style] (which makes the header red) and [<a> href xray/now+title title] (which gives the page a title.)"]
	[<p> "The page itself is described using Tcl commands which generate HTML."]
	[<p> "This (or any) page may be edited with [<a> href +*edit +*edit]"]
	[<p> "The following is a transclusion of +*edit using the &lt;inc&gt; pseudo-tag:"]
	[<inc> +*edit]
	[<p> "Note that the transclusion does not bring with it any scripts or stylesheets"]
    }
}

now+title {
    type Text
    content "A Demo Title"
}

now+style {
    type css
    content {
	h1 {color:red;}
    }
}

reflect {
    type "Tcl Variable"
    mime "Tcl Dict"
    content r
}

"Reflect Text" {
    type "Tcl Variable"
    mime Text
    content r
}

"Dict err" {
    type "Tcl Dict"
    content {this is not a properly formed dict}
}

"Tests+Glob" {
    type Glob
    mime text
    content {
	now+*
    }
}

Creole+Html {
    type Conversion
    content {
	set tuple [dict get $r -tuple]

	Debug.tupler {Creole+Html converting [dict merge $tuple [list content ...elided...]]}

	set r [jQ jquery $r]	;# critical that we load jquery first
	set r [jQ script $r creole.js]	;# load creole conversion js
	set r [Html script $r js/js]	;# then the local js
 
	# run Creole post-processing on the loaded content
	set r [Html postscript $r {
	    $(document).Tuple();
	}]

	set r [jQ editable $r #T_[dict get $tuple id] 'saveJE/' loadurl '[dict get $tuple name].PT' type 'textarea' name 'content']	;# also load editable

	set mime [my getmime $tuple]
	if {$mime ni {tuple/html tuple/text}} {
	    Debug.tupler {Creole+Html convert from $mime ($tuple)}
	    set content [my tuConvert $tuple tuple/html $mime]
	} else {
	    set content [dict get $r -content]
	}
	Debug.tupler {Creole+Html converted from $mime ($content)}
 
	return [Http Ok $r [<div> class creole $content] tuple/html]
    }
}

Tests+Creole {
    type Creole
    content {
	[[WikiCreole:Creole1.0|{{http://www.wikicreole.org/attach/LeftMenu/viki.png|Creole 1.0}}]]\\
	    What you see is a **live** demonstration of [[WikiCreole:Creole1.0|Creole 1.0]] parser, written entirely in [[Wikipedia:JavaScript|JavaScript]]. Creole is a wiki markup language, intended to be a cross standard for various wiki markup dialects.

	[[http://www.ivan.fomichev.name/2008/04/javascript-creole-10-wiki-markup-parser.html | Ivan Fomichev]]'s parser is used to render Creole in-client.

	See [[WikiCreole:CheatSheet|Creole 1.0 Cheat Sheet]] for editing tips.

	The following is a local transclusion from Creole:

	{{+*edit}}
    }
}

Tests+Component {
    type Creole
    content {
	This is a test of Component assembly.

	The [[+header|page header]] and [[+footer|page footer]] are components of this page.

	Components are like server-side inclusion.  Components can drag in js and css.

	The layout of this page would be improved by a bit of judicious padding in [[*rform+style]]

	The layout could also be specialised to just pages of this type.
    }
}

"Creole+header" {
    # this header applies to all creole tuples
    type Creole
    mime Template
    content {
	== [string totitle $_left]
    }
}

"Creole+footer" {
    # this footer applies to all creole tuples
    type Creole
    mime Template
    content {
	----
	\[\[. | Tupler\]\] //(generated [clock format [clock seconds]])//
    }
}

"Tests+Component+nav" {
    type Creole
    content {
	This is a 'nav' component

	It floats to the left

	One would usually populate it with links
    }
}

"Tests+Component+aside" {
    type Creole
    content {
	This is the 'aside' component
	
	It floats to the right
    }
}

Welcome {
    type Creole
    content {
	Tupler is a Tcl content management system based on [[http://wagn.org | Wagn]] using [[http:/wub/ | Wub]]'s powerful content-negotiation module.

	It overlays a [[http://wiki.tcl.tk/tdbc | TDBC]] database with Wagn's naming scheme and a [[Type Scheme]], allowing you to compose pages from html5-like components, jQuery javascript components and CSS styling components.

	Anything in Tupler can be represented as a Tcl script, which generates page content.  This will be performed in a [[http://wiki.tcl.tk/Safe Interps | Tcl Safe Interpreter]] for pretty-good site security.

	It provides a sophisticated but simple [[Match Language]] which permits arbitrary SQL queries over the database.  It also provides simpler [[Glob Name]] and [[Regexp Name]] matches

	{{Tests}}
    }
}
