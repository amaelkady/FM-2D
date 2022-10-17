/************************************************************************

Confirmer is a jQuery plugin which provides an alternative to
confirmation dialog boxes and "check this checkbox to confirm action"
widgets. It acts by modifying a button to require two clicks within
a certain time, with the second click acting as a confirmation of
the first. If the second click does not come within a specified
timeout then the action is not confirmed.

Usage:

<button id='MyButton'></button>

$('#MyButton').initConfirmer({options});

Options:

	.initialText = initial text of the element.
	There is no default value.

	.confirmText = text to show when in "confirm mode".
	Default=("Confirm: "+initialText), or something similar.

	.timeout = Number of milliseconds to wait for confirmation.
	Default=3000.

	.onconfirm = function to call when clicked in confirm mode.
	Default = null. The function is passed a jQuery object
	wrapping the HTML element to which the countdown applies.

	.ontimeout = function to call when confirm is not issued.
	Default = null. The function is passed a jQuery object
	wrapping the HTML element to which the countdown applies.

	.onactivate = function to call when item is clicked, but only
	if the item is not currently in countdown mode. This is
	called (and must return) before the countdown starts. The
	function is passed a jQuery object wrapping the HTML element
	to which the countdown applies.

	.classInitial = optional CSS class string (default='') which
	is added to the element during it's "initial" state (the state
	it is in when it is not waiting on a timeout). When the target
	is activated (waiting on a timeout) this class is removed.
	In the case of a timeout, this class is added *before* the
	.ontimeout handler is called.

	.classActivated = optional CSS class string (default='') which
	is added to the target when it is waiting on a timeout. When
	the target leaves timeout-wait mode, this class is removed.
	When timeout-wait mode is entered, this class is added *before*
	the .onactivate handler is called.


Due to the nature of multi-threaded code, it is potentially possible
that confirmation and timeout actions BOTH happen if the user triggers
the associated action at "just the right millisecond" before the timeout
is triggered.

Potential TODOs:

- Add support for non-BUTTON elements. In theory, any element for which
a click(handler) and html("some text") is valid can be used, but in
practice some elements (e.g. IMG) won't work gracefully with the current
code.

- Add optional generic support for UI effects like blinking the button.
This requires additional plugins, though. It can currently be implemented
client-side via the .onactivate/.ontimeout/.onconfirm handlers.

- This thing probably has far more code than it really needs. See what
we can strip out.

- Idea from Michael Geary: to foil habitual double-clickers, do not go
into confirm-mode immediately, but instead disable the element and
re-enable it after a delay of 500ms or so. i added this feature but it
was too flaky, so i removed it. In any case, it's only really usable
for Buttons (and other elements which have a useful disabled=true
state).

- Add tick:{interval:int,function(target){...}} option to trigger
a callback every N milliseconds. The main intention would be
allowing the user to update the visual of his element (e.g. add
a countdown timer). A problem with this is a very real possibility
of colliding with the timeout triggers, e.g. re-updating the UI
after the confirm or cancel triggers have fired.


////////////////////////////////////////////////////////////////////////
   Confirmer home page:

   http://wanderinghorse.net/computing/javascript/jquery/confirmer/

   License: Public Domain

   Author: stephan beal (http://wanderinghorse.net/home/stephan/)

   Terse revision history (newest at the top):

   20070724:
   - initConfirm() no longer attaches new properties to 'this', as that
   may cause collisions with jQuery properties.
   - Internally uses cancelTimeout() to cancel a timeout.
   - Added Felix Geisendörfer's idea: options classInitial and
   classActivated.

   20070717: initial release
************************************************************************/

jQuery.fn.initConfirmer = function(opts) {
	if( ! opts ) { opts = []; }
	opts = jQuery.extend({
		initialText:"PLEASE SET .initialText='Button Label'",
		confirmText:"Confirm: "+opts.initialText,
		timeout:3000,
		onconfirm:null,
		ontimeout:null,
		onactivate:null,
		classInitial:'',
		classActivated:'',
		debuggering:false
	}, opts);
	/** Internal debuggering function. */
	var dbgdiv = null;
	function dbg(msg) { if( dbgdiv ) dbgdiv.prepend("Confirmer debug: "+msg+"<br/>"); };
	if( opts.debuggering ) {
		this.after("<div id='ConfirmerDebugDiv'>Confirmer debugging area</div>");
		dbgdiv = jQuery('#ConfirmerDebugDiv');
		dbgdiv.css('border','1px dashed #000');
		dbg("debugging activated.");
	}

	/* Internal data holder class. */
	function ConfirmHolder(target,opts) {
		var me = this;
		me.target = target;
		me.opts = opts;
		me.timerID = null;
		var states = { initial:0,waiting:1 };
		me.state = states.initial;
		me.target.html(me.opts.initialText);

		me.setClasses = function(activated) {
			if( activated ) {
				if( me.opts.classActivated ) {
					me.target.addClass( me.opts.classActivated );
				}
				if( me.opts.classInitial ) {
					me.target.removeClass( me.opts.classInitial );
				}
			} else {
				if( me.opts.classInitial ) {
					me.target.addClass( me.opts.classInitial );
				}
				if( me.opts.classActivated ) {
					me.target.removeClass( me.opts.classActivated );
				}
			}
		}
		me.setClasses( false );
		me.doTimeout = function() {
			me.timerID = null;
			if( me.state != states.waiting ) {
				// it was already confirmed
				return;
			}
			me.setClasses( false );
			me.state = states.initial;
			dbg("Timeout triggered.");
			me.target.html(me.opts.initialText);
			if( me.opts.ontimeout ) {
				me.opts.ontimeout(me.target);
			}
		};
		me.target.click( function() {
			switch( me.state ) {
				case( states.waiting ):
					if( null !== me.timerID ) clearTimeout( me.timerID );
					me.state = states.initial;
					me.setClasses( false );
					dbg("Confirmed");
					me.target.html(me.opts.initialText);
					if( me.opts.onconfirm ) me.opts.onconfirm(me.target);
					break;
				case( states.initial ):
					me.setClasses( true );
					if( me.opts.onactivate ) me.opts.onactivate( me.target );
					me.state = states.waiting;
					dbg("Waiting "+me.opts.timeout+"ms on confirmation...");
					me.target.html( me.opts.confirmText );
					me.timerID = setTimeout(function(){me.doTimeout();},me.opts.timeout );
					break;
				default: // can't happen.
					break;
			};
		});
	};
	var holder = new ConfirmHolder(this,opts);
	return this;
}; // initConfirmer()
