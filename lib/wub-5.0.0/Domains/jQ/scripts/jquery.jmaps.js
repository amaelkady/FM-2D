/* jQuery Maps (jmaps) - A jQuery plugin for Google Maps API
 * Author: Tane Piper (digitalspaghetti at gmail dot com) 
 * With special thanks Dave Cardwell (who helped on getting the first version of this plugin to work).
 * Website: http://code.google.com/p/jmaps/
 * Licensed under the MIT License: http://www.opensource.org/licenses/mit-license.php
 * This plugin is not affiliated with Google or Yahoo.  
 * For Google Maps API and T&C see http://www.google.com/apis/maps/
 * 
 * For support, I can usually be found on the #jquery IRC channel on irc.freenode.net
 * ===============================================================================================================
 * ^^^ Changelog ^^^
 * Version 1.5a (17/10/2007)
 * Removed all Yahoo code, quick test with API, needs more testing
 *===============================================================================================================
 * Version 1.4 (08/08/2007)
 * Added option to double click on map to add marker.  Single click on marker gives Lat/Lng details, while double click removes
 * Moved searchAddress and searchDirections back into main function, can now be called via .searchAddress and .searchDirections, removed options for fields to pass in data
 * Added support for new Google Ad's Manager for Maps.  Can be enabled with .mapAds()
 * Added callback in searchAddress to return as a map, or as an array of Lat/Lng
 * Added callback in addRss
 * Added passing in custom icon
 * ===============================================================================================================
 * Version 1.3.1 (06/08/2007)
 * Fixed bug with change in Google Maps API
 * ===============================================================================================================
 * Version 1.3 (31/07/2007)
 * Added support for creating Yahoo! Maps, can create Map, Satallite or Hybrid.  Check out available options below
 * Added support for creating points on Yahoo! maps.
 * Added support for creating Polylines on Yahoo! maps.
 * Added support for GeoRSS files on both Yahoo! and Google maps, as well as existing KML support for Google, method name was changed from .addKml to .addRss
 * Moved directions search out of main namespace, now function that is called from within plugin by providing fields
 * Added Yahoo! Geocoding support
 * 
 * Known 1.3 Bugs
 * Event.MouseDoubleClick does not work on Yahoo maps within .addPoint method
 * ===============================================================================================================
 * Version 1.2 (25/07/2007)
 * Moved GClientGeocoder into searchAddress method
 * Fixed bug in searchAddress method regarding getPoint().
 * ===============================================================================================================
 * Version 1.1 (16/07/2007)
 * Changed name to remove Google from main name - namespace now .jmap.
 * Added additional options:
 * 	+ Add map dragging enable/disable.
 *	+ Add scroll wheel zooming.
 *	+ Add smooth continuous zooming (on certain browsers).
 *	+ Added clean unloading of Google objects.
 * Added .addPoly method.  Allows the creation of polylines on the map.
 * Added .addKml support for rendering KML Files.
 * Added .directions Driving Direction support.
 * ===============================================================================================================
 * Version 1.0 (13/07/2007)
 * Initial version.
 * Creates Google Map.
 * Add points to map.
 * Takes address or postcode, Geocodes and centers map.  Also creates a draggable marker.
 * ===============================================================================================================
 */
(function($) {
	$.fn.extend({
		/* jmap: function(settings)
		 * The constructor method
		 * Example: $().jmap();
		 */
		jmap: function(settings) {
			var version = "1.5a";
			/* Default Settings*/	
			var settings = $.extend({
				maptype: "hybrid",		// can be "map", "sat" or "hybrid"
				center: [55.958858,-3.162302],
				dimensions: [400, 400],
				zoom: 12,
				controlsize: "small",
				showtype: true,
				showoverview: true,
				dragging: true,
				scrollzoom: false,
				smoothzoom: true,
				clickmarker: false
			},settings);
			
			return this.each(function(){
				// Initialise the GMap2 object
				var jmap = this.jMap = new GMap2(this);
				switch(settings.maptype) {
					case "map":	// Normal Map
						var loadmap = G_NORMAL_MAP;
					break;
					case "sat":	// Satallite Imagery
						var loadmap = G_SATELLITE_MAP;
					break;
					case "hybrid":	//Hybrid Map
						var loadmap = G_HYBRID_MAP;
					break;
				}
				
				// Initialise the map to it's defined center
				jmap.setCenter(new GLatLng(settings.center[0],settings.center[1]),settings.zoom,loadmap);
				
				// Attach a controller to the map view
				switch(settings.controlsize)
				{
					case "small":
						jmap.addControl(new GSmallMapControl());
					break;
					case "large":
						jmap.addControl(new GLargeMapControl());
					break;
					case "none":
					break;
				}
	
				// Type of map Control (Map,Sat,Hyb)
				if (settings.showtype == true){
					jmap.addControl(new GMapTypeControl());
				}
				// Show the small overview map
				if (settings.showoverview == true){
					jmap.addControl(new GOverviewMapControl());//Overview Map
				}
				// Enable scrollwheel on the map
				if (settings.scrollzoom == true) {
					/* Off by default */
					jmap.enableScrollWheelZoom();
				}
				// Enable smooth zooming
				if (settings.smoothzoom == true) {
					/* Off by default*/
					jmap.enableContinuousZoom();
				}
				// Enable a mouse-dragable map
				if (settings.dragging == false) {
					/* On by default */
					jmap.disableDragging();
				}
				
				if (settings.clickmarker == true){
					GEvent.addListener(jmap, "dblclick", function(marker, point){
						if (marker) {
							jmap.removeOverlay(marker);
						} else {
							var marker = new GMarker(point);
							jmap.addOverlay(marker);
							GEvent.addListener(marker, 'click', function(){
								pointlocation = marker.getPoint();
								marker.openInfoWindowHtml("Latitude: " + pointlocation.lat() + "<br />Longitude: " + pointlocation.lng());
							})	
						}
					});
				}
			});	
		},
		/* myMap: function()
		 * Returns a map object from the API, so it's available to the user
		 * Example: $().myMap().setCenter(...) for Google;
		 */
		myMap: function() {
			return this[0].jMap;	
		},
		/* addPoint: function()
		 * Returns a marker to be overlayed on the Google map
		 * Example: $().addPoint(...);
		 */
		addPoint: function(pointlat, pointlng, pointhtml, isdraggable, removable) {
			var jmap = this[0].jMap;
			var marker = new GMarker(new GLatLng(pointlat,pointlng), { draggable: isdraggable } );
			GEvent.addListener(marker, "click", function(){
				marker.openInfoWindowHtml(pointhtml);
			});
			if (removable == true) {
				GEvent.addListener(marker, "dblclick", function(){
					return jmap.removeOverlay(marker);
				});
			}
			return jmap.addOverlay(marker);
		},
		/* addPoly: function(poly)
		 * Takes an array of GLatLng points, converts it to a vector Polyline to display on the map
		 * Example: $().addPoly(...);
		 */
		addPoly: function (poly) {
			var jmap = this[0].jMap;
			return jmap.addOverlay(poly);
		},
		/* addRss: function()
		 * Takes a KML file and renders it to the map.
		 * Example: $().addPoint(...);
		 */
		addRss: function (rssfile, callback) {
			var jmap = this[0].jMap;
			var geoXml = new GGeoXml(rssfile, callback);
			return jmap.addOverlay(geoXml);			
		},
		searchAddress: function (address, settings, callback) {
	
			var settings = $.extend({
				returntype: "map"	//Return as Map or a Object
			},settings);
	
			var jmap = this[0].jMap;
			GGeocoder = new GClientGeocoder();
			GGeocoder.getLatLng(address, function(point){
				if (!point) {
					alert(address + " not found");
				} else {
					switch (settings.returntype) {
						case "object":
							var results = [];
							results[0] = point.y;
							results[1] = point.x;						
							return callback(results);
							break;
						default:
							jmap.setCenter(point);
							var marker = new GMarker(point, {draggable: true});
							jmap.addOverlay(marker);
							var pointlocation = marker.getPoint();
							marker.openInfoWindowHtml("Latitude: " + pointlocation.lat() + "<br />Longitude: " + pointlocation.lng());
							GEvent.addListener(marker, "dragend", function(pointlocation){
								marker.openInfoWindowHtml("Latitude: " + pointlocation.lat() + "<br />Longitude: " + pointlocation.lng());			
							});
							break;
					}
				}
			});
	},
	searchDirections : function(from,to,panel) {
			var jmap = this[0].jMap;
			var dirpanel = document.getElementById(panel);
			directions = new GDirections(jmap, dirpanel);
			directions.load(from + '  to ' + to);
	},
	mapAds : function (p,o) {
		var jmap = this[0].jMap;		
		var o = $.extend({
			maxAdsOnMap: 3,
			channel: "",
			minZoomLevel: 6
		},o);
		
		var adsManager = new GAdsManager(jmap, p, o);
		adsManager.enable();
	},
	showTraffic : function() {
		var jmap = this[0].jMap;
		jmap.addOverlay(new GTrafficOverlay());
	}
	});
})(jQuery);