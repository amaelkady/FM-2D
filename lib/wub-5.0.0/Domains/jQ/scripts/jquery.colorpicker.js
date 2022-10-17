
/**
	An extremely primitive color picker, designed to be used with a jQuery selector, as in:

	<div id='MyColorSelector'></div>

	$('#MyColorSelector').addColorPicker();

	it creates a set of "color blotches" elements and uses jQuery(this).append() to add them
	to the current element. If it is called outside of a jQuery context then it will throw
	an exception.

	Arguments:

	props = an optional array of key/val pairs:

	props.colors = array of colors (hex, rgb(), or (null or 'transparent')). The default
	contains a hex-encoded "premium, hand-picked selection" of common
	reds/yellows/blues, plus null (treated as transparent).

	props.blotchElemType: Element Type for each color blotch (default='span')

	props.blotchClass: CSS class for each element (default='ColorBlotch')

	props.clickCallback: a callback tied to each blotch, called when the blotch
	is clicked. It is passed a single color argument (hex-encoded or rgb(r,g,b)
	or null, as defined in .colors). For the special transparent color, the callback
	is passed the string 'transparent'. The default callback does nothing.

	props.iteractionCallback: function(target,elem,color,iterationNumber) is
	called after each blotch is append()ed. It is passed the target jQuery
	object, the blotch jQuery object, current color (same encoding as in
	.colors), and the current iteration count (starts at 0 and increments 1
	per blotch added). This can be used to gain some control over the layout,
	e.g. by inserting a <br/> every 5 iterations. e.g.:
		iterationCallback: function(tgt,elem,i) { if( !((i+1)%5) ) tgt.append('<br/>') }
	The default callback is null.


	props.fillString: a string which gets inserted into all
	non-transparent color blotches.

	props.fillStringX: a string which gets inserted into
	transparent blotches.


	Peculiarities of the implementation:

	- each "cell" of the selector is populated with a single
	&nbsp; UNLESS the color is (null or 'transparent'), in which
	case a '?' is used (this is to avoid visual confusion with a
	blotch of the same background container as the target
	element. If you don't like this, you can use the
	iterationCallback to change the content using jQuery's .text()
	or .html() functions.


	Code home page: http://wanderinghorse.net/computing/javascript/

	License: Public Domain

	Author: stephan beal (http://wanderinghorse.net/home/stephan/)

	Terse revision history (newest at the top):

	20070712:
	- integrated changes/comments from Jörn Zaefferer.
	- renamed func: braindeadColorSelector() to addColorPicker(), because that's
		really what the function does.

	20070711: initial release
*/
jQuery.fn.addColorPicker = function( props ) {
	if( ! props ) { props = []; }
	props = jQuery.extend({
		blotchElemType: 'span',
		blotchClass:'ColorBlotch',
		clickCallback: function(ignoredColor) {},
		iterationCallback: null,
		fillString: '&nbsp;',
		fillStringX: '?',
		colors: [
			'transparent', '#ffffff','#d0d0d0','#777777','#000000', // monochromes
			'#ffaaaa','#ff00ff', '#ff0000','#aa0000','#9000ff', // reds
			'#ff6c00', '#ffff00', '#ffbb00', '#f0e68c','#d2b229', // browns/oranges/yellows
			'#aaffaa','#00ff00','#00aa00','#6b8e23','#007700', // greens
			'#bbddff','#00ffdd', '#aaaaff','#0000ff','#0000aa' // blues
			]
	}, props);
	var count = props.colors.length;
	for( var i = 0; i < count; ++i ) {
		var color = props.colors[i];
		if( ! color ) color='transparent';
		var elem = jQuery('<'+props.blotchElemType+'/>')
			.addClass( props.blotchClass )
			.css( 'background-color',color); // jq bug: chaining here fails if color is null b/c .css() returns (new String('transparent'))!
		elem.html( ('transparent' == color) ? props.fillStringX : props.fillString );
		if( props.clickCallback ) {
			elem.click( function() { props.clickCallback(jQuery(this).css('background-color')); });
		}
		this.append( elem );
		if( props.iterationCallback ) props.iterationCallback( this, elem, color, i );
	}
	return this;
};
