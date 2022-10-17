/* 
	jQuery HoverImageText plugin
	Created on 16th January 2008 by Ryan O'Dell 
	Version 1
	
	Configurable variables: usage: $.fn.HoverImageText.defaults.<variable_name> = <value>;
	AnimShow 				= {opacity: "show"}		show animation (allows custom jQuery animation)
	AnimShowCallback			= null				show animation function callback
	HoverCheck				= 600				show mouse hover check/delay time (ms)
	HoverIn				= 500				show animation time (ms)
	AnimHide				= {opacity: "hide"}		hide animation (allows custom jQuery animation)
	AnimHideCallback			= null				hide animation function callback
	HoverOut				= 300				hide animation time (ms)
	TagName				= 'p'				tag name to find hover text

	Example usage:
	$(document).ready(function() {
		$.fn.HoverImageText.defaults.AnimShow = {height: "show"};
		$('.imageLibrary a').HoverImageText();
	});
*/
(function($) {
	/* HoverImageText plugin */
	$.fn.HoverImageText = function() {
		var opts = $.fn.HoverImageText.defaults;
		return this.each(function() {
			var oText = $(this).children(opts.TagName);
			oText = oText.hide();
			var oImg = $(this).hover(function() {
					oHover = oText;
					window.setTimeout(function() {
						HoverCheckAndShow(oText);
					}, opts.HoverCheck);
				}, function() {
					oHover = null;
					oText.animate(opts.AnimHide, opts.HoverOut, opts.AnimHideCallback);
				});
		});
	};
	/* Available options*/
	$.fn.HoverImageText.defaults = {
			AnimShow: {opacity: "show"},
			AnimShowCallback: null,
			HoverCheck: 600,
			HoverIn: 500,
			AnimHide: {opacity: "hide"},
			AnimHideCallback: null,
			HoverOut: 300,
			TagName: 'p'
	};
	/* private function "HoverCheckAndShow" adds a delay before displaying hover text */
	function HoverCheckAndShow(oText) {
		var opts = $.fn.HoverImageText.defaults;
		if (oHover == oText) {
			oText.animate(opts.AnimShow, opts.HoverIn, function() { 
					this.style.display = "inline";
					if (typeof(opts.AnimShowCallback) == 'function') {
						opts.AnimShowCallback();
					}
				});
			oText.each(function() {
					this.style.display = "inline";
				});
			if ($.browser.msie) {
				oText.each(function() {
						var oThis = this;
						window.setTimeout(function() {
							oThis.style.filter = "progid:DXImageTransform.Microsoft.Alpha(opacity=80)";
							}, opts.HoverIn-260);
					});
			}
		}
		return oText;
	};
	/* private variable "oHover" used to determine if you're still hovering over the same element */
	var oHover = null;
	/* *** update the '$.fx.prototype.update' function replacing the "block" for "inline" *** */
	$.fx.prototype.update = function() {
		if ( this.options.step )
			this.options.step.apply( this.elem, [ this.now, this ] );

		(jQuery.fx.step[this.prop] || jQuery.fx.step._default)( this );

		// Set display property to block for height/width animations
		if ( this.prop == "height" || this.prop == "width" )
			this.elem.style.display = "inline";
	};
})(jQuery);
