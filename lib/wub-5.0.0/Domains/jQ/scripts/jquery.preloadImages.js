/*
 * jQuery preloadImages plugin
 * Version 0.1.1  (20/12/2007)
 * @requires jQuery v1.2.1+
 *
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 * @name preloadImages
 * @type jQuery
 * @cat Plugins/Browser Tweaks
 * @author Blair McBride <blair@theunfocused.net>
*/

(function($) {
/**
*
* Queue up a list of images, and start preloading them.
* Works with multi-dimensional arrays.
*
* @example $.preloadImages(['1.jpg', '2.jpg', '3.jpg']);
* @example $.preloadImages(['1.jpg', '2.jpg', '3.jpg', ['4.jpg', '5.jpg']]);
*
* @param arr Any number of image URLs to preload, in an array.
*/
$.preloadImages = function(arr) {
	$.preloadImages.add(arr);

	queuedStop = false;
	startPreloading();
};




/**
* Add a list of images to the end of the preload queue.
* Does not start precoessing the queue, unlike $.preloadImages()
* Works with multi-dimensional arrays.
*
* @example $.preloadImages.add(['1.jpg', '2.jpg', '3.jpg']);
* @example $.preloadImages.add(['1.jpg', '2.jpg', '3.jpg', ['4.jpg', '5.jpg']]);
*
* @param arr Any number of image URLs to preload, either as individual arguments or in an array.
*/
$.preloadImages.add = function(arr) {
	if(typeof(arr) == 'string') {
		$.preloadImages.imageQueue.push(arr);
		return;
	}

	if(arr.length < 1) return;

	for(var i = 0, numimgs = arr.length; i < numimgs; i++) {
		if(typeof(arr[i]) == 'string')
			$.preloadImages.imageQueue.push(arr[i]);
		else if(typeof(arr[i]) == 'object' && arr[i].length > 0)
			$.preloadImages.add(arr[i]);
	}
}

/**
* Prepend a list of images to the start of the preload queue.
* Does not start precoessing the queue, unlike $.preloadImages()
* Works with multi-dimensional arrays.
*
* @example $.preloadImages.add('1.jpg', '2.jpg', '3.jpg');
* @example $.preloadImages.add(['1.jpg', '2.jpg', '3.jpg'], ['4.jpg', '5.jpg']);
*
* @param Any number of image URLs to preload, either as individual arguments or in an array.
*/
$.preloadImages.prepend = function() {
	if(typeof(arr) == 'string') {
		$.preloadImages.imageQueue.unshift(arr);
		return;
	}

	if(arr.length < 1) return;

	for(var i = numargs - 1; i >= 0; i--) {
		if(typeof(arr[i]) == 'string')
			$.preloadImages.imageQueue.unshift(arr[i]);
		else if(typeof(arr[i]) == 'object' && arr[i].length > 0)
			$.preloadImages.prepend(arr[i]);
	}
}

/**
* Clear the preload queue.
*/
$.preloadImages.clear = function() {
	$.preloadImages.imageQueue = [];	
}

/**
* Stop processing the preload queue. Does not clear the queue, so precessing can be started off from where it was stopped.
*/
$.preloadImages.stop = function() {
	queuedStop = true;
}

/**
* Start processing the preload queue.
*/
$.preloadImages.start = function() {
	queuedStop = false;
	startPreloading();
}

/**
* The preload queue, for direct manupilation of the queue.
* Items at the start of the queue will be processed first.
* This needs to be kept single-dimensional.
*/
$.preloadImages.imageQueue = [];



/* PRIVATE */
var isPreloading = false;
var queuedStop = false;

function startPreloading() {
	if(isPreloading)
		return;

	$(document.createElement('img')).bind('load', function() {
		if(queuedStop) {
			queuedStop = isPreloading = false;
			return;
		}
		isPreloading = true;
		if($.preloadImages.imageQueue.length > 0) {
			this.src = $.preloadImages.imageQueue.shift();
		} else
			isPreloading = false;
	}).trigger('load');
}


})(jQuery);
