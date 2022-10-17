/* http://remysharp.com/2007/03/19/a-few-more-jquery-plugins-crop-labelover-and-pluck/#labelOver
 DIV { position: relative; float: left; }
LABEL.over-apply { color: #ccc; position: absolute; top: 5px; left: 5px;}
*/


jQuery.fn.labelOver = function(overClass) {
	return this.each(function(){
		var label = jQuery(this);
		var f = label.attr('for');
		if (f) {
			var input = jQuery('#' + f);
			
			this.hide = function() {
			  label.css({ textIndent: -10000 })
			}
			
			this.show = function() {
			  if (input.val() == '') label.css({ textIndent: 0 })
			}

			// handlers
			input.focus(this.hide);
			input.blur(this.show);
		  label.addClass(overClass).click(function(){ input.focus() });
			
			if (input.val() != '') this.hide(); 
		}
	})
}
