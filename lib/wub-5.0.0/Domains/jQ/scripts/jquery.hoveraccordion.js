/**
* HoverAccordion - jQuery plugin for intuitively opening accordions and menus
* http://berndmatzner.de/jquery/hoveraccordion/
* Copyright (c) 2007 Bernd Matzner
* Dual licensed under the MIT and GPL licenses:
* http://www.opensource.org/licenses/mit-license.php
* http://www.gnu.org/licenses/gpl.html
* Requires jQuery 1.2.1 or higher
* Version: 0.4.3
*
* Usage:
* $('#YourUnorderedListID').hoverAccordion();
* or
* $('.YourUnorderedListClass').hoverAccordion({
* 	speed: 'slow',
* 	activateitem: '1',
* 	active: 'current',
* 	header: 'title',
* 	hover: 'highlight',
* 	opened: 'arrowdown',
* 	closed: 'arrowup'
*   keepheight: 'true'
* });
*/

(function($)
{
	$.fn.hoverAccordion = function(options)
	{
		// Setup options
		options = jQuery.extend(
		{
			speed:          'fast',     // Speed at which the subitems open up - valid options are: slow, normal, fast
			activateitem:   'true',     // 'true': Automatically activate items with links corresponding to the current page, '2': Activate item #2
			active:         'active',   // Class name of the initially active element
			header:         'header',   // Class name for header items
			hover:          'hover',    // Class name for hover effect
			opened:         'opened',   // Class name for open header items
			closed:         'closed',   // Class name for closed header items
			keepheight:     'true'      // 'true': Set the height of each accordion item to the size of the largest one, 'false': Leave height as is
		}, options);

		// Current hover status
		thislist = this;

		// Current URL
		var thisurl = window.location.href;

		// Change display status of subitems when hovering
		function doHover(obj)
		{
			if($(obj).html() == undefined) obj = this;

			// Change only one display status at a time
			if(!thislist.is(':animated'))
			{
				var newelem = $(obj).parent().children('ul');
				var oldelem = $(obj).parent().parent().children('li').children('ul:visible');
				if(options.keepheight == 'true')
				{
					thisheight = maxheight;
				} else {
					thisheight = newelem.height();
				}

				// Change display status if not already open
				if(!newelem.is(':visible'))
				{
					if(!oldelem.length > 0)
					{
						newelem.animate(
						{
							height: thisheight
						},
						{
							duration: options.speed,
							easing: 'linear'
						});
					}
					else
					{
						newelem.show();
					}

					oldelem.animate(
					{
						height: 'hide'
					},
					{
						step: function(n, fx)
						{
							newelem.height(thisheight - n);
						},
						duration: options.speed,
						easing: 'linear'
					});

					// Switch classes for headers
					oldelem.parent().children('a').addClass(options.closed).removeClass(options.opened);
					newelem.parent().children('a').addClass(options.opened).removeClass(options.closed);
				}
			}
		};

		// Do nothing (necessary for the hoverIntent plugin)
		function doNothing()
		{
		};

		var itemNo = 0;
		var maxheight = 0;

		// Setup initial state and hover events
		$(this).children('li').each(function()
		{
			var thisitem = $(this);

			itemNo++;

			// Set current link to current URL to 'active' and disable anchor links
			var thislink = thisitem.children('a');

			if(thislink.length>0)
			{
				// Hover effect for all links
				thislink.hover(function()
				{
					$(this).addClass(options.hover);
				}, function()
				{
					$(this).removeClass(options.hover);
				});

				var thishref = thislink.attr('href');

				if(thishref == '#')
				{
					// Add a click event if the header does not contain a link
					thislink.click(function() {
						doHover(this);
						this.blur();
						return false;
					});
				}
				else if(options.activateitem == 'true' && thisurl.indexOf(thishref)>0 && thisurl.length-thisurl.lastIndexOf(thishref) == thishref.length)
				{
					thislink.parent().addClass(options.active);
				}
			}

			var thischild = thisitem.children('ul');

			// Initialize subitems
			if(thischild.length > 0)
			{
				if(maxheight < thischild.height()) maxheight = thischild.height();

				// Change appearance of the header element of the active item
				thischild.children('li.'+options.active).parent().parent().children('a').addClass(options.header);

				// Bind hover events to all subitems
				try
				{
					// If Brian Cherne's 'hoverIntent' plugin is available, use it for safe hovering
					thislink.hoverIntent(
					{
						sensitivity: 1,
						interval: 80,
						over: doHover,
						timeout: 600,
						out: doNothing
					});
				}
				catch(err)
				{
					// Regular hover function if hoverIntent isn't available
					thislink.hover(function()
					{
						doHover(this);
					}, function()
					{
						doNothing();
					});
				}

				// Set current link to current URL to 'active'
				if(options.activateitem == 'true')
				{
					thischild.children('li').each(function()
					{
						var m = $(this).children('a').attr('href');
						if(m)
						{
							if(thisurl.indexOf(m) > 0 && thisurl.length-thisurl.lastIndexOf(m) == m.length)
							{
								$(this).addClass(options.active).parent().parent().children('a').addClass(options.opened);
							}
						}
					});
				}
				else if(parseInt(options.activateitem) == itemNo)
				{
					thisitem.addClass(options.active).children('a').addClass(options.opened);
				}
			}

			// Close all subitems except for those with active items
			thischild . not($(this).parent().children('li.'+options.active).children('ul')) . not(thischild.children('li.'+options.active).parent()) . hide() . parent().children('a') . addClass(options.closed);
		});

		return this;
	};
})(jQuery);