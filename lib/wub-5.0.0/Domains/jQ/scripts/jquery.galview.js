/**
 * jQuery jqGalView Plugin
 * Examples and documentation at: http://benjaminsterling.com/2007/08/24/jquery-jqgalview-photo-gallery/
 * This is a port of http://www.flashimagegallery.com/pics/artwork/
 *
 * @author: Benjamin Sterling
 * @version: 2.0.1
 * @copyright (c) 2007 Benjamin Sterling, KenzoMedia
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *   
 * @requires jQuery v1.1.3.1 or later
 * @optional jQuery Easing v1.1.1
 * @optional jQuery jqModal v2007.08.17 +r11
 * 
 * 
 * @name jqGalView
 * @example $('ul').jqGalView();
 * 
 * @Semantic requirements:
 * 				The structure fairly simple and should be unobtrusive, you
 * 				basically only need a parent container with a title 
 * 				attribute and a list of imgs
 * 
 * 	<ul title="My Gallery" id="gallery">
 *		<li><img src="common/img/dsc_0003.thumbnail.JPG"/></li>
 *		<li><img src="common/img/dsc_0012.thumbnail.JPG"/></li>
 *	</ul>
 *
 *  -: or :-
 * 
 * <div title="My Gallery" id="gallery">
 * 		<img src="common/img/dsc_0003.thumbnail.JPG"/>
 * 		<img src="common/img/dsc_0012.thumbnail.JPG"/>
 * </div>
 * 
 * @param Integer getUrlBy
 * 					By default, it is set to 0 (zero) and the plugin will
 * 					get the url of the full size img from the images 
 * 					parent A tag, or you can set it to 1 will and provide
 * 					the fullSizePath param with the path to the full size
 * 					images.  Finally, you can set it to 2 and provide text
 * 					to prefix param and have that prefix removed from the
 * 					src tag of the thumbnail to create the path to the
 * 					full sized image
 * 
 * @example $('#gallery').jqGalView({getUrlBy:1,fullSizePath:'fullPath/to/fullsize/folder'});
 * 
 * @example $('#gallery').jqGalView({getUrlBy:2, prefix:'.tn'});
 * 					".tn" gets removed from the src attribute of your image
 * 
 * @param String fullSizePath
 * 					Set to null by default, but if you are going to set
 * 					getUrlBy param to 1, you need to provide the full path
 * 					to the full size image.
 * 
 * @example $('#gallery').jqGalView({getUrlBy:1,fullSizePath:'fullPath/to/fullsize/folder'});
 * 
 * @param String prefix
 * 					Set to null by default, but if you are going to set
 * 					getUrlBy param to 2, you need to provide text you
 * 					want to remove from the src attribute of the thumbnail
 * 					to get create the full size image name
 * 
 * @example $('ul').jqGalView({getUrlBy:2, prefix:'.tn'});
 * 					".tn" gets removed from the src attribute of your image
 * 
 * @param Integer items
 * 					Set to 20 by default, and will set the plugin to show
 * 					20 thumbnails (or what ever number you want) at a time
 * 
 * @example $('#gallery').jqGalView({items:50});
 * 
 * @param String openTxt
 * 					The text you want to have shown when you hover over a
 * 					thumbnail
 * 
 * @example $('#gallery').jqGalView({openTxt:"Open Me"});
 * 
 * @param String backTxt
 * 					The text that gets append to the full images title
 * 					attribute to give a hint for the user to click to
 * 					return to the thumbnails
 * 
 * @example $('#gallery').jqGalView({backTxt:"Close Me"});
 * 
 * @param String goFullSizeTxt
 * 					The text that gets appended after the alt text when
 * 					the full sized image is being view and will allow the
 * 					user to view the resized full image in a new browser
 * 					window or in the modal box
 * 
 * @example $('#gallery').jqGalView({goFullSizeTxt:"See full sized unresized"});
 * 
 * @param String tnease
 * 					Set to null by default and will need the easing plugin
 * 					if set otherwise and will add easing to the thumbnail
 * 					scrolling
 * 
 * @see http://gsgd.co.uk/sandbox/jquery.easing.php
 * 
 * @example $('#gallery').jqGalView({tnease:"easein"});
 * 
 * @param String title
 * 					Set to null by default and will allow you to add a
 * 					title to gallery if not already set in a title tag
 * 					of the parent element of the thumbnail group
 * 					eg. <ul title="this is title">
 * 
 * @example $('#gallery').jqGalView({title:"This is a title for my gallery"});
 * 
 * @param String headerElements
 * 					By default, this param is set to 
 * 					<div class="gvHeader">%t</div> with the %t being 
 * 					required to append the title to the gallery.  You will
 * 					be able to passing any dom structure you need to
 * 					achieve a specific design you are expecting for your
 * 					gallery header.
 * 
 * @example $('#gallery').jqGalView({headerElements:"<div class="gvHeader"><div class="left"></div><div class="middle">%t</div><div class="right"></div></div>"});
 * 
 * @styleClasses
 * 		gvHeader:  Main header
 * 		gvContainer:  overall holder of thumbnails and gvHolder div, the
 * 						gvLoader div and the gvImgContainer div
 * 		gvHolder: contains the thumbnails divs
 *		gvItem: contains the thumbnail img, the gvLoaderMini div and the gvOpen div
 *		gvLoaderMini :empty but styled with a loader images as background image.
 * 		gvOpen: contains the open text
 * 		gvImgContainer: the full size image container and the gvDescText div
 * 		gvDescText: contains the alt text for the image and the open full 
 * 						size text
 * 		gvLoader: empty but styled with a loader images as background image.
 * 		gvFooter: contains the pagination links
 * 		gvLinks: contains the actual links
 * 
 * 
 * changes:
 *	09/26/2007
 *		Fixed: Changed this.altImg = $this.src.replace(item.opts.prefix,”); to
 *				this.altImg = this.src.replace(el.opts.prefix,”); thanks to jurrie
 *				@ jurrie.net for finding this error
 *	09/24/2007
 *		Added: a title param so that you can either pass in a title param or put a
 *				title attribute on the parent element.
 *		Added: grabbing the alt tag and showing the text in the large image
 *		Removed:  javascript styling in favor for css styling. eg. cursor:pointer, display:none
 *		Removed:  Scrolling availablity in favor of being able to open the image in own window
 *		Added: a headerElements param to allow for custom header styling
 *		Removed:  the need for appendTo param in favor of a "hot swap"
 *
 *	09/20/2007:
 *		Added: Some extra stylable elements to allow for a better styling of the gallery
 *		Added: A picasa fix for larger images
 *
 *	09/12/2007:
 *		Improvements: Some very minor adjustments to the code for speed improvement.
 *
 *	08/28/2007:
 *		Added: option to have full image to open in jqModal (jqModal plugin required)
 *		Fixed: ie7 issue with margin-left and margin-top not being set
 *		Fixed: ie7 issue with "open" not being clickable
 *
 *	08/27/2007:
 *		Added: option to turn scroll off (larger image mouseover)
 *		Added: image resizing for when the scroll is turned off (borrowed from thickbox)
 *		Added: option to change the thumbnail scroll easing (easing plugin required)
 *		Added/Changed: option to ease the "open" dialog into view
 *		Added: a switch to the navigation to check if larger image is visible and if
 *				so, fade that out and the scroll the thumbnails to their respective
 *				view
 *		Added: some function globals to eleviate some duplicate code (not sure if this
 *				is good practise)
 *		Fixed: Clickablity of the "open" dialog
 *		Removed: "go back" dialog box (the thing that was following the mouse)
 *		Added: "go back" option text to title attibute of the large image
 *		Added:  a loading bar (image borrowed from thickbox)
 *		Added:  image fadeIn and fadeOut when loading and closing
 *
 */
