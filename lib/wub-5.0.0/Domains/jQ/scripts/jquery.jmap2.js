/** 
 *	jMap2 - A jQuery plugin for Google Maps API
 *	Author: Tane Piper (digitalspaghetti at gmail dot com)
 * 	Website: http://digitalspaghetti.me.uk
 *	Repository: http://hg.pastemonkey.org/jmaps
 *	Google Group: http://groups.google.com/group/jmaps
 * 	Licensed under the MIT License: http://www.opensource.org/licenses/mit-license.php
 * 	This plugin is not affiliated with Google.  
 * 	For Google Maps API and T&C see http://code.google.com/apis/maps
 * 
 * For support, I can usually be found on the #jquery IRC channel on irc.freenode.net
 **/

// Create a closure so we don't pollute the namespace
(function($){
	// Create global object to store jmap in
	$.jmap = $.jmap || {};

	// Create object containing project details
	$.jmap.JDetails = {
		version: "2.0b",
		author: "Tane Piper <digitalspaghetti@gmail.com>",
		blog: "http://digitalspaghetti.me.uk",
		repository: "http://hg.pastemonkey.org/jmaps",
		googleGroup: "http://groups.google.com/group/jmaps",
		licenceType: "MIT",
		licenceURL: "http://www.opensource.org/licenses/mit-license.php"
	};
	
	// Create object of errors, allows for i18n.
	$.jmap.JErrors = {
		en : {
			addressNotFound: "This address cannot be found.  Please modify your search.",
			browserNotCompatible: "This browser is reported as being not compatible with Google Maps.",
			cannotLoad: "Cannot load the Google Maps API at this time.  Please check your connection."
		},
		fr : {
			addressNotFound: "Cette adresse ne peut pas être trouvée. Veuillez modifier votre recherche.",
			browserNotCompatible: "Ce navigateur est rapporté en tant qu'étant non compatible avec des cartes de Google.",
			cannotLoad: "Ne peut pas charger les cartes api de Google actuellement. Veuillez vérifier votre raccordement."
		},
		de : {
			addressNotFound: "Diese Adresse kann nicht gefunden werden. Ändern Sie bitte Ihre Suche.",
			browserNotCompatible: "Diese Datenbanksuchroutine wird als seiend nicht kompatibel mit Google Diagrammen berichtet.",
			cannotLoad: "Kann nicht die Google Diagramme API diesmal laden. Überprüfen Sie bitte Ihren Anschluß."
		},
		nl : {
			addressNotFound: "Dit adres kan worden gevonden niet. Gelieve te wijzigen uw onderzoek.",
			browserNotCompatible: "Dit browser wordt gemeld zoals zijnd niet compatibel met Kaarten Google.",
			cannotLoad: "Kan de Google Kaarten API op dit moment laden niet. Gelieve te controleren uw verbinding."
		},
		es : {
			addressNotFound: "Esta dirección no puede ser encontrada. Modifique por favor su búsqueda.",
			browserNotCompatible: "Este browser se divulga como siendo no compatible con los mapas de Google.",
			cannotLoad: "No puede cargar los mapas API de Google en este tiempo. Compruebe por favor su conexión."
		},
		sv : {
			addressNotFound: "Denna adress kunde ej hittas. Var god justera din sökning",
			browserNotCompatible: "Denna webbläsare är ej kompatibel med Google Maps",
			cannotLoad: "Kan inte ladda Google Maps API för tillfället. Var god kontrollera din anslutning."
		}
	};
	
	/**
	 *	jMaps Default Options
	 **/
	$.jmap.JDefaults = {
		// Initial type of map to display
		language: "en",
		// Options: "map", "sat", "hybrid"
		mapType: "map",
		// Initial map center
		mapCenter: [55.958858,-3.162302],
		// Initial map size
		mapDimensions: [400, 400],
		// Initial zoom level
		mapZoom: 12,
		// Initial map control size
		// Options: "large", "small", "none"
		mapControlSize: "small",
		// Initialise type of map control
		mapShowType: true,
		// Initialise small map overview
		mapShowOverview: true,
		// Enable map dragging when left button held down
		mapEnableDragging: true,
		// Enable map info windows
		mapEnableInfoWindows: true,
		// Enable double click zooming
		mapEnableDoubleClickZoom: false,
		// Enable zooming with scroll wheel
		mapEnableScrollZoom: false,
		// Enable smooth zoom
		mapEnableSmoothZoom: true,
		// Enable Google Bar
		mapEnableGoogleBar: false
	}
	
	$.jmap.JAdsManagerDefaults = {
		// Google Adsense publisher ID
		publisherId: ""
	};
	
	$.jmap.JFeedDefaults = {
		// URL of the feed to pass (required)
		feed: "",
		// Position to center the map on (optional)
		mapCenter: []
	}
	
	$.jmap.JGroundOverlayDefauts = {
		// South West Boundry
		sw: [],
		// North East Boundry
		ne: [],
		// Image
		image: ""
	}
	
	$.jmap.JIconDefaults = {
		image: "",
		shadow: "",
		iconSize: null,
		shadowSize: null,
		iconAnchor: null,
		infoWindowAnchor: null,
		printImage: "",
		mozPrintImage: "",
		printShadow: "",
		transparent: ""
	};
	
	// Marker manager default options
	$.jmap.JMarkerManagerDefaults = {
		// Border Padding in pixels
		borderPadding: 100,
		// Max zoom level 
		maxZoom: 17,
		// Track markers
		trackMarkers: false
	};
	
	// Default options for a point to be created
	$.jmap.JPointDefaults = {
		// Point latitude
		pointLat: null,
		// Point longitude
		pointLng: null,
		// Point HTML for infoWindow
		pointHTML: null,
		// Event to open infoWindow (click, dblclick, mouseover, etc)
		openHTMLEvent: "click",
		// Point is draggable?
		isDraggable: false,
		// Point is removable?
		removable: false,
		// Event to remove on (click, dblclick, mouseover, etc)
		removeEvent: "dblclick",
		// These two are only required if adding to the marker manager
		minZoom: 4,
		maxZoom: 17,
		// Optional Icon to pass in (not yet implemented)
		icon: null,
		// For maximizing infoWindows (not yet implemented)
		maxContent: null,
		maxTitle: null
	};
	
	// Defaults for a Polygon
	$.jmap.JPolygonDefaults = {
		// An array of GLatLng objects
		points: [],
		// The outer stroke colour
	 	strokeColor: "#000000",
	 	// Stroke thickness
	 	strokeWeight: 5,
	 	// Stroke Opacity
	 	strokeOpacity: 1,
	 	// Fill colour
	 	fillColor: "#ff0000",
	 	// Fill opacity
	 	fillOpacity: 1,
	 	// Optional center map
	 	centerMap: [],
	 	// Is polygon clickable?
	 	clickable: true
	};
	
	// Default options for a Polyline
	$.jmap.JPolylineDefaults = {
		// An array of GLatLng objects
		points: [],
		// Colour of the line
		color: "#ff0000",
		// Width of the line
		width: 10,
		// Opacity of the line
		opacity: 1,
		// Optional center map
		centerMap: [],
		// Is line Geodesic (i.e. bends to the curve of the earth)?
		geodesic: false,
		// Is line clickable?
		clickable: true
	};
	
	$.jmap.JSearchAddressDefaults = {
		// Address to search for
		address: null,
		// Option to add marker for address
		addMarker: true,
		// Show address in infoWindow of point is added
		showAddress: true,
		// Optional Cache to store Geocode Data (not implemented yet)
		cache: {},
		// Country code for localisation (not implemented yet)
		countryCode: 'uk'
	};
	
	$.jmap.JSearchDirectionsDefault = {
		// From address
		fromAddress: "",
		// To address
		toAddress: "",
		// Optional panel to show text directions
		directionsPanel: ""
	};
	
	$.jmap.JTrafficDefaults = {
		// Can pass in "create" (default) or "destroy" which will remove the layer
		method: "create",
		// Center the map on this point (optional)
		mapCenter: []
	};
	
	// End of Options
	//========================================================================================================================
	
	/**
	 *	Call with $('#map').jmap(options?, callback?);
	 */
	$.fn.jmap = function(options, callback) {
		return this.each(function(){
			new $.jmap.init(this, options, callback);
		});
	}

	/**
	 *	Call with $('#map').addFeed(options, callback?);
	 */
	 $.fn.addFeed = function(options, callback) {
	 	return this.each(function(){
	 		new $.jmap.addFeed(options, callback);
	 	});
	 }
	 
	 /**
	 *	Call with $('#map').addFeed(options, callback?);
	 */
	 $.fn.addGroundOverlay = function(options, callback) {
	 	return this.each(function(){
	 		new $.jmap.addGroundOverlay(options, callback);
	 	});
	 }
	
	/**
	 *	Call with $('#map').addMarker(options, callback?);
	 */
	$.fn.addMarker = function(options, callback) {
		return this.each(function(){
			new $.jmap.addMarker(options, callback);
		});
	}
	
	/**
	 *	Call with $('#map').addPolygon(options, callback?)
	 */
	 $.fn.addPolygon = function(options, callback) {
	 	return this.each(function(){
	 		new $.jmap.addPolygon(options, callback);
	 	});
	 }
	
	/**
	 *	Call with $('#map').addPolyline(options, callback?)
	 */
	$.fn.addPolyline = function(options, callback) {
	 	return this.each(function(){
	 		new $.jmap.addPolyline(options, callback);
	 	});
	 }
	
	/**
	 *	Call with $('#map').addTrafficInfo(options?, callback?);
	 */
	 $.fn.addTrafficInfo = function(options, callback) {
	 	return this.each(function(){
	 		new $.jmap.addTrafficInfo(options, callback);
	 	});
	 }
	 
	/**
	  *	Call with $('#map').disableTraffic();
	  */
	 $.fn.disableTraffic = function() {
	 	return this.each(function(){
	 		new $.jmap.disableTraffic();
	 	});
	 }
	 
	 /**
	  *	Call with $('#map').enableTraffic();
	  */
	 $.fn.enableTraffic = function() {
	 	return this.each(function(){
	 		new $.jmap.enableTraffic();
	 	});
	 }
	 
	 /**
	  *	Call with $('#map').createAdsManager(options, callback?)
	  */
	 $.fn.createAdsManager = function(options, callback) {
		return this.each(function(){
			new $.jmap.createAdsManager(options, callback);
		});
	}

	/**
	 * Call with $('#map').disableAds()
	 */
	$.fn.disableAds = function() {
		return this.each(function(){
			new $.jmap.disableAds();
		});
	}
	
	/** 
	 *	Call with $('#map').enableAds()
	 */
	$.fn.enableAds = function() {
		return this.each(function(){
			new $.jmap.enableAds();
		});
	}
	
	/**
	 *	Call with $('#map').createGeoCache();
	 */
	$.fn.createGeoCache = function(callback) {
		return this.each(function(){
			new $.jmap.createGeoCache(callback);
		});
	}
	
	/**
	 *	Call with $('#map').createGeoCoder(cache?);
	 */
	$.fn.createGeoCoder = function(cache) {
		return this.each(function(){
			new $.jmap.createGeoCoder(cache);
		});
	}
	
	/**
	 *	Call with $('#map').createMarkerManager(options?, callback?);
	 */
	$.fn.createMarkerManager = function(options, callback) {
		return this.each(function(){
			new $.jmap.createMarkerManager(options, callback);
		});
	}
	
	/**
	 * Call with $('#map').searchAddress({address: "Address"}, pass?, callback?);
	 */
	$.fn.searchAddress = function(options, pass, callback) {
		return this.each(function() {
			new $.jmap.searchAddress(options, pass, callback);
		});
	}
	
	/**
	 *	Call with $('#map').searchDirections(options, callback?);
	 */
	$.fn.searchDirections = function(options, callback) {
		return this.each(function(){
			new $.jmap.searchDirections(options, callback);
		});
	}

	/**
	 *	Function: jmap()
	 *	Basic Useage: $('#div').jmap();
	 *	Accepts: DOM Element, Options object
	 *	Outputs: Map as jQuery Object
	 **/
	$.jmap.init = function(el, options, callback) {
	
		// First we create out options object by checking passed options
		// and that no defaults have been overidden
		var options = $.extend({}, $.jmap.JDefaults, options);
		// Check for metadata plugin support
		var o = $.jmap.JOptions = $.meta ? $.extend({}, options, $(this).data()) : options;
	
		// Check if API can be loaded
		if (typeof GBrowserIsCompatible == 'undefined') {
			// Because map does not load, provide visual error
			$(el).text($.jmap.JErrors[$.jmap.JOptions.language].cannotLoad).css({color: "#f00"});
			// Throw exception
			throw Error($.jmap.JErrors[$.jmap.JOptions.language].cannotLoad);
		}
	
		// Check to see if browser is compatible, if not throw and exception
		if (!GBrowserIsCompatible()) {
			// Because map does not load, provide visual error
			$(el).text($.jmap.JErrors[$.jmap.JOptions.language].browserNotCompatible).css({color: "#f00"});
			// Throw exception
			throw Error($.jmap.JErrors[$.jmap.JOptions.language].browserNotCompatible);
		}
		
		// Initialise the GMap2 object
		el.jmap = $.jmap.GMap2 = new GMap2(el);
		// Set map type based on passed option
		var mapType = $.jmap.initMapType(o.mapType);
		
		// Initialise the map with the passed settings
		el.jmap.setCenter(new GLatLng(o.mapCenter[0], o.mapCenter[1]), o.mapZoom, mapType);
			
		// Attach a controller to the map view
		// Will attach a large or small.  If any other value passed (i.e. "none") it is ignored
		switch(o.mapControlSize)
		{
			case "small":
				el.jmap.addControl(new GSmallMapControl());
			break;
			case "large":
				el.jmap.addControl(new GLargeMapControl());
			break;
		}
		// Type of map Control (Map,Sat,Hyb)
		if(o.mapShowType)
			el.jmap.addControl(new GMapTypeControl()); // Off by default
		
		// Show the small overview map
		if(o.mapShowOverview)
			el.jmap.addControl(new GOverviewMapControl());// Off by default
		
		// GMap2 Functions (in order of the docs for clarity)
		// Enable a mouse-dragable map
		if(!o.mapEnableDragging)
			el.jmap.disableDragging(); // On by default
			
		// Enable Info Windows
		if(!o.mapEnableInfoWindows)
			el.jmap.disableInfoWindow(); // On by default
		
		// Enable double click zoom on the map
		if(o.mapEnableDoubleClickZoom)
			el.jmap.enableDoubleClickZoom(); // On by default
		
		// Enable scrollwheel on the map
		if(o.mapEnableScrollZoom)
			el.jmap.enableScrollWheelZoom(); //Off by default
		
		// Enable smooth zooming
		if (o.mapEnableSmoothZoom)
			el.jmap.enableContinuousZoom(); // Off by default

		// Enable Google Bar
		if (o.mapEnableGoogleBar)
			el.jmap.enableGoogleBar();  //Off by default
		
		return callback;
	}
	
	/**
	 *	.addFeed(options, callback?);
	 *	This function takes a KML or GeoRSS file and
	 *	adds it to the map
	 */
	$.jmap.addFeed = function(options, callback) {
	
		var options = $.extend({}, $.jmap.JFeedDefaults, options);
		
		// Load feed
		var feed = new GGeoXml(options.feed);
		// Add as overlay
		$.jmap.GMap2.addOverlay(feed);
		
		// If the user has passed the optional mapCenter,
		// then center the map on that point
		if (options.mapCenter[0] && options.mapCenter[1])
			$.jmap.GMap2.setCenter(new GLatLng(options.mapCenter[0], options.mapCenter[1]));
		
		return callback;
	
	}
	
	$.jmap.addGroundOverlay = function(options, callback) {
		var options = $.extend({}, $.jmap.JGroundOverlayDefaults, options);
		var boundries = new GLatLngBounds(new GLatLng(options.sw[0], options.sw[1]), new GLatLng(options.ne[0], options.ne[1]));
		
		$.jmap.GGroundOverlay = new GGroundOverlay(options.image, boundries);
		$.jmap.GMap2.addOverlay($.jmap.GGroundOverlay);
	}
	
	/**
	 *	Create a marker and add it as a point to the map
	 */
	$.jmap.addMarker = function(options, callback) {
		// Create options
		var options = $.extend({}, $.jmap.JPointDefaults, options);
		var markerOptions = {}
		
		if (typeof options.icon == 'object')
			$.extend(markerOptions, {icon: options.icon});
		
		if (options.isDraggable)
			$.extend(markerOptions, {draggable: options.isDraggable});
		
		// Create marker, optional parameter to make it draggable
		var marker = new GMarker(new GLatLng(options.pointLat,options.pointLng), markerOptions);
		
		// If it has HTML to pass in, add an event listner for a click
		if(options.pointHTML)
			GEvent.addListener(marker, options.openHTMLEvent, function(){
				marker.openInfoWindowHtml(options.pointHTML, {maxContent: options.maxContent, maxTitle: options.maxTitle});
			});

		// If it is removable, add dblclick event
		if(options.removable)
			GEvent.addListener(marker, options.removeEvent, function(){
				$.jmap.GMap2.removeOverlay(marker);
			});

		// If the marker manager exists, add it
		if($.jmap.GMarkerManager) {
			$.jmap.GMarkerManager.addMarker(marker, options.minZoom, options.maxZoom);	
		} else {
			// Direct rendering to map
			$.jmap.GMap2.addOverlay(marker);
		}
		
		return callback;
	}
	
	/**
	 * Create a polygon and render to the map
	 */
	 $.jmap.addPolygon = function(options, callback) {
	 	var options = $.extend({}, $.jmap.JPolygonDefaults, options);
	 	if(!options.clickable)
	 		var polygonOptions = $.extend({}, polygonOptions, {clickable: false});
	 		
	 	if(options.centerMap[0] && options.centerMap[1])
	 		$.jmap.GMap2.setCenter(new GLatLng(options.centerMap[0], options.centerMap[1]));
		
		var polygon = new GPolygon(options.points, options.strokeColor, options.strokeWeight, options.strokeOpacity, options.fillColor, options.fillopacity, polygonOptions);
		$.jmap.GMap2.addOverlay(polygon);
		
		return callback;
	 }
	
	/**
	 *	Create a polyline and render on the map
	 */
	$.jmap.addPolyline = function (options, callback) {
		var options = $.extend({}, $.jmap.JPolylineDefaults, options);
		var polyLineOptions = {};
		if (options.geodesic)
			$.extend({}, polyLineOptions, {geodesic: true});
			
		if(!options.clickable)
			$.extend({}, polyLineOptions, {clickable: false});

		if (options.centerMap[0] && options.centerMap[1])
			$.jmap.GMap2.setCenter(new GLatLng(options.centerMap[0], options.centerMap[1]));

		var polyline = new GPolyline(options.points, options.color, options.width, options.opacity, polyLineOptions);
		$.jmap.GMap2.addOverlay(polyline);
		
		return callback;
	}
		
	/**
	 *	.trafficInfo(options?, callback?);
	 *	This function renders a traffic info
	 *	overlay for supported cities
	 *	The GTrafficOverlay also has it's own show/hide methods
	 *	that do not destory the overlay.  Can be called:
	 *	$.jmap.GTrafficOverlay.show();
	 *	$.jmap.GTrafficOverlay.hide();
	 */
	$.jmap.addTrafficInfo = function(options, callback) {
		var options = $.extend({}, $.jmap.JTrafficDefaults, options);
		
		// Does the user wants to create or destory the overlay
		switch(options.method) {
			case "create":
				$.jmap.GTrafficOverlay = new GTrafficOverlay;
				// Add overlay
				$.jmap.GMap2.addOverlay($.jmap.GTrafficOverlay);
				// If the user has passed the optional mapCenter,
				// then center the map on that point
				if (options.mapCenter[0] && options.mapCenter[1]) {
					$.jmap.GMap2.setCenter(new GLatLng(options.mapCenter[0], options.mapCenter[1]));
				}
			break;
			case "destroy":
				// Distroy overlay
				$.jmap.GMap2.removeOverlay($.jmap.GTrafficOverlay);
			break;
		
		}
	}
	
	$.jmap.disableTraffic = function() {
		$.jmap.GTrafficOverlay.hide();
	}
	
	$.jmap.enableTraffic = function() {
		$.jmap.GTrafficOverlay.show();
	}
	
	/**
	 *	Create a AdSense ad manager
	 */
	$.jmap.createAdsManager = function(options, callback) {
		var options = $.extend({}, $.jmap.JAdsManagerDefaults, options);
	
		$.jmap.GAdsManager = new GAdsManager($.jmap.GMap2, options.publisherId);
		
		return callback;
	}
	
	$.jmap.disableAds = function(){
		$.jmap.GAdsManager.disable();
	}
	
	$.jmap.enableAds = function(){
		$.jmap.GAdsManager.enable();
	}
	
	// Create Geocoder cache and attach to global object
	$.jmap.createGeoCache = function(callback) {
		$.jmap.GGeocodeCache = new GGeocodeCache();
		return callback;
	}
	
	// Create a geocoder object
	$.jmap.createGeoCoder = function(cache) {
		if (cache) {
			// Create with cache
			$.jmap.GClientGeocoder = new GClientGeocoder(cache);
		} else {
			// No cache
			$.jmap.GClientGeocoder = new GClientGeocoder;
		} 
	}
	
	/**
	 * Create an icon to return to addMarker
	 */
	$.jmap.createIcon = function(options) {
		var options = $.extend({}, $.jmap.JIconDefaults, options);
		var icon = new GIcon(G_DEFAULT_ICON);
		
		if(options.image)
			icon.image = options.image;
		if(options.shadow)
			icon.shadow = options.shadow;
		if(options.iconSize)
			icon.iconSize = options.iconSize;
		if(options.shadowSize)
			icon.shadowSize = options.shadowSize;
		if(options.iconAnchor)
			icon.iconAnchor = options.iconAnchor;
		if(options.infoWindowAnchor)
			icon.infoWindowAnchor = options.infoWindowAnchor;
	
		return icon;
	}
	
	/**
	 *	Creates the marker manager and attaches it to the $.jmap namespace
	 */
	$.jmap.createMarkerManager = function(options, callback) {
		// Merge the options with the defaults
		var options = $.extend({}, $.jmap.JMarkerManagerDefaults, options);
		// Create the marker manager and attach to the global object
		$.jmap.GMarkerManager = new GMarkerManager($.jmap.GMap2, options);
		// Return the callback
		return callback;
	}
		
	// This is an alias function that allows the user to simply search for an address
	// Can be returned as a result, or as a point on the map
	$.jmap.searchAddress = function(options, pass, callback) {
	
		var options = $.extend({}, $.jmap.JSearchAddressDefaults, options);
		
		// Add options from pass to marker object
		var pass = $.extend({}, $.jmap.JMarkerManagerDefaults, pass);
		
		// Check to see if the Geocoder already exists in the object
		// or create a temporary locally scoped one.
		if (typeof $.jmap.GClientGeocoder == 'undefined') {
			 var geocoder = new GClientGeocoder;
		} else {
			var geocoder = $.jmap.GClientGeocoder;
		}
		
		// Geocode the address
		geocoder.getLatLng(options.address, function(point){
				if (!point) {
					// Address is not found, throw an error
					throw new Error($.jmap.JErrors[$.jmap.JOptions.language].addressNotFound);
				} else {
					// Center map on point
					$.jmap.GMap2.setCenter(point);
					// If user wants to add marker, get the lat/lng details
					if (options.addMarker) {
						pass.pointLat = point.y;
						pass.pointLng = point.x;
						// Optional show address in a bubble
						if (options.showAddress)
							pass.pointHTML = options.address;
							
						// Add marker to map
						$.jmap.addMarker(pass);
					} else {
						// Return geocoded object
						return point;
					}
				}
		}, callback);	// Fire optional callback supported by the GClientGeocoder
	}
	

	/**
	 *	.searchDirections(options, callback?);
	 *	This function allows you to pass a to and from address.  If To address
	 *	is previous from address, automatically creates a GRoute object
	 */	
	$.jmap.searchDirections = function(options, callback) {
		
		var options = $.extend({}, $.jmap.JSearchDirectionsDefaults, options);

		var panel = $('#' + options.directionsPanel).get(0);
		$.jmap.GDirections = new GDirections($.jmap.GMap2, panel);
		$.jmap.GDirections.load(options.fromAddress + ' to ' + options.toAddress);
		
		return callback;
	}

	// Internal Functions
	
	/**
	 *	Function: 	setMapType
	 *	Accepts: 	string maptype
	 *	Returns:	CONSTANT maptype
	 **/ 
	$.jmap.initMapType = function(option) {
		// Lets set our map type based on the options
		switch(option) {
			case "map":	// Normal Map
				var maptype = G_NORMAL_MAP;
			break;
			case "sat":	// Satallite Imagery
				var maptype = G_SATELLITE_MAP;
			break;
			case "hybrid":	//Hybrid Map
				var maptype = G_HYBRID_MAP;
			break;
		}
		return maptype;	
	}
	
})(jQuery);
// End of closure
