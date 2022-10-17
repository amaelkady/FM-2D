/* jQuery Password Strength Plugin (PStrength) - A jQuery plugin to provide accessibility functions
 * Author: Tane Piper (digitalspaghetti@gmail.com) 
 * Website: http://digitalspaghetti.me.uk
 * Licensed under the MIT License: http://www.opensource.org/licenses/mit-license.php
 * This code uses a modified version of Steve Moitozo's algorithm (http://www.geekwisdom.com/dyn/passwdmeter)
 * 
 * === Changelog ===
 * Version 1.3 (02/01/2008)
 * Changing coding style to more OO
 * Added default messages object for i18n
 * Changed password length score to Math.pow (thanks to Keith Mashinter for this suggestion)
 * Version 1.2 (03/09/2007)
 * Added more options for colors and common words
 * Added common words checked to see if words like 'password' or 'qwerty' are being entered
 * Added minimum characters required for password
 * Re-worked scoring system to give better results
 * 
 * Version 1.1 (20/08/2007)
 * Changed code to be more jQuery-like
 * 
 * Version 1.0 (20/07/2007)
 * Initial version.
 */
(function($){
	
	$.PStrength = $.PStrength || {}
	
	// Create object containing project details
	$.PStrength.codedetails = {
		version: "1.3b",
		author: "Tane Piper <digitalspaghetti@gmail.com>",
		blog: "http://digitalspaghetti.me.uk",
		repository: "http://hg.digitalspaghetti.me.uk/jmaps",
		googleGroup: "http://groups.google.com/group/jmaps",
		licenceType: "MIT",
		licenceURL: "http://www.opensource.org/licenses/mit-license.php"
	};
	
	$.PStrength.messages = {
		en : {
			mMinChar : "The minimum number of characters is"	
		},
		nl : {
			mMinChar : "Het minimumaantal karakters is"	
		},
		fr : {
			mMinChar : "Le nombre minimum de caractères est"
		},
		de : {
			mMinChar : "Die Mindestzahl der Buchstaben ist"	
		}
	}
	
	/**
	* $.fn.PStrength.defaults
	* These are the default values that can be overidden
	*/
	$.PStrength.defaults = {
		language:	'en',
		verdicts:	["Very Weak","Weak","Medium","Strong","Very Strong"],
		colors: 	["#f00","#c06", "#f60","#3c0","#3f0"],
		scores: 	[10,15,30,40],
		pow_max: 	1.4,
		common:		["password","sex","god","123456","123","liverpool","letmein","qwerty","monkey"],
		minchar:	6,
		displayMin: true
	};
	
	/** @name pstrength
	* @var mixed options An object of options
	* @returns object jQuery Returns the output to the screen 
	*/
	$.PStrength.init = function(el, options) {
		// Take the passed options and merge with default options
		var options = $.extend({}, $.PStrength.defaults, options);
		// Main logic
		// Check to see if any options have been attached as expandos
		var o = $.meta ? $.extend({}, options, $(el).data()) : options;
		// Get the ID of the password field
		var infoarea = $(el).attr('id');
		// Check to see if we should display the minimum number of characters
		if (o.displayMin) {
			$(el).after('<div class="pstrength-minchar" id="' + infoarea + '_minchar">' +  $.PStrength.messages[$.PStrength.defaults.language].mMinChar +' '+ o.minchar + '</div>');
		}
		// Add in the text to show the bar and text
		$(el).after('<div class="pstrength-info" id="' + infoarea + '_text"></div>');
		$(el).after('<div class="pstrength-bar" id="' + infoarea + '_bar" style="border: 1px solid white; font-size: 1px; height: 2px; width: 0px;"></div>');

		// Check the password on each KeyUp
		$(el).keyup(function(){				
			$.PStrength.runPassword($(this).val(), infoarea, o);
		});
	};
		
	$.PStrength.runPassword = function (password, infoarea, options){
       	// Check password
		nPerc = $.PStrength.checkPassword(password, options);
		// Get controls
	   	var ctlBar = "#" + infoarea + "_bar"; 
	   	var ctlText = "#" + infoarea + "_text";		
		// Color and text
		if (nPerc == -200) {
			strColor = '#f00';
			strText = 'Unsafe Password Word!';
			$(ctlBar).css({width: "0%"});
		}		
		else if (nPerc < 0 && nPerc > -199) {
			strColor = '#ccc';
			strText = 'Too Short';
			$(ctlBar).css({width: "1%"});
		}
		else if(nPerc <= options.scores[0])
		{
	   	strColor = options.colors[0];
			strText = options.verdicts[0];
			$(ctlBar).css({width: "1%"});
		}
		else if (nPerc > options.scores[0] && nPerc <= options.scores[1])
		{
	   	strColor = options.colors[1];
			strText = options.verdicts[1];
			$(ctlBar).css({width: "25%"});
		}
		else if (nPerc > options.scores[1] && nPerc <= options.scores[2])
		{
		  strColor = options.colors[2];
			strText = options.verdicts[2];
			$(ctlBar).css({width: "50%"});
		}
		else if (nPerc > options.scores[2] && nPerc <= options.scores[3])
		{
		  strColor = options.colors[3];
			strText = options.verdicts[3];
			$(ctlBar).css({width: "75%"});
		}
		else
		{
		  strColor = options.colors[4];
			strText = options.verdicts[4];
			$(ctlBar).css({width: "99%"});
		}
		$(ctlBar).css({backgroundColor: strColor});
		$(ctlText).html("<span style='color: " + strColor + ";'>" + strText + "</span>");
	}
		
	$.PStrength.checkPassword = function(p, o)
	{
		var intScore = 0;
		// PASSWORD LENGTH
		intScore = Math.pow(p.length, o.pow_max);
		if (p.length < o.minchar)                         // Password too short
		{
			intScore = (intScore - 100)
		}
		// CHARACTER CLASSES
		if (p.match(/[a-z]/)) intScore += 1;
		if (p.match(/[A-Z]/)) intScore += 5;
		if (p.match(/\d+/)) intScore += 5;
		if (p.match(/(.*[0-9].*[0-9].*[0-9])/)) intScore += 5;
		if (p.match(/.[!,@,#,$,%,^,&,*,?,_,~]/)) intScore += 5;
		if (p.match(/(.*[!,@,#,$,%,^,&,*,?,_,~].*[!,@,#,$,%,^,&,*,?,_,~])/)) intScore += 5;
		if (p.match(/([a-z].*[A-Z])|([A-Z].*[a-z])/)) intScore += 2;
		if (p.match(/([a-zA-Z])/) && p.match(/([0-9])/)) intScore += 2;
		if (p.match(/([a-zA-Z0-9].*[!,@,#,$,%,^,&,*,?,_,~])|([!,@,#,$,%,^,&,*,?,_,~].*[a-zA-Z0-9])/)) intScore += 2;
		
		for (var i=0; i < o.common.length; i++) {
			if (p.toLowerCase() == o.common[i]) {
				intScore = -200;
			}
		}
		return intScore;
	}
		
	$.fn.pstrength = function(options) {
		return this.each(function(){
			new $.PStrength.init(this, options);
	 	});
	}
	
})(jQuery);