(function($){
	$.fn.jqGalView = function(options){
		return this.each(function(){
			var el = this, $_ = $(this); $img = $('img', $_);
			el.opts = $.extend({}, $.fn.jqGalView.defaults, options);
			var title = $_.attr('title') ? $_.attr('title') : el.opts.title;
			el.opts.title = title;
			
			//  swap out current image gallery for jqGalView structure
			var $this = $.fn.jqGalView.swapOut($_);
			
			//  Build our header
			var $header = $(el.opts.headerElements.replace(/%t/g,'<span>'+el.opts.title+'</span>')).appendTo($this);
			
			var $container = $('<div class="gvContainer">').appendTo($this);
			//  Build our holder for the thumbnail images
			var $holder = $('<div class="gvHolder"/>').appendTo($container);

			$img.each(function(i){
				var $el = $(this);

				var $div = $('<div id="gvID'+i+'" class="gvItem">').appendTo($holder).append('<div class="gvLoaderMini">')
				.hover(
					function(){
						$div.children('.gvOpen').stop().animate({top:0},'fast', el.opts.ease);
					},
					function(){
						$div.children('.gvOpen').stop().animate({top:-16},'fast', el.opts.ease);
					}
				);
				var image = new Image();
				image.onload = function(){
					image.onload = null;
					if(el.opts.getUrlBy == 0)
						this.altImg = $el.parent().attr('href');
					else if(el.opts.getUrlBy == 1)
						this.altImg = el.opts.fullSizePath + this.src.split('/').pop();
					else if(el.opts.getUrlBy == 2)
						this.altImg = $this.src.replace(el.opts.prefix,'');
	
					this.altTxt = $el.attr('alt');
					$div.empty().append(this).css('cursor','pointer');
					$('<div class="gvOpen">'+el.opts.openTxt+'</div>').appendTo($div).css({top:-16,opacity:".75"})
					.click(
						function(){
							$el.trigger('click');
						}
					);
					$(this)
					.click(
						function(){
							$.fn.jqGalView.view(this,el);
						}
					);
				};
				image.src = this.src;
			});
			
			var $footer = $('<div class="gvLinks">').appendTo($('<div class="gvFooter">').appendTo($this));
			el.mainImgContainer = $('<div class="gvImgContainer">').appendTo($container);
			el.image = $('<img/>').appendTo(el.mainImgContainer);
			el.descTxt = $('<div class="gvDescText"/>').appendTo(el.mainImgContainer);
			el.loader = $('<div class="gvLoader"/>').appendTo($container);
			
			for(var i = 0; i < $img.size()/el.opts.items; i++){
				$('<a href="#'+(i)+'">'+(i+1)+'</a>').appendTo($footer)
					.click(function(){
						var $l = $(this);
						var index = $l.attr('href').replace(/^.*#/, '')

						if(el.image.is(":hidden")){
							$holder.animate({marginTop:-(el.mainImgContainer.height()*index)},'1000', el.opts.tnease);
						}
						else{
							el.mainImgContainer.fadeOut(100).unbind();
							el.image.fadeOut(100,function(){$holder.animate({marginTop:-(el.mainImgContainer.height()*index)},'1000', el.opts.tnease);});
						}
						
						
						return false;
					});	
			};

			//  remove current images and replace with jqGalview
			$(this).after($this).remove();
		});
	};//  end: $.fn.jqGalView
	
	$.fn.jqGalView.view = function(img,el){
		if(typeof img.altImg == 'undefined') return false;
		var url = /\?imgmax/.test(img.altImg) ? img.altImg : img.altImg+'?imgmax=800';
		var $i_wh = {}; // 
		var $i_whFinal = {}; // 
		var wContainer, hContainer;
		var $w, $h, $wOrg, $hOrg, isOver = false; 

		el.loader.show();
		wContainer = el.mainImgContainer.width();
		hContainer = el.mainImgContainer.height();
		el.mainImgContainer.show();
		
		el.image.attr({src:url,title:el.opts.backTxt}).css({top:0,left:0,position:'absolute'}).hide();
		var a = $('<a href="#" target="_blank" class="gvFullSizeText">'+el.opts.goFullSizeTxt+'</a>');
		
		a.attr('href',url);
		var txt = img.altTxt ? img.altTxt +' : ' : '';
		el.descTxt.empty().append(txt).append(a);
		
		$img = new Image();
		$img.onload = function(){
			$img.onload = null;
			$w = $wOrg = $img.width;
			$h = $hOrg = $img.height;

			if ($w > wContainer) {
				$h = $h * (wContainer / $w); 
				$w = wContainer; 
				if ($h > wContainer) { 
					$w = $w * (hContainer / $h); 
					$h = hContainer; 
				}
			} else if ($h > hContainer) { 
				$w = $w * (hContainer / $h); 
				$h = hContainer; 
				if ($w > wContainer) { 
					$h = $h * (wContainer / $w); 
					$w = wContainer;
				}
			}
			el.image.css({width:$w,height:$h, marginLeft:(wContainer-$w)*.5,marginTop:(hContainer-$h)*.5})
			.click(function(e){
				el.mainImgContainer.fadeOut().unbind();
				el.image.fadeOut();
				a.unbind();
				el.image.attr({src:''}).hide();
			});
			if(el.opts.modal && typeof $.fn.jqm == 'function'){
				a.click(function(){
					$.fn.jqGalView.buildDialogBox(this.href,$wOrg,$hOrg);
					return false;
				});
			};
			el.loader.fadeOut('fast',function(){el.image.fadeIn(function(){el.descTxt.fadeIn();});});
		};
		$img.src = url;
		
	};
	$.fn.jqGalView.buildDialogBox = function($url, imageWidth, imageHeight){
		
		$('#gvModal').remove();
		$gvModal = $('<div id="gvModal" class="jqmWindow">').appendTo('body');

		//	borrowed from thickbox
		var de = document.documentElement;
		var w = window.innerWidth || self.innerWidth || (de&&de.clientWidth) || document.body.clientWidth;
		var h = window.innerHeight || self.innerHeight || (de&&de.clientHeight) || document.body.clientHeight;
		
		var x = w - 150;
		var y = h - 150;
		if (imageWidth > x) {
			imageHeight = imageHeight * (x / imageWidth); 
			imageWidth = x; 
			if (imageHeight > y) { 
				imageWidth = imageWidth * (y / imageHeight); 
				imageHeight = y; 
			}
		} else if (imageHeight > y) { 
			imageWidth = imageWidth * (y / imageHeight); 
			imageHeight = y; 
			if (imageWidth > x) { 
				imageHeight = imageHeight * (x / imageWidth); 
				imageWidth = x;
			}
		}
		// End Resizing
	
		var $img = $('<img src="'+$url+'"/>').appendTo($gvModal).css({width:imageWidth,height:imageHeight,padding:0});
		$('#gvModal').jqm({zIndex:5000,modal:false,overlay:50,
			onHide: function(hash, serial){
				hash.o.remove();
				hash.w.remove();
			},
			onShow: function(hash){
				hash.w.fadeIn('slow',function(){$img.fadeIn();});
			}
		}).css({marginLeft: '-' + parseInt(((imageWidth+20) / 2),10) + 'px', width: (imageWidth+20) + 'px',marginTop: '-' + parseInt(((imageHeight+20) / 2),10) + 'px'}).jqmShow(); 
	};
	$.fn.jqGalView.swapOut = function($el){
		var id = $el.attr('id') ? (' id="'+$el.attr('id')+'"') : '';
		var $this = $('<div' + id + '>');
		return $this;
	};
	
	$.fn.jqGalView.defaults = {
		getUrlBy : 0, // 0 == from parent A tag | 1 == the full size resides in another folder
		fullSizePath : null,
		prefix: 'thumbnail.',
		items: 20,
		openTxt:'open&raquo; ',
		backTxt:'<< Click to go back',
		goFullSizeTxt: 'Full Size',
		tnease:null,
		modal : false,
		title : null,
		headerElements : '<div class="gvHeader">%t</div>'
	};
})(jQuery);
 