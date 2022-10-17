/*
LowlanderAccordion is similar to the "accordion" widgets
available for jQuery, but it allows several elements to be
opened at one time. In effect, it is an accordion which does
not enforce Highlander behaviour (i.e. "there can be only one").

This plugin intentionally uses the same HTML structure as Joern
Zaefferer's Accordion plugin so that it is trivial to switch between
the One True Accordion plugin and this one.

///////////////////////////////////////////////////////////////////////
Usage:

	$('#TogglePaneId').initTogglePane({ ... options ... });

Where the available options (all of which are optional) are:

	- speed: an integer (milliseconds) to pass to slideToggle(),
	or one of the conventional string values 'slow', 'normal', 'fast'.
	The default is 'fast'.

	- headerClassClosed: When a pane element is closed, the header
	of that element gets this class added to it. When it is opened,
	this class is removed. Thus all headers can have a client-determined
	class (which we need not pass to initTogglePane() and can use cascading
	to implement the Closed look and feel. There is no default value.

	- startOpened: this may be a boolean, an integer, or one of the
	special numbers, Infinity or NaN. An integer means to start off
	with all elements closed EXCEPT the one at the specified index
	integer (starting at 0 and going to length-1). The special value
	NaN (or false) means to close all elements. Conversely, the special
	number Infinity (or true) means to open all elements. The default is
	true/Infinity. Passing an invalid value (e.g. a string) is the same
	as passing true.

///////////////////////////////////////////////////////////////////////
Working example:

HTML:

	<div id="TogglePaneMain">
		<div>
			<div class="TogglePaneHeader">Header One</div>
			<div class='TogglePaneContent'>Your content goes here.</div>
		</div>
		<div>
			<div class="TogglePaneHeader">Header Two</div>
			<div class='TogglePaneContent'>Your content goes here.</div>
		</div>
	</div><!-- TogglePaneMain -->

Note that there is an "extra" level of DIVs there. This is for compatibility
with the Accordion plugin and it coincidentally(?) simplifies the plugin
code's queries.

Example CSS (optional):

.TogglePaneHeader {
	border: 2px inset #fff;
	background-color: #005;
	color: #fff;
	font-size: 1em;
	padding: 0 1em 0 1em;
}
.TogglePaneHeaderClosed {
	border: 2px outset #fff;
}

.TogglePaneContent {
	background-color: #f0f0f0;
	color: #005;
	padding: 0.5em;
	border-left: 1px inset #000;
	border-right: 1px inset #000;
	font-size: 0.8em;
}


Note that you can also use background images in the CSS styles for
interesting effects:

.TogglePaneHeader {
	border: 2px inset #fff;
	background-image: url(view_remove.png);
	background-repeat: no-repeat;
	background-position: right;
	background-color: #005;
	color: #fff;
	font-size: 1em;
	padding: 0 1em 0 1em;
}
.TogglePaneHeaderClosed {
	border: 2px outset #fff;
	background-image: url(view_top_bottom.png);
}



JavaScript:

To start with all TogglePane elements opened and apply no special class
to the Closed sections:

	$('#TogglePaneMain').initTogglePane();

To start with all TogglePane elements closed and the above-defined
'TogglePaneHeaderClosed' as the class to use for closed section headers:

	$('#TogglePaneMain').initTogglePane({
		headerClassClosed:'TogglePaneHeaderClosed',
		startOpened:false
	});


To start with the second TogglePane element opened:

	$('#TogglePaneMain').initTogglePane({startOpened:1});


///////////////////////////////////////////////////////////////////////
Potential TODOs:

- Add Highlander support ("there can be only one"). There already
exists good Accordion plugins for that, though.

- Add onclick/onshow/onhide handlers. ???

- Figure out how best to support multiple animation types.

- Support different selector types for the startOpened option.

///////////////////////////////////////////////////////////////////////
Author:

	http://wanderinghorse.net/home/stephan/

Based off of Karl Swedberg's article:

	http://www.learningjquery.com/2007/02/more-showing-more-hiding

Plugin home page:

	http://wanderinghorse.net/computing/javascript/jquery/togglepane/

License: Public Domain

Revision history:

- 20070911:
  - Added a workaround to allow it to work around missing lt/gt functions
	in jQuery 1.2.x.


- 20070807: initial release

*/
jQuery.fn.initTogglePane = function( props ) {
	props = jQuery.extend({
		// todo: highlander:false,
		headerClassClosed:null,
		startOpened:Infinity,
		speed:'fast'
		},
		props ? props : {});
	if( false === props.startOpened ) props.startOpened = NaN;
	else if( true === props.startOpened ) props.startOpened = Infinity;
	var wrappers = jQuery('> div',this);
	var contents = jQuery('div:last',wrappers);
	var heads = jQuery('div:first',wrappers);
	if( ! heads.lt ) { // accommodate jQuery 1.2 incompatibility...
		heads.lt = function(index) { return heads.slice(0,index); };
		heads.gt = function(index) { return heads.slice(index+1); };
	}
	heads.click( function() {
		var head = jQuery(this);
		head.next().slideToggle(props.speed,
			props.headerClassClosed
			? function(){head.toggleClass( props.headerClassClosed )}
			: undefined);
	});
	var so = props.startOpened;
	if( isNaN(so) ) {
		heads.click(); // close all
	}
	else if( ! isFinite( so ) ) {
		1; // Inifinity: all are opened.
	}
	else if( (so >= 0) && (so < heads.length) ) {
		heads.lt(so).click();
		heads.gt(so).click();
	} else {
		1; // this is an error, but lamely ignore it.
	}
	return this;
};
