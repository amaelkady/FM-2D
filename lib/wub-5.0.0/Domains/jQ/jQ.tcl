package require Html

package require Debug
Debug define jq 10

package provide jQ 1.0
package provide JQ 1.0
package require File

set ::API(Domains/JQ) {
    {
	jQ domain provides a tight integration to the jQuery web framework.  It enables the application to load jQuery plugins and modules (such as the jQuery UI module) in a convenient manner.

	jQ provides an interface to jQuery and the plugins which ensures that dependencies are loaded, and invokes the plugin with an appropriate element selector and arguments.  jQ also provides some support for emitting javascript into an HTML page.

	== Supported Plugins ==

	General form of Plugin interfaces is [[jQ ''plugin'' selector args]] where ''selector'' is a jQuery selector expression, and args will be passed to the main entry point of the plugin.

	;[http://garage.pimentech.net/scripts_doc_jquery_jframe/ jframe]: jFrame provides an easy way to get an HTML frame-like behaviour on DIV Elements with AJAX.
	;[http://jtemplates.tpython.com/ jtemplates]: a template engine for JavaScript.
	;[http://stilbuero.de/jquery/history/ history]: plugin for enabling history support and bookmarking
	;<ready>:
	;[http://docs.jquery.com/UI/Datepicker datepicker]: configurable plugin that adds datepicker functionality
	;[http://keith-wood.name/timeEntryRef.html timeentry]: sets an input field up to accept a time value
	;[http://remysharp.com/2007/01/25/jquery-tutorial-text-box-hints/ hint]: Show a 'hint' inside the input box when it is not in focus
	;[http://www.stainlessvision.com/collapsible-box-jquery boxtoggle]: takes a container and hides all of it's content apart from the heading
	;[http://tablesorter.com/ tablesorter]: Flexible client-side table sorting
	;[http://www.fyneworks.com/jquery/multiple-file-upload/ multifile]: non-obstrusive plugin that helps users easily select multiple files for upload quickly and easily
	;[http://plugins.jquery.com/project/mbContainerPlus containers]: full featured and fully skinnable containers.
	;container: format up a container for the mbContainerPlus plugin
	;[http://docs.jquery.com/UI/Tabs tabs]: 
	;addtab:
	;gentab:
	;[http://docs.jquery.com/UI/Accordion accordion]: Accordion widget
	;dict2accordion:
	;[http://docs.jquery.com/UI/Resizeables resizable]: 
	;[http://docs.jquery.com/UI/Draggables draggable]: 
	;[http://docs.jquery.com/UI/Droppables droppable]: 
	;[http://docs.jquery.com/UI/Sortables sortable]: 
	;[http://docs.jquery.com/UI/Selectables selectable]: 
	;[http://www.aclevercookie.com/facebook-like-auto-growing-textarea/ autogrow]: autogrowing text area
	;[http://jquery.autoscale.js.googlepages.com/ autoscale]: Scale an element to browser window size
	;[http://bassistance.de/jquery-plugins/jquery-plugin-tooltip/ tooltip]: Display a customized tooltip instead of the default one for every selected element.
	;[http://plugins.jquery.com/project/HoverImageText hoverimage]: create images along with descriptive text that is displayed on mouse over, similar to a tool hip, however the text is overlayed over the image.
	;[http://monc.se/kitchen galleria]: image gallery
	;[http://benjaminsterling.com/jquery-jqgalview-photo-gallery/ gallery]: another image gallery
	;[http://www.appelsiini.net/projects/jeditable editable]: in-place editing
	;[http://malsup.com/jquery/form/ form]: easily and unobtrusively upgrade HTML forms to use AJAX - numerous options which allows you to have full control over how the data is submitted.
	;[http://bassistance.de/jquery-plugins/jquery-plugin-validation/ validate]: form validation
	;[http://plugins.jquery.com/project/Autofill autofill]: auto-fill a form
	;[http://nadiaspot.com/jquery/confirm confirm]: displays a confirmation message in place before doing an action.
	;[http://reconstrukt.com/ingrid/ ingrid]: unobtrusively add datagrid behaviors (column resizing, paging, sorting, row and column styling, and more) to tables.
	;[http://code.google.com/p/jmaps/ map]: API to create and manage multiple google maps on any page. 

	== General API ==
	jQ package exports functions to load and invoke jQ plugins

	== Examples ==
	The following assume that the response ''r'' contains x-text/html-fragment style html

	=== Example: arbitrary javascript over jQuery ===
	
	set r [jQ jquery $r]	;# load the jquery library
	set r [Html postscript $r {/* this is javascript */}]
	
	=== Example: ajax form ===

	# apply form plugin to ''formid''
	set r [[jQ form $r "#formid" target \"#divid\"]]
	
	# emit a form with the id ''formid'' and a div with the id ''divid''
	# the returned result of submitting ''formid'' will replace the content of ''divid''
	return [Http Ok $r "[<form> formid {...}] [<div> divid {...}]" x-text/html-fragment]
    }
    expires {when do these javascript files expire?}
    google {use the google versions of jQuery wherever possible}
}

namespace eval ::jQ {
    variable root [file dirname [file normalize [info script]]]
    variable mount /jquery/
    variable expires "next week"
    variable google 0

    variable version 1.4.2
    variable uiversion 1.8.2
    variable min 1

    proc script {r script args} {
	variable version; variable min
	if {$script eq "jquery.js"} {
	    # get the currently supported jquery
	    set script jquery-${version}[expr {$min?".min":""}].js
	}

	variable uiversion
	if {$script eq "jquery.ui.js"} {
	    # get the currently supported jquery UI
	    set script jquery-ui-${uiversion}[expr {$min?".min":""}].js
	}

	variable mount
	return [Html script $r [join [list $mount scripts $script] /] {*}$args]
    }

    # generate a DOM ready function
    proc ::<ready> {args} {
	if {[llength $args]%2} {
	    set script [lindex $args end]
	    set args [lrange $args 0 end-1]
	} else {
	    set script ""
	}

	return [<script> [string map [list %F [string map $args $script] ] {
	    $(function() {
		%F
	    });
	}]]
    }

    # arrange for the function in args to be run post-load
    proc ready {r args} {
	if {[llength $args]%2} {
	    set script [lindex $args end]
	    set args [lrange $args 0 end-1]
	    set script [string map [list %F [string map $args $script] ] {
		$(function() {
		    %F
		});
	    }]
	    return [Html postscript $r $script]
	}
    }

    proc scripts {r args} {
	Debug.jq {scripts: $args}

	variable version
	variable google
	if {$google} {
	    # use the google AJAX repository to fetch our jquery version
	    set r [Html script $r http://www.google.com/jsapi]
	    set r [Html script $r !google "google.load('jquery', '$version');"]
	}

	# load each specified script
	variable mount
	foreach script $args {
	    variable min
	    switch -- $script {
		jquery.js {
		    if {$google} continue	;# needn't load jquery.js again
		    # get the currently supported jquery
		    set script jquery-${version}[expr {$min?".min":""}].js
		}
		jquery.ui.js {
		    # get the currently supported jquery UI
		    variable uiversion
		    set script jquery-ui-${uiversion}[expr {$min?".min":""}].js
		}
	    }

	    # record requirement for script
	    set r [Html script $r [join [list $mount scripts $script] /]]
	}
	Debug.jq {SCRIPT: [dict get $r -script]}
	return $r
    }

    proc theme {r theme} {
	variable mount; variable root
	if {[file exists [file join $root themes $theme jquery.ui.all.css]]} {
	    return [Html style $r [join [list $mount themes $theme jquery.ui.all.css] /]]
	} elseif {[file exists [file join $root themes $theme ui.all.css]]} {
	    return [Html style $r [join [list $mount themes $theme ui.all.css] /]]
	} else {
	    return $r
	}
    }

    proc style {r style args} {
	variable mount
	return [Html style $r [join [list $mount css $style] /] $args]
    }

    variable defaults {
	editable {
	    indicator {'<img src="/icons/indicator.gif">'}
	    type 'textarea'
	    select false
	    autogrow {{lineHeight:16, minHeight:32}}
	    submit 'OK'
	    cancel 'cancel'
	    onblur 'cancel'
	    cssclass 'autogrow'
	    event 'dblclick'
	    tooltip {'Double click to edit'}
	    style 'inherit'
	}

	autogrow {
	    maxHeight 1000
	    minHeight 100
	}
	galleria {
	    history true
	    clickNext true
	}

	map {
	    center [0,0]
	    mapType 'hybrid'
	}

	galleria1 {
	    history false
	    clickNext false
	    insert undefined
	    onImage {
		function() { $('.nav').css('display','block'); }
	    }
	}
	containers {
	}
	container {
	    buttons 'm'
	    skin 'default'
	    aspectRatio false
	    handles 'n,s,e,w'
	}
	datatables {
	    sPaginationType 'full_numbers'
	    sDom 'tr<"bottom"pifl<"clear">'
	}
	track {
	    changeListVisible false
	}
	rte {
	    media_url '/icons/'
	    content_css_url 'rte.css'
	}
	stickynotes {
	    size 'large'
	}
    }

    proc opts {args} {
	set type ""
	if {[llength $args]%2} {
	    set args [lassign $args type]
	}

	set opts {}
	variable defaults
	if {$type ne "" && [dict exists $defaults $type]} {
	    set args [list {*}[dict get $defaults $type] {*}$args]
	}
	dict for {n v} $args {
	    if {$v eq ""} {
		set v "''"	;# ensure we don't send naked names
	    }
	    lappend opts "$n:$v"
	}
	if {$opts eq ""} {
	    return ""
	} else {
	    return "\{[join $opts ,]\}"
	}
    }

    # just load the jquery module
    proc jquery {r} {
	return [jQ script $r jquery.js]
    }

    # http://garage.pimentech.net/scripts_doc_jquery_jframe/
    # <a href="javascript:$('#target1').loadJFrame('url1')">click here</a>
    # or place a src attribute in your target <div>
    proc jframe {r} {
	return [scripts $r jquery.js jquery.form.js jquery.jframe.js]
    }

    # http://jtemplates.tpython.com/
    proc jtemplates {r selector args} {
	return [scripts $r jquery.js jquery-jtemplates.js]
    }

    # http://johannburkard.de/blog/programming/javascript/inc-a-super-tiny-client-side-include-javascript-jquery-plugin.html
    proc inc {r} {
	return [scripts $r jquery.js jquery.inc.js]
    }

    proc tc {url {transform ""} {post ""}} {
	lappend url [string map {" " @ \n @ \t @} $transform]
	lappend url [string map {" " @ \n @ \t @} $post]
	
	return [list class inc:[string trim [join $url "#"] "#"]]
    }

    proc history {r args} {
	set r [scripts $r jquery.js jquery.history-remote.js]
	return [ready $r {
		$.ajaxHistory.initialize();
	}]
    }

    # combine a selector/initializer and set of script
    # dependencies to call a jQ package.
    # relies upon preload and postload capabilities of
    # conversion scripts to ensure code is initialized in the correct
    # order, as a postload.
    # relies upon the script and css capabilities to ensure packages
    # are loaded correctly
    # scripts - a list of scripts upon which this depends
    # args - a series of argument/value pairs followed by the script
    proc weave {r scripts args} {
	#puts stderr "WEAVE: $r"
	set r [scripts $r {*}$scripts]	;# preload scripts first

	# generate the document-ready script with %var substitution
	if {[llength $args]%2} {
	    set script [lindex $args end]
	    set args [lrange $args 0 end-1]
	    set script [string map [dict filter $args key %*] $script]
	} else {
	    set script ""
	}

	# %prescript is a function to run before the script
	set js [dict get? $args %prescript]\n

	# append the script to the relevant loader request element
	# allow different loaders to process script
	if {$js ne "" || $script ne ""} {
	    append js "\$(function()\{\n${script}\n\});"
	    Debug.jq {WEAVE: $script}
	    switch -- [dict get? $args loader] {
		google {
		    # the script needs google loader
		    dict lappend r -google $script
		}
		"" {
		    # run this script in -script phase
		    set r [Html postscript $r $js]
		}

		default {
		    # use specified loader to load this script
		    dict lappend r [dict get $args loader] $js
		}
	    }
	}

	# record the style
	if {[dict exists $args css]} {
	    set r [style $r {*}[dict get $args css]]
	}

	#puts stderr "POST WEAVE: $r"
	return $r
    }
 
    proc S {name} {
	if {[string match #* $name]} {
	    return [string map {. \\\\.} $name]
	} else {
	    return $name
	}
    }
    
    # http://docs.jquery.com/UI/Datepicker
    proc datepicker {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js
	} %SEL [S $selector] %OPTS [opts datepicker {*}$args] {
	    $('%SEL').datepicker(%OPTS);
	}]
    }

    # http://keith-wood.name/timeEntryRef.html
    proc timeentry {r selector args} {
	return [weave $r {
	    jquery.js jquery.timeentry.js
	}  css jquery.timeentry.css %SEL [S $selector] %OPTS [opts timeentry {*}$args] {
	    $('%SEL').timeEntry(%OPTS);
	}]
    }

    # http://remysharp.com/2007/01/25/jquery-tutorial-text-box-hints/
    proc hint {r {selector input[title!=""]} args} {
	return [weave $r {
	    jquery.js jquery.hint.js
	}  %SEL [S $selector] %OPTS [opts hint {*}$args] {
	    $('%SEL').hint(%OPTS);
	}]
    }

    # http://www.stainlessvision.com/collapsible-box-jquery
    proc boxtoggle {r selector args} {
	return [weave $r {
	    jquery.js jquery.boxtoggle.js
	}  %SEL [S $selector] %OPTS [opts boxtoggle {*}$args] {
	    boxToggle('%SEL');
	}]
    }

    # http://tablesorter.com/addons/pager/jquery.tablesorter.pager.js
    proc tablesorter {r selector args} {
	return [weave $r {
	    jquery.js jquery.metadata.js jquery.tablesorter.js
	} css jquery.tablesorter.css %SEL [S $selector] %OPTS [opts tablesorter {*}$args] {
	    $('%SEL').tablesorter(%OPTS);
	}]
    }

    # http://www.fyneworks.com/jquery/multiple-file-upload/
    proc multifile {r args} {
	if {[llength $args]} {
	    set args [lassign $args selector]
	    return [weave $r {
		jquery.js jquery.MultiFile.js
	    }  %SEL [S $selector] %OPTS [opts multifile {*}$args] {
		$('%SEL').MultiFile(%OPTS);
	    }]
	} else {
	    # just supports the simple case
	    return [scripts $r jquery.js jquery.MultiFile.js]
	}
    }

    # http://plugins.jquery.com/project/mbContainerPlus
    proc containers {r selector args} {
	set r [style $r mbContainer.css]	;# ensure the css is loaded

	variable mount
	if {![dict exists $args elementsPath]} {
	    dict set args elementsPath '[join [list $mount elements] /]/'
	}
	dict set args containment 'document'

	return [weave $r {
	    jquery.js jquery.ui.js jquery.metadata.js jquery.container.js
	} %SEL [S $selector] %OPTS [opts containers {*}$args] {
	    $('%SEL').buildContainers(%OPTS);
	}]
    }

    # format up a container for the mbContainerPlus plugin
    proc container {args} {
	# grab content (if any)
	if {[llength $args]%2} {
	    set ct [lindex $args end]
	    set args [lrange $args 0 end-1]
	} else {
	    set ct ""
	}

	# grab some significant parameters
	foreach v {style class id cid} {
	    # attribute supplied?
	    if {[dict exists $args $v]} {
		set $v [list $v [dict get $args $v]]
		dict unset args $v
	    } else {
		set $v {}
	    }
	}

	# assemble the classes
	set class [lindex $class end]	;# remove the prefix
	lappend class containerPlus

	foreach sc {draggable resizable} {
	    if {[dict exists $args $sc]} {
		if {[dict get $args $sc]} {
		    lappend class $sc
		}
		dict unset args $sc
	    }
	}

	# set up the funky <div> structure this thing needs
	set footer ""; set title ""; set header ""
	dict with args {
	    set C [<div> class no [subst {
		[<div> class ne [<div> class n "$title $header"]]
		[<div> class o [<div> class e [<div> class c [<div> class content $ct]]]]
		[<div> class bl [<div> class so [<div> class se [<div> class s $footer]]]]
	    }]]
	    unset header
	    unset footer
	    unset title
	}

	# assemble options in a metadata class element
	# skin, collapsed, iconized, icon, buttons, content, aspectRatio
	# handles, width, height, 
	set opts [string map {' \"} [opts container {*}$args]]
	if {$opts ne ""} {
	    set opts [list class $opts]
	}

	set result [<div> {*}$cid class $class {*}$opts {*}$style $C\n]
	return $result
    }

    # http://docs.jquery.com/UI/Tabs
    proc tabs {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js
	} %SEL [S $selector] %OPTS [opts tabs {*}$args] {
	    $('%SEL').tabs(%OPTS);
	}]
    }

    proc addtab {var name content} {
	upvar 1 $var page
	set id "FT[llength [dict get? $page _]]"
	dict set page $id $content
	dict set page _ $id $name
    }

    proc gentab {r tabid var args} {
	upvar 1 $var page
	set r [tabs $r "#$tabid > ul" {*}$args]

	set index ""
	dict for {id name} [dict get $page _] {
	    append index [<li> [<a> href "#$id" [<span> $name]]] \n
	}
	dict unset page _

	set tabs ""
	dict for {id content} $page {
	    append tabs [<div> id $id \n$content] \n
	}

	dict append r -content [<div> id $tabid class fflora "\n[<ul> \n$index]\n$tabs\n"]

	return $r
    }

    proc dict2accordion {dict args} {
	set result {}
	foreach {n v} $dict {
	    set n [armour $n]
	    lappend result [<div> "[<a> href #$n $n]\n[<div> $v]"]
	}
	return [<div> {*}$args [join $result \n]]
    }

    # http://docs.jquery.com/UI/Accordion
    proc accordion {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js
	} %SEL [S $selector] %OPTS [opts accordion {*}$args] {
	    $('%SEL').accordion(%OPTS);
	}]
    }

    # http://docs.jquery.com/UI/Resizeables
    proc resizable {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js
	} %SEL [S $selector] %OPTS [opts resizable {*}$args] {
	    $('%SEL').resizable(%OPTS);
	}]
    }

    # http://docs.jquery.com/UI/Draggables
    proc draggable {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js
	} %SEL [S $selector] %OPTS [opts draggable {*}$args] {
	    $('%SEL').draggable(%OPTS);
	}]
    }

    # http://docs.jquery.com/UI/Droppables
    proc droppable {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js
	} %SEL [S $selector] %OPTS [opts droppable {*}$args] {
	    $('%SEL').droppable(%OPTS);
	}]
    }

    # http://docs.jquery.com/UI/Sortables
    proc sortable {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js
	} %SEL [S $selector] %OPTS [opts sortable {*}$args] {
	    $('%SEL').sortable(%OPTS);
	}]
    }

    # http://sprymedia.co.uk/article/DataTables
    proc datatable {r selector args} {
	return [weave $r {
	    jquery.js jquery.dataTables.js
	} %SEL [S $selector] %OPTS [opts datatables {*}$args] {
	    $('%SEL').dataTable(%OPTS);
	}]
    }

    # http://nicedit.com/
    proc nicedit {r selector args} {
	return [weave $r {
	    jquery.js jquery.nicedit.js
	} %SEL [S $selector] %OPTS [opts rte {*}$args] {
	    new nicEditor({fullPanel : true}).panelInstance(%SEL);
	}]

	# area2 = new nicEditor({fullPanel : true}).panelInstance('myArea2');
	# area2.removeInstance('myArea2');
    }

    # http://docs.jquery.com/UI/Selectables
    proc selectable {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js
	} %SEL [S $selector] %OPTS [opts selectable {*}$args] {
	    $('%SEL').selectable(%OPTS);
	}]
    }

    # http://www.aclevercookie.com/facebook-like-auto-growing-textarea/
    proc autogrow {r selector args} {
	return [weave $r {jquery.js jquery.autogrow.js
	} %SEL [S $selector] %OPTS [opts autogrow {*}$args] {
	    $('%SEL').autogrow(%OPTS);
	}]
    }

    # http://jquery.autoscale.js.googlepages.com/
    proc autoscale {r selector args} {
	return [weave $r {jquery.js jquery.autoscale.js
	} %SEL [S $selector] %OPTS [opts autoscale {*}$args] {
	    $('%SEL').autoscale(%OPTS);
	}]
    }

    # http://bassistance.de/jquery-plugins/jquery-plugin-tooltip/
    proc tooltip {r selector args} {
	return [weave $r {
	    jquery.js jquery.dimensions.js
	    jquery.tooltip.js
	} %SEL [S $selector] %OPTS [opts tooltip {*}$args] {
	    $('%SEL').Tooltip(%OPTS);
	}]
    }

    # http://plugins.jquery.com/project/HoverImageText
    proc hoverimage {r selector args} {
	return [weave $r {
	    jquery.js jquery.hoverimagetext.js
	} %SEL [S $selector] %OPTS [opts hoverimage {*}$args] {
	    $('%SEL').HoverImageText(%OPTS);
	}]
    }

    proc galleria {r selector args} {
	return [weave $r {
	    jquery.js jquery.galleria.js
	} %SEL [S $selector] %OPTS [opts galleria {*}$args] {
	    $('ul.%SEL').galleria(%OPTS)
	}]
    }

    # http://benjaminsterling.com/jquery-jqgalview-photo-gallery/
    proc gallery {r selector args} {
	return [weave $r {
	    jquery.js jquery.galview.js
	} %SEL [S $selector] %OPTS [opts gallery {*}$args] {
	    $('%SEL').jqGalView(%OPTS);
	}]
    }

    proc aaccordion {r selector args} {
	return [weave $r {
	    jquery.js jquery.accordion.js
	} %SEL [S $selector] %OPTS [opts aaccordion {*}$args] {
	    $('%SEL').Accordion(%OPTS);
	}]
    }

    # http://github.com/janv/rest_in_place/tree/master
    proc rest_in_place {r} {
	set r [scripts $r jquery.js jquery.rest_in_place.js]
	return $r
    }

    proc editable {r selector fn args} {
	if {[dict exists $args %prescript]} {
	    set pre [list %prescript [dict get $args %prescript]]
	    dict unset args %prescript
	} else {
	    set pre ""
	}

	return [weave $r {
	    jquery.js jquery.autogrow.js jquery.jeditable.js
	} %SEL [S $selector] %OPTS [opts editable {*}$args] {*}$pre %FN $fn {
	    $('%SEL').editable(%FN,%OPTS);
	}]
    }

    # http://malsup.com/jquery/form/
    proc form {r selector args} {
	return [weave $r {
	    jquery.js jquery.form.js
	} %SEL [S $selector] %OPTS [opts form {*}$args] {
	    $('%SEL').ajaxForm(%OPTS);
	}]
    }

    # http://code.google.com/p/jglycy/
    proc jiggle {r} {
	return [jQ script $r jquery.jglycy.js]
    }

    # http://code.zhandwa.com/jquery/
    proc track {r selector args} {
	return [weave $r {
	    jquery.js jquery.track.js
	} %SEL [S $selector] %OPTS [opts form {*}$args] {
	    $('%SEL').trackChanges(%OPTS);
	}]

	#var oldvals3 = $('#form3').trackChanges({
	#    changeListName: "form3List",  // changed field names will be in this list (if not given, defaults to {formname}TrackList)
	#    events: "change blur keypress keydown click",  // events on which the tracking should occur
	#    changeListVisible: true, // should the change list be visible
	#    changeListClass: "custom" // css class applied to the change list
	#});
    }

    # http://code.google.com/p/jquery-form-observe/
    proc observer {r selector args} {
	return [weave $r {
	    jquery.js jquery.formobserver.js
	} %SEL [S $selector] %OPTS [opts formobserver {*}$args] {
	    $('%SEL').FormObserve(%OPTS);
	}]
	# $('#MyForm').submit(function(){
	# if(validation=='ok'){
	# $(this).FormObserve_save();
	#}
	#});
    }

    # http://bassistance.de/jquery-plugins/jquery-plugin-validation/
    proc validate {r selector args} {
	return [weave $r {
	    jquery.js jquery.delegate.js
	    jquery.maskedinput.js jquery.metadata.js
	    jquery.validate.js jquery.validate-ext.js
	} %SEL [S $selector] %OPTS [opts validate {*}$args] {
	    $('%SEL').validate(%OPTS);
	}]
    }

    proc autofill {r selector args} {
	return [weave $r {
	    jquery.js jquery.autofill.js
	} %SEL [S $selector] %OPTS [opts autofill {*}$args] {
	    $('%SEL').autofill(%OPTS);
	}]
    }

    proc confirm {r selector args} {
	return [weave $r {
	    jquery.js jquery.confirm.js
	} %SEL [S $selector] %OPTS [opts confirm {*}$args] {
	    $('%SEL').confirm(%OPTS);
	}]
    }

    proc ingrid {r selector args} {
	return [weave $r {
	    jquery.js jquery.ingrid.js
	} css ingrid.css %SEL [S $selector] %OPTS [opts ingrid {*}$args] {
	    $('%SEL').ingrid(%OPTS);
	}]
    }

    proc map {r selector callback args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}

	if {[dict exists $args key]} {
	    # load the google maps API if we're given a key
	    set r [Html script $r "http://maps.google.com/maps?file=api&v=2&key=[dict get $args key]"]
	    dict unset args key
	}

	return [weave $r {
	    jquery.js jquery.jmaps.js
	} %SEL [S $selector] %OPTS [opts map {*}$args] %CALL $callback {
	    $('%SEL').jmap('init', %OPTS, %CALL);
	}]
    }

    proc pnotify {r} {
	return [weave $r {
	    jquery.js jquery.ui.js jquery.pnotify.js
	} css jquery.pnotify.css]
    }

    proc popup {args} {
	# title: false, The notice's title.
	# text: false, The notice's text.
	# addclass: "", Additional classes to be added to the notice. (For custom styling.)
	# nonblock: false, Create a non-blocking notice. It lets the user click elements underneath it.
	# nonblock_opacity: .2, The opacity of the notice (if it's non-blocking) when the mouse is over it.
	# history: true, Display a pull down menu to redisplay previous notices, and place the notice in the history.
	# width: "300px", Width of the notice.
	# min_height: "16px", Minimum height of the notice. It will expand to fit content.
	# type: "notice", Type of the notice. "notice" or "error".
	# notice_icon: "ui-icon ui-icon-info", The icon class to use if type is notice.
	# error_icon: "ui-icon ui-icon-alert", The icon class to use if type is error.
	# animation: "fade", The animation to use when displaying and hiding the notice. "none", "show", "fade", and "slide" are built in to jQuery. Others require jQuery UI. Use an object with effect_in and effect_out to use different effects.
	# animate_speed: "slow", Speed at which the notice animates in and out. "slow", "def" or "normal", "fast" or number of milliseconds.
	# opacity: 1, Opacity of the notice.
	# shadow: false, Display a drop shadow.
	# closer: true, Provide a button for the user to manually close the notice.
	# hide: true, After a delay, remove the notice.
	# delay: 8000, Delay in milliseconds before the notice is removed.
	# mouse_reset: true, Reset the hide timer if the mouse moves over the notice.
	# remove: true, Remove the notice's elements from the DOM after it is removed.
	# insert_brs: true, Change new lines to br tags.
	# stack: {"dir1": "down", "dir2": "left", "push": "bottom"}, The stack on which the notices will be placed. Also controls the direction the notices stack.

	if {[llength $args]%2} {
	    set text [lindex $args end]
	    set args [lrange $args 0 end-1]
	    dict set args text $text
	}

	set opts {}
	dict for {n v} $args {
	    dict set opts pnotify_$n '$v'
	}

	return "\$.pnotify([jQ opts pnotify {*}$opts]);"
    }

    # http://tympanus.net/codrops/2009/10/30/jstickynote-a-jquery-plugin-for-creating-sticky-notes/
    # http://www.jquery-sticky-notes.com/
    proc stickynote {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js jquery.stickynote.js
	} css stickynote.css %SEL [S $selector] %OPTS [opts stickynotes {*}$args] {
	    $('%SEL').stickyNotes(%OPTS);
	}]
    }

    proc sheet {r selector args} {
	return [weave $r {
	    jquery.js jquery.sheet.calc.js jquery.sheet.js
	} css jquery.sheet.css %SEL [S $selector] %OPTS [opts sheet {*}$args] {
	    $('%SEL').sheet(%OPTS);
	}]
    }

    # comet - server side push
    proc comet {r url args} {
	set url '[string trim $url ']'
	set opts [opts datepicker {*}$args]
	if {$opts eq ""} {
	    set opts "{}"
	}
	return [weave $r {
	    jquery.js
	} %URL $url %OPTS $opts {
	    jQuery.comet = {
		fetching: false,
		url: %URL,

		timeout: 60000,
		wait: 10000,
		onError: null,
		type: 'GET',
		dataType: "script",
		async: true,
		cache: false,
		ifModified: false,

		success: function(xhr, status, error) {
		    this.fetching = false;
		    //alert("success");
		    this.fetch();	// got result - refetch
		},
		
		error: function (xhr, status, error) {
		    this.fetching = false;
		    if (status == 'timeout') {
			//alert("timeout");
			this.fetch();	// on timeout - refetch
		    } else if (status == 'timeout') {
			//alert("notmodified");
			this.fetch();	// on timeout - refetch
		    } else {
			if (this.onError != null) {
			    this.onError(xhr, status, error);
			}
			// on error, wait then refetch
			//alert("ajax fail:"+status);
			setTimeout(this.fetch, this.wait);
		    }
		},
		
		fetch: function() {
		    if (!this.fetching) {
			this.fetching = true;
			$.ajax(this);
		    }
		}
	    };
	    jQuery.comet = jQuery.extend(jQuery.comet, %OPTS);
	    $.comet.fetch();	// start fetching
	}]
    }

    proc slider {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js
	} %SEL [S $selector] %OPTS [opts slider {*}$args] {
	    $('%SEL').slider(%OPTS);
	}]
    }

    proc combobox {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js jquery.combobox.js
	} %SEL [S $selector] %OPTS [opts combobox {*}$args] {
	    $('%SEL').combobox(%OPTS);
	}]
    }

    proc autocomplete {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js
	} %SEL [S $selector] %OPTS [opts autocomplete {*}$args] {
	    $('%SEL').autocomplete(%OPTS);
	}]
    }

    # http://aext.net/2010/04/bubbleup-jquery-plugin/
    proc bubbleup {r selector args} {
	return [weave $r {
	    jquery.js jquery.ui.js jquery.bubbleup.js
	} %SEL [S $selector] %OPTS [opts bubbleup {*}$args] {
	    $('%SEL').bubbleup(%OPTS);
	}]
    }

    proc toolbar {r} {
	set r [scripts $r jquery.js jquery.ui.js jquery.toolbar.js]	;# preload scripts first
	set r [style $r jquery.toolbar.css]
	return $r
    }

    if {0} {
	proc websocket {r var url args} {
	    if {[llength $args]%2} {
		set script [lindex $args end]
		set args [lrange $args 0 end-1]
	    } else {
		set script ""
	    }
	    return [weave $r {
		jquery.js jquery.websockets.js
	    } "var $var = \$.websocket('$url', [opts websocket {*}$args]);\n$script;"]
	}
    }

    proc websocket {r var url args} {
	if {[llength $args]%2} {
	    set script [lindex $args end]
	    set args [lrange $args 0 end-1]
	} else {
	    set script ""
	}

	if {[dict exists $args events]} {
	    set onmessage "ws.onmessage = function (e) \{[dict get $args events];\}"
	} else {
	    set onmessage ""
	}

	if {[dict exists $args open]} {
	    set onopen "ws.onopen = function() \{alert('open'); [dict get $args open];$onmessage; $script;\}"
	} else {
	    set onopen "ws.onopen = function() \{alert('open'); $onmessage; $script;\}"
	}

	if {[dict exists $args close]} {
	    set onclose "ws.onclose = function() \{[dict get $args close];\}"
	} else {
	    set onclose ""
	}

	return [weave $r {jquery.js} "
	    if ('WebSocket' in window) {
		var ws = new WebSocket('$url');
		$onopen;
		$onclose;
		$onmessage;
	    } else {
		alert ('browser does not support WebSocket');
	    }
	"]
    }

    proc do {r} {
	fs do $r
    }

    proc new {args} {
	variable {*}[Site var? jQ]	;# allow .ini file to modify defaults
	variable {*}$args
	
	# construct a File wrapper for the jscript dir
	variable root; variable mount; variable expires
	set mount /[string trim $mount /]/

	if {[info commands ::jQ::fs] eq ""} {
	    File create ::jQ::fs {*}$args root $root mount $mount expires $expires
	}
	return jQ
    }

    proc create {junk args} {
	return [new {*}$args]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

interp alias {} JQ {} jQ	;# convention - Domain names start with U/C char
# vim: ts=8:sw=4:noet
