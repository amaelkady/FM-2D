# WubTk.tcl - a domain built around coroutines from tcl8.6
#
# Inspired by Roy Keene's http://www.rkeene.org/projects/tkweb/

# TODO:
#* comet - ajax push - for mods to local vars ... push them to client BUGGY
#* fix Site so it grabs WubTk DONE?
#* rename to Toplevel?
#* [exit] to redirect DONE
#* [toplevel] to create a new window/tab - the old Tk hangs around DONE
#* frame -> fieldset DONE
#* ensure text is working DONE
#* enable/push wm title changes
#* what to do about event [update] stuff? - currently stubbed
#* spinning wheel on updates DONE
#* frames, labelframes DONE
#* add -grid {r c rs cs} option to widgets, to take over the [grid configure .w] function DONE
#* add [Widget relative] method to give name-within-grid DONE
#* move all widget commands into an interp DONE
#* some sort of combo box
#* select list box
#* radiobutton
#* spin selector
#* comboboxes, spinboxes
#* menus

package require Debug
Debug define wubtk 10
Debug on wubtkerr 10
package require Http
package require md5
package require Image	;# force rasterization

package require WubWidgets

package provide WubTk 1.0
if {[catch {package present Tk}]} {
    package provide Tk 8.6
}

set ::API(Domains/WubTk) {
    {WubTk - a Web emulation of Tk}
}

set ::WubTk_dir [file normalize [file dirname [info script]]]

class create ::WubTkI {
    # code to activate button JS for given objects
    method buttonJS {{what .button}} {
	return [string map [list %B% $what] {
	    $('%B%').button();
	    $('%B%').click(buttonJS);
	}]
    }

    # code to activate cbutton JS for given objects
    method cbuttonJS {{what .cbutton}} {
	return [string map [list %B% $what] {
	    $('%B% > :checkbox').change(cbuttonJS);
	}]
    }

    # code to activate rbutton JS for given objects
    method rbuttonJS {{what .rbutton}} {
	return [string map [list %B% $what] {
	    $('%B%').click(rbuttonJS);
	}]
    }

    # code to activate variable JS for given objects
    method variableJS {{what .variable}} {
	return [string map [list %B% $what] {
	    $('%B%').change(variableJS);
	}]
    }

    # update - accumulate HTML and JS to reflect changes to given set of widgets
    method update {changes} {
	Debug.wubtk {[self] UPDATE ($changes)}

	set result ""
	foreach {widget id html type} $changes {
	    Debug.wubtk {[namespace tail [self]] changed id: $id type: $type}
	    dict lappend classified $type $id
	    set html [string map {\n \\n} $html]
	    set jid #$id

	    # generate replacement HTML for changed widget
	    append result "<!-- update widget:$widget id:$id type:$type -->" \n
	    append result [string map [list %ID% $jid %H% $html] {
		$('%ID%').replaceWith("%H%");
	    }]

	    # generate js to track widget state
	    append result [$widget tracker]
	}

	Debug.wubtk {SCRIPT: ($result)}
	return $result
    }

    # strip any of the js donated by changed components
    # and plug it on the end of the generic stuff.
    method stripjs {r} {
	set content {}
	dict for {n v} [dict get? $r -script] {
	    if {[string match !* $n]} {
		#Debug.wubtk {stripjs: $n ($v)}
		set v [join [lrange [split [string trim $v] \n] 1 end-2] \n]
		lappend content $v
	    }
	}
	return [join $content \n]
    }

    method rq {} {
	variable r
	return $r
    }

    # record change indication from widgets
    method prod {what} {
	variable changes
	dict set changes $what 1	;# record changed widgets

	variable lastupdate; variable maxlag
	set now [clock milliseconds]
	if {$now - $lastupdate > $maxlag} {
	    after 0 [list [info coroutine] prod]	;# we've waited long enough prod now
	} else {
	    variable updater
	    catch {after cancel $updater}
	    variable frequency
	    set updater [after $frequency [list [info coroutine] prod]]
	}
    }

    # reset change indication from widgets
    method reset {what} {
	variable changes
	if {[dict exists $changes $what]} {
	    dict unset changes $what
	}
    }

    # return script to widget
    method script {} {
	variable script
	return $script
    }

    # set redirect for widget
    method redirect {args} {
	variable redirect
	if {[llength $args]} {
	    set redirect $args
	} else {
	    return $redirect
	}
    }

    # do_redir - perform redirection if requested
    method do_redir {r {js 0}} {
	variable redirect
	set redir $redirect
	if {![llength $redir]} {
	    return $r
	}
	set redirect ""	;# forget redirection request now

	# we've been asked to redirect ... so do it
	if {$js} {
	    set redir [Url redir $r {*}$redir]
	    Debug.wubtk {do_redir javascript: $redir}
	    return [Http Ok $r "window.location='$redir';" application/javascript]
	} else {
	    Debug.wubtk {do_redir HTTP: $redirect}
	    return [Http Redirect $r {*}$redirect]
	}
    }

    # support the cookie widget
    method cookie {op caller args} {
	variable cdict	;# current request's cookies
	if {[llength $args]%2} {
	    set args [lassign $args value]
	}

	set name [$caller widget]
	set opts {path domain port expires secure max-age}
	foreach n $opts {
	    set val [$caller cget? -$n] 
	    if {$val ne ""} {
		set $n $val
	    }
	}

	variable cookiepath;
	if {[info exists path]} {
	    if {[string first $cookiepath $path] != 0} {
		set path "$cookiepath/$path"
		$caller configure -path $path
	    }
	} else {
	    set path $cookiepath
	    $caller configure -path $path
	}

	set matcher {}
	set rest {}
	foreach n [list name {*}$opts] {
	    if {![info exists $n]} continue
	    if {$n in {name path domain}} {
		lappend matcher -$n [set $n]
	    } else {
		lappend rest -$n [set $n]
	    }
	}

	Debug.wubtk {cookie $op matcher:$matcher rest:$rest for $caller}

	switch -- $op {
	    get {
		return [dict get [Cookies fetch $cdict {*}$matcher] -value]
	    }

	    clear {
		set cdict [Cookies clear $cdict {*}$matcher]
	    }

	    set {
		set matches [Cookies match $cdict {*}$matcher]
		if {![llength $matches]} {
		    set cdict [Cookies add $cdict -value $value {*}$matcher {*}$rest]
		}
		set cdict [Cookies modify $cdict -value $value {*}$args {*}$matcher {*}$rest]
	    }

	    construct {
		set matches [Cookies match $cdict {*}$matcher]
		if {[llength $matches] > 1} {
		    error "Ambiguous cookie, matches '$matches'"
		} else {
		    Debug.wubtk {new cookie $matcher}
		}
		if {[llength $matches]} {
		    $caller configure {*}[Cookies fetch $cdict {*}$matcher]
		}
	    }
	}
    }

    method tl {op widget args} {
	variable toplevels
	switch -- $op {
	    add {
		dict set toplevels $widget visible
	    }
	    delete {
		dict set toplevels $widget delete
	    }
	    hide {
		dict set toplevels $widget hide
	    }
	}
    }

    method addprep {sel args} {
	variable prep
	dict set prep $sel,$args [list $sel $args]
    }

    method prep {r} {
	# re-render whole page
	set r [jQ jquery $r]
	set r [jQ scripts $r jquery.form.js jquery.metadata.js]
	#set r [jQ tabs $r .notebook]
	#set r [jQ accordion $r .accordion]B
	set r [jQ pnotify $r]
	#set r [jQ combobox $r .combobox]

	# add in preparatory jQ as required by widgets
	variable prep
	foreach {n v} $prep {
	    lassign $v n v
	    Debug.wubtk {preparatory: jQ $n . $v}
	    set r [jQ $n $r {*}$v]
	}

	# define some useful functions
	set r [Html postscript $r {
	    $.metadata.setType("html5");	// use HTML5 metadata

	    function ereport (status, error) {
		$.pnotify({pnotify_title: "Ajax "+status, pnotify_type: 'error', pnotify_text: error.description});
	    }

	    function buttonJS () { 
		//alert($(this).attr("name")+" button pressed");
		$("#Spinner_").show();
		$.ajax({
		    context: this,
		    type: "GET",
		    url: ".",
		    data: {
			id: $(this).attr("name"),
			_op_: "command"
		    },
		    dataType: "script",
		    success: function (data, textStatus, XMLHttpRequest) {
			$("#Spinner_").hide();
			//alert("button: "+data);
		    },
		    error: function (xhr, status, error) {
			ereport(status, error);
		    }
		});
	    }

	    function rbuttonJS () { 
		$("#Spinner_").show();

		var name = $(this).attr("name");
		var val = $(this).val();
		$.metadata.setType("html5");
		var widget = $(this).metadata().widget;
		//alert(name+" rbutton value "+ val+ " widget:"+widget);

		$.ajax({
		    context: this,
		    type: "GET",
		    url: ".",
		    data: {
			id: name,
			val: val,
			widget: widget,
			_op_: "rbutton"
		    },
		    dataType: "script",
		    success: function (data, textStatus, XMLHttpRequest) {
			$("#Spinner_").hide();
			//$.pnotify({pnotify_title: "RadioButton", pnotify_text: data})
			//alert("rbutton: "+data);
		    },
		    error: function (xhr, status, error) {
			ereport(status, error);
		    }
		});
	    }

	    function cbuttonJS () { 
		//alert($(this).attr("name")+" cbutton pressed");
		$("#Spinner_").show();
		var data = {id: $(this).attr("name"), val: 0, _op_: "cbutton"};
		var val = this.value;
		if($(this).is(":checked")) {
		    data['val'] = val;
		}

		$.ajax({
		    context: this,
		    type: "GET",
		    url: ".",
		    data: data,
		    dataType: "script",
		    success: function (data, textStatus, XMLHttpRequest) {
			$("#Spinner_").hide();
			//alert("cbutton: "+data);
		    },
		    error: function (xhr, status, error) {
			ereport(status, error);
		    }
		});
	    }

	    function sliderJS (e, id, ui) {
		if(e.originalEvent==undefined) {
		    //
		    // event was triggered programmatically
		    //
		    return
		}

		// event was triggered by user
		$("#Spinner_").show();
		$.ajax({
		    type: "GET",
		    url: ".",
		    data: {id: id,
			val: ui.value,
			_op_: "slider"
		    },
		    dataType: "script",
		    success: function (data, textStatus, XMLHttpRequest) {
			$("#Spinner_").hide();
			// alert("slider: "+data);
		    },
		    error: function (xhr, status, error) {
			alert("ajax fail:"+status);
		    }
		});
	    }

	    function autocompleteJS (event,entry) {
		if(event.originalEvent==undefined) {
		    //
		    // event was triggered programmatically
		    //
		    return
		}

		//alert($(entry).attr("name")+" autocomplete: " + $(entry).val());
		$("#Spinner_").show();
		$.ajax({
		    context: $(entry),
		    type: "GET",
		    url: ".",
		    data: {
			id: $(entry).attr("name"),
			val: encodeURIComponent($(entry).val()),
			_op_: "var"
		    },
		    dataType: "script",
		    success: function (data, textStatus, XMLHttpRequest) {
			$("#Spinner_").hide();
			//alert("variable: "+data + encodeURIComponent($(entry).val()));
		    },
		    error: function (xhr, status, error) {
			ereport(status, error);
		    }
		});
	    }

	    function variableJS () {
		//alert($(this).attr("name")+" changed: " + $(this).val());
		$("#Spinner_").show();
		$.ajax({
		    context: this,
		    type: "GET",
		    url: ".",
		    data: {
			id: $(this).attr("name"),
			val: encodeURIComponent($(this).val()),
			_op_: "var"},
		    dataType: "script",
		    success: function (data, textStatus, XMLHttpRequest) {
			//alert("variable: "+data + encodeURIComponent($(this).val()));
			$("#Spinner_").hide();
		    },
		    error: function (xhr, status, error) {
			ereport(status, error);
		    }
		});
	    }
	}]

	# send js to track widget state
	set r [jQ ready $r [my buttonJS]]
	set r [jQ ready $r [my cbuttonJS]]
	set r [jQ ready $r [my rbuttonJS]]
	set r [jQ ready $r [my variableJS]]
	set r [Html postscript $r "\$('.ubutton').button();"]
	return $r
    }

    method render {r} {
	variable redirect
	if {[llength $redirect]} {
	    # the widget command did a redirect
	    return [my do_redir $r]
	}

	set r [my prep $r]
	variable timeout

	if {$timeout > 0} {
	    Debug.wubtk {Comet push $timeout}
	    set r [jQ comet $r ./?_op_=refresh]
	} else {
	    Debug.wubtk {Comet no push}
	}

	# add some CSS
	variable theme
	variable theme_switcher
	set r [jQ theme $r $theme]
	if {$theme_switcher} {
	    # add theme switcher
	    append content [my <div> id switcher style {float:right}]
	    set r [Html script $r http://jqueryui.com/themeroller/themeswitchertool/]
	    set r [Html postscript $r {
		$('#switcher').themeswitcher();
	    }]
	}

	variable fontsize
	set dcss [subst {
	    .ui-widget {font-size:${fontsize}px !important;}
	    .ui-autocomplete {
		max-height: 100px;
		overflow-y: auto;
	    }
	    /* IE 6 doesn't support max-height
	    * we use height instead, but this forces the menu to always be this tall
	    */
	    * html .ui-autocomplete {
		height: 100px;
	    }

	    ul.toolbar {
		list-style: none;
		display: inline-block;
		border: 1px solid;
		padding: 0px;
	    }
	    
	    ul.toolbar li {
		padding: 0px;
		float: left;
		margin: 0px;
	    }
	}]

	append content [<style> $dcss]
	set r [Html prestyle $r [<style> $dcss]]

	set css [wm css .]
	if {$css ne ""} {
	    append content [<style> $css]
	}

	set style [wm stylesheet .]
	if {$style ne ""} {
	    set r [Html postscript $r [<stylesheet> {*}$style]]
	}

	try {
	    append content [grid render]
	    set r [grid js $r]
	    Debug.wubtk {RENDER JS: [my stripjs $r]}
	    append content [my <span> id STORE {}]

	    variable toplevels
	    set tljs {}
	    foreach {tl tv} $toplevels {
		set tlw [$tl widget]
		# render visible toplevels
		Debug.wubtk {TV $tl: $tv}
		switch -- $tv {
		    visible {
			# open the toplevel window/tab
			set title [$tl cget? -title]
			if {$title eq ""} {
			    set title $tlw
			}
			set opts [list '$tlw/' '$title']
			if {0} {
			    foreach opt {titlebar menubar toolbar
				location scrollbars status resizable} {
				if {[$tl cget $opt]} {
				    lappend opts $opt='yes'
				} else {
				    lappend opts $opt='no'
				}
			    }
			    foreach opt {width height left top} {
				if {[$tl cget? $opt] ne ""} {
				    lappend opts $opt=[$tl cget $opt]
				}
			    }
			}
			lappend tljs "\$('#STORE').data('$tlw', window.open([join $opts ,]))"
		    }
		    delete {
			# close the toplevel window/tab
			lappend tljs "\$('#STORE').data('$tlw').close()"
			dict unset toplevels $tl
		    }
		    hide {
			# close the toplevel window/tab
			lappend tljs "\$('#STORE').data('$tlw').close()"
		    }
		}
		if {[llength $tljs]} {
		    set tljs [join $tljs ";\n"]
		    set r [Html postscript $r $tljs]
		}
	    }

	    variable icons
	    variable spinner_size
	    variable spinner_style
	    append content [string map [list %SS% $spinner_style] [my <img> id Spinner_ style {%SS%; display:none;} width $spinner_size src $icons/bigrotation.gif]]
	    Debug.wubtk {RENDERED: $content}

	    dict set r -title [wm title .]
	    dict lappend r -headers [wm header .]
	    
	    set r [Http Ok $r $content x-text/html-fragment]
	} on error {e eo} {
	    set r [Http ServerError $r $e $eo]
	}

	return $r
    }

    method do_comet {r} {
	# client has asked us to push changes
	Debug.wubtk {[self] client has asked us to push changes}
	set changes [lassign [grid changes $r] r]
	set update [my update $changes]
	append update [my stripjs $r]

	if {$update eq ""} {
	    # no updates to send
	    if {[info exists _comet]} {
		# we already have a pending _comet
		# just send out something to satisfy it
		Debug.wubtk {WubTk [info coroutine] - double refresh}
		set _comet [Http Ok $_comet {} application/javascript]
		Httpd Resume $_comet
	    }
	    set _comet $r	;# remember request
	    set r [Httpd Suspend $r]	;# suspend until changes
	    grid prod 1	;# register interest
	} else {
	    # send out what updates we have
	    append update \n "<!-- do_comet -->" \n
	    set r [Http Ok $r $update application/javascript]
	}
	return $r
    }

    # process a browser event
    method event {r} {
	# clear out any old refresh - this response will satisfy it
	if {[info exists _comet]} {
	    Debug.wubtk {satisfy old refresh}
	    set re [Http Ok $_comet {} application/javascript]
	    unset _comet
	    Httpd Resume $re
	} else {
	}
	
	# client event has been received
	set Q [Query flatten [Query parse $r]]
	set widget .[dict Q.id]

	if {[llength [info commands [namespace current]::$widget]]} {
	    # the widget addressed exists - process the requested operation
	    Debug.wubtk {event $widget ($Q)}
	    set content "<!-- changes due to event '$widget [dict r.-op] [string range [dict Q.val?] 0 10]...' -->\n"
	    try {
		# run the $widget operation specified by $op
		$widget [dict r.-op] [dict Q.val?] {*}[dict Q.widget?]
	    } on error {e eo} {
		# widget operation caused an error - report on it
		set errpopup [jQ popup type error title "Script Error" [armour $e]]
		Debug.wubtkerr {event error on $widget: '$e' ($eo)}
		append content $errpopup
	    } finally {
		# widget operation completed, or error noted
		variable redirect
		if {[llength $redirect]} {
		    # the widget command did a redirect
		    tailcall my do_redir $r 1
		}

		# reflect changes consequent to the widget operation
		# a sufficiently comprehensive change will trigger a -repaint
		set changes [lassign [grid changes $r] r] ;# calculate changeset
		if {[dict exists $r -repaint]} {
		    # a repaint has been triggered through grid operation
		    # this response causes a reload of the entire page
		    catch {dict unset -r -script}	;# discard accumulated js
		    tailcall Http Ok $r {window.location='.';} application/javascript
		}

		# normal result - respond with changes caused by event processing
		append content \n [my update $changes]
		append content \n [my stripjs $r]

		tailcall Http Ok $r $content application/javascript
	    }
	} else {
	    # widget doesn't exist - report that
	    Debug.wubtk {not found [namespace current]::$widget}
	    set content [jQ popup type error "Widget '$widget' does not exist."]
	    return [Http Ok $r $content application/javascript]
	}
    }

    method do_image {r} {
	set cmd .$widget
	if {[llength [info commands [namespace current]::$cmd]]} {
	    Debug.wubtk {image $cmd}
	    set r [$cmd fetch $r]
	} else {
	    Debug.wubtk {not found image [namespace current]::$cmd}
	    set r [Http NotFound $r]
	}
	return $r
    }

    # do - main entry point for per-user coro
    # at this point we're running a read-eval-print loop in that coro
    # this code yields at appropriate points with HTTP response dicts filled with
    # responses to (usually) client events (usually per-widget)
    method do {req lambda} {
	Debug.wubtk {[info coroutine] PROCESS in namespace:[namespace current]}

	variable r $req	;# keep our current request around
	variable script $lambda	;# record original script for app to fetch if it wants it
	variable coro [info coroutine]	;# remember this coro for [after] code

	# run user code - return result
	variable cdict [dict get? $r -cookies]

	my limit 10	;# enforce time limit on our Interp
	Interp eval $lambda	;# install the user code
	my unlimit

	set r [my render $r]	;# traverse widget tree to HTML/JS
	Debug.wubtk {COOKIES: $cdict}
	dict set r -cookies $cdict	;# reflect cookies back to client

	# initial client direct request
	variable exit 0
	while {!$exit} {
	    lassign [::yieldm [Http NoCache $r]] what r
	    Debug.wubtk {[info coroutine] processing '$what'}
	    switch -- $what {
		prod {
		    # our grid has prodded us - there are changes
		    # to be pushed to the client
		    if {[info exists _comet]} {
			Debug.wubtk {prodded with suspended refresh}
			# we've been prodded by grid with a pending refresh
			set changes [lassign [grid changes $_comet] _comet]
			set content [my update $changes]
			append content [my stripjs $_comet]
			set re [Http Ok $_comet $content application/javascript]
			unset _comet
			Httpd Resume $re
		    } else {
			Debug.wubtk {prodded without suspended refresh}
		    }
		}

		terminate {
		    # process a terminate request
		    Debug.wubtk {requested termination}
		    break	;# we've been asked to terminate
		}

		client {
		    # process a client request
		    set cdict [dict get? $r -cookies]

		    # unpack query response
		    Debug.wubtk {[info coroutine] Event: [dict r.-op?]}
		    my limit	;# enforce the command limit on our Interp
		    switch -- [dict r.-op?] {
			command -
			cbutton -
			slider -
			rbutton -
			var {
			    # process browser event as a widget operation
			    set r [my event $r]
			}

			fetch {
			    # client fetch has been received
			    set widget .[dict r.-widget]
			    set r [$widget fetch $r]
			}

			autocomplete {
			    # this is autocomplete - we get to call the -command with
			    # one argument passed in

			    # client event has been received
			    set Q [Query flatten [Query parse $r]]
			    set widget .[dict r.-widget]
			    set term [dict Q.term]
			    set result [$widget command $term]

			    # we should have a list in reply, convert it to JSON
			    set json {}
			    foreach v $result {
				lappend json '[string map {' \'} $v]'
			    }
			    set json \[[join $json ,]\]
			    Debug.wubtk {autocomplete: $result -> ($json)}
			    set r [Http Ok [Http NoCache $r] $json application/json]
			}

			upload {
			    # client event has been received for upload file
			    set Q [Query flatten [Query parse $r]]
			    set widget .[dict Q.id]

			    if {[llength [info commands [namespace current]::$widget]]} {
				Debug.wubtk {event $widget ($Q)}
				try {
				    $widget [dict r.-op] [dict Q.val?]
				} on error {e eo} {
				    # what to do on an upload error?
				} finally {
				    set r [my render $r]
				}
			    } else {
				# widget doesn't exist - report that
				Debug.wubtk {not found [namespace current]::$widget}
				set content [jQ popup type error "Widget '$widget' not found"]
				set r [Http Ok $r $content application/javascript]
			    }
			}

			comet {
			    # process refresh event
			    set r [my do_comet $r]
			}

			default {
			    # nothing else to be done ... repaint display by default
			    set widget [dict r.-widget]
			    if {$widget eq ""} {
				Debug.wubtk {render .}
				set r [my render $r]
			    } else {
				Debug.wubtk {fetch and render toplevel $widget}
				try {
				    set r [.$widget fetch $r]
				} on error {e eo} {
				    set r [Http ServerError $r $e $eo]
				} finally {
				}
			    }
			}
		    }
		    my unlimit
		    dict set r -cookies $cdict	;# reflect cookies back to client
		    Debug.wubtk {[info coroutine] Event Complete: [dict r.-op?]}
		}
	    }

	    Debug.wubtk {[info coroutine] processed '$what'}

	    # each time through this loop we have interacted with the client
	    # record the time of last interaction for comet.
	    variable changes
	    if {[dict size $changes]} {
		variable lastupdate [clock milliseconds]
		variable updater
		catch {after cancel $updater}
		variable frequency
		set updater [after $frequency [list [info coroutine] prod]]
	    }
	}

	# fallen out of loop - time to go
	Debug.wubtk {[info coroutine] exiting}
	return $r
    }

    # maintain a table of unique pseudo-widgets for variables
    # used to give radiobuttons a single name
    method rbvar {var} {
	variable rbvars
	if {[dict exists $rbvars $var]} {
	    return [dict rbvars.$var]
	} else {
	    variable rbcnt
	    set rb [WubWidgets rbC create [namespace current]::.rb[incr rbcnt] variable $var -interp [list [namespace current]::Interp eval]]
	    dict rbvars.$var $rb
	    return $rb
	}
    }

    destructor {
	catch {Interp destroy}
    }

    method destroyme {args} {
	variable rbvars
	dict for {n v} $rbvars {
	    catch {$v destroy}
	}
	[self] destroy
    }

    method bgerror {args} {
	puts stderr "BGERROR: $args"
    }

    superclass FormClass
    constructor {args} {
	variable interp {}
	variable {*}$args
	variable redirect ""	;# no redirection, initially
	variable exit 0		;# do not exit, initially
	variable prep {}
	variable frequency 300	;# ms between push update
	variable maxlag 600	;# how many ms between updates
	variable limit ""	;# interpreter command limit (default none)
	variable safe 0		;# is this to be a safe interp

	next? {*}$args		;# construct Form
	Debug.wubtk {constructed WubTkI self-[self]  - ns-[namespace current] ($args)}

	variable toplevels {}	;# track toplevels
	variable rbvars {}	;# track radiobutton vars
	variable changes {}	;# track changes per widget

	variable lastupdate 0	;# track time of last update

	if {$theme ne ""} {
	    # set Form defaults
	    foreach w {text password file textarea} {
		my setdefault $w class {ui-state-default ui-corner-all}
	    }
	    my setdefault button class {ui-button ui-widget ui-state-default ui-corner-all}
	    my setdefault fieldset class {ui-widget ui-corner-all}
	    my setdefault table class ui-widget
	    #my setdefault table style {width:80%} 
	    my setdefault tbody class ui-widget
	    my setdefault legend class {legend ui-widget-header ui-corner-all}
	    my setdefault label class {label ui-corner-all}
	}

	# create an interpreter within which to evaluate user code
	# install its command within our namespace
	set interp [::interp create {*}[expr {$safe?"-safe":""}] {*}$interp -- [namespace current]::Interp]
	if {0} {
	    Interp eval {
		proc ::bgerror {args} {
		    puts stderr "BGERROR: $args"
		}
	    }
	    Interp bgerror bgerror
	}
	Interp alias bgerror [self] bgerror

	Debug.wubtk {[info coroutine] INTERP $interp}
	Interp eval [list set ::auto_path $::auto_path]

	# create per-coro namespace commands
	namespace eval [namespace current] {
	    proc exit {value} {
		variable exit 1	;# flag the exit
		variable coro
		Debug.wubtk {exit $value}
		set C [info coroutine]
		if {$C eq ""} {
		    # we're not running in the coro, perhaps an [after]
		    # or [fileevent] has triggered this call.
		    # we need to tell the coro to die
		    Debug.wubtk {exit from outside coro $coro}
		    $coro terminate
		} else {
		    Debug.wubtk {exit from coro $C ($coro)}
		    if {![string is integer -strict $value]} {
			my redirect {*}$value
		    }
		}
		Debug.wubtk {exit complete}
	    }

	    proc connection {args} {
		return [my {*}$args]
	    }

	    proc destroy {} {
		namespace delete [namespace current]
	    }
	    proc update {args} {}
	}

	# per-coro grid instance for toplevel .
	WubWidgets gridC create [namespace current]::grid interp [list [namespace current]::Interp eval]
	WubWidgets wmC create [namespace current]::wm		;# per-coro wm instance

	if {[info exists css]
	    && $css ne ""
	} {
	    wm css . $css
	}

	if {[info exists stylesheet]
	    && $stylesheet ne ""
	} {
	    wm stylesheet . {*}$stylesheet
	}

	foreach n {grid wm connection destroy update exit} {
	    Interp alias $n [namespace current]::$n
	}
	Interp alias rq [self] rq

	# install aliases for Tk Widgets
	foreach n $::WubWidgets::tks {
	    proc [namespace current]::$n {w args} [string map [list %N% $n %C% [self]] {
		Debug.wubtk {SHIM: 'WubWidgets %N%C create [namespace current]::$w'}
		set obj [WubWidgets %N%C create [namespace current]::$w -interp [list [namespace current]::Interp eval] -connection %C% {*}$args]
		return [namespace tail $obj]
	    }]
	    Interp alias $n [namespace current]::$n	;# reflect widget command to interp
	}

	# construct an image command for the interp
	proc image {args} {
	    Debug.wubtk {SHIM: 'WubWidgets image $args'}
	    set args [lassign $args cmd]
	    if {$cmd eq "create"} {
		set obj [WubWidgets image create {*}$args -interp [list [namespace current]::Interp eval]]
		Debug.wubtk {SHIMAGE: $obj}
		return [namespace tail $obj]
	    } else {
		return [WubWidgets image $cmd {*}$args]
	    }
	}

	Interp alias image [namespace current]::image
	Interp eval {package provide Tk 8.6}

	oo::objdefine [self] forward site ::Site
    }

    # limit - Interp's hit its limit
    method limiter {} {
	Debug.wubtk {limiter - interpreter limit exceeded}
	error "WubTk Interpreter limit exceeded."
    }

    method unlimit {} {
	Interp limit time -seconds ""
    }

    method limit {{mult 1}} {
	variable limit
	if {$limit ne ""} {
	    set time [expr {[clock seconds] + ($limit*$mult)}]
	    Interp limit time -seconds $time
	} else {
	    Debug.wubtk {unlimited}
	}
    }
}

class create ::WubTk {
    method getcookie {r} {
	variable cookie
	# try to find the application cookie
	set cl [Cookies Match $r -name $cookie]
	if {[llength $cl]} {
	    # we know they're human - they return cookies (?)
	    return [dict get [Cookies Fetch $r -name $cookie] -value]
	} else {
	    return ""
	}
    }

    method newcookie {r {cmd ""}} {
	if {$cmd eq ""} {
	    # create a new cookie
	    variable uniq; incr uniq
	    set cmd [::md5::md5 -hex $uniq[clock microseconds]]
	}

	# add a cookie to reply
	if {[dict exists $r -cookies]} {
	    set cdict [dict get $r -cookies]
	} else {
	    set cdict [dict create]
	}

	# include an optional expiry age
	variable expires
	if {$expires ne ""} {
	    if {[string is integer -strict $expires]} {
		# it's an age
		if {$expires != 0} {
		    set expiresC [Http Date [expr {[clock seconds] + $expires}]]
		    set expiresC [list -expires $expires]
		} else {
		    set expiresC {}
		}
	    } else {
		set expiresC [Http Date [clock scan $expires]]
		set expiresC [list -expires $expires]
	    }
	} else {
	    set expiresC {}
	}
	
	# add the cookie
	variable cookie; variable mount
	set cdict [Cookies add $cdict -path $mount -name $cookie -value $cmd {*}$expiresC]
	Debug.wubtk {created wubapp cookie $cdict}
	
	dict set r -cookies $cdict
	dict set r -wubapp $cmd
	return $r
    }

    method call {r cmd suffix extra} {
	# this is an existing coroutine - call it and return result
	Debug.wubtk {calling coroutine '$cmd' with extra '$extra'}
	if {[catch {
	    [namespace current]::Coros::$cmd client $r
	} result eo]} {
	    Debug.error {'$cmd' error: $result ($eo)}
	    return [Http ServerError $r $result $eo]
	}
	Debug.wubtk {'$cmd' yielded: ($result)}
	return $result
    }

    # process request helper
    method do {r} {
	variable mount
	# calculate the suffix of the URL relative to $mount
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return [Httpd NotFound $r]	;# the URL isn't in our domain
	}

	# decode stuff to the right of the mount URL
	set widget ""
	dict set r -extra [join [set extra [lassign [split $suffix /] widget]] /]
	dict set r -widget $widget

	# get op from query
	set Q [Query parse $r]; dict set r -Query $Q; set Q [Query flatten $Q]
	dict set r -op [set op [dict Q._op_?]]
	if {$op eq ""} {
	    set op [dict Q.term?]
	    if {$op ne ""} {
		dict set r -op autocomplete
		set op autocomplete
	    }
	}

	set wubapp [my getcookie $r]	;# get the wubapp cookie
	Debug.wubtk {process cookie: '$wubapp' widget:'$widget' op:'$op' extra:'$extra' suffix:'$suffix' over '$mount'}
	
	if {$wubapp ne ""
	    && [namespace which -command [namespace current]::Coros::$wubapp] ne ""
	} {
	    dict set r -wubapp $wubapp
	    return [my call $r $wubapp $suffix $extra]
	} else {
	    Debug.wubtk {coroutine gone: $wubapp -> $mount$widget}
	    if {$wubapp ne ""} {
		# they handed us a cookie relating to a defunct coro,
		# doesn't matter, the value is purely nominal,
		# go with it.
		if {$op ne ""} {
		    # this is an old invocation trying to get javascript
		    # make it redirect
		    set app "$mount/$widget/"
		    return [Http Ok $r "window.location='$app';" application/javascript]
		}
	    } else {
		set r [my newcookie $r]	;# brand new webapp
		set wubapp [dict get $r -wubapp]
	    }

	    # collect options to pass to coro
	    set options {}
	    foreach v {timeout icons theme spinner_style spinner_size css stylesheet cookiepath theme_switcher fontsize limit} {
		variable $v
		if {[info exists $v]} {
		    lappend options $v [set $v]
		}
	    }

	    # create the coroutine to service this WubTk session
	    try {
		set req $r
		my reload
		variable lambda
		set o [::WubTkI create [namespace current]::Coros::O_$wubapp {*}$options]
		set r [::Coroutine [namespace current]::Coros::$wubapp $o do $r $lambda]
		if {[llength [info command [namespace current]::Coros::$wubapp]]} {
		    # when the coro dies, clean up the related object too
		    trace add command [namespace current]::Coros::$wubapp delete [list $o destroyme]
		}
	    } on error {e eo} {
		Debug.wubtk {[info coroutine] error '$e' ($eo)}
		catch {$o destroy}
		catch {rename [namespace current]::Coros::$wubapp {}}
		set r [Http ServerError $req $e $eo]
	    }

	    return $r
	}
    }

    method reload {} {
	variable file; variable lambda
	if {[info exists file]} {
	    variable loadtime
	    if {[file mtime $file] > $loadtime} {
		set lambda [fileutil::cat -- $file]
	    }
	}
    }

    constructor {args} {
	variable lambda ""
	variable prep {}
	variable expires ""
	variable stylesheet ""
	variable css {}
	variable theme start
	variable theme_switcher 0
	variable timeout 0
	variable icons /icons/
	variable fontsize 12
	variable spinner_size 20
	variable spinner_style "position: fixed; top:10px; left: 10px;"

	variable {*}[Site var? WubTk]	;# allow .ini file to modify defaults
	variable {*}$args
	set timeout 0

	set fontsize [string trimright $fontsize "px"]

	if {![info exists cookiepath] || $cookiepath eq ""} {
	    variable cookiepath $mount
	}

	if {[info exists file]} {
	    append lambda [fileutil::cat -- $file]
	    variable loadtime [file mtime $file]
	} elseif {![info exists lambda] || $lambda eq ""} {
	    variable lambda [fileutil::cat -- [file join $::WubTk_dir test.tcl]]
	}

	if {![info exists cookie]} {
	    variable cookie [string map {/ _} $mount]
	}

	namespace eval [namespace current]::Coros {}

	next? {*}$args
    }
}
