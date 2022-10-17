// transclude <span>s with src links

// set caching to true, otherwise jquery.js can't be cached
$.ajaxSetup({
	cache: true
});

$.fn.transclude = function (options) {
    //alert("transcluding: '" + options.url + "' '" + options.data+"'");
    var empty = {};
    options = $.extend(empty, {
	    type: "GET",
	    target: $(this),
	    merge: "overwrite",
	    dataType: "html",
	    cache: true,
	    success: function (data, status) {
		//alert("success "  + $(this.target).attr("id") + " " + data);
		try {
		    if (this.merge == "overwrite") {
			$(this.target).replaceWith(data);
		    } else {
			$(this.target).html(data);
		    }

		    // recursively creolize and transclude until no changes
		    $(this.target).find("span[src]").each(function(i) {
			    var url = $(this.target).attr("src");
			    $(this.target).removeAttr("src");
			    $(this.target).transclude({url:url, data:$(this.target).attr("data")});
			});

		    // perform low-level transforms if necessary
		    try {
			$('.autoform').ajaxForm({target:'#result'});
		    } catch (e) {}
		    try {
			$('.autogrow').autogrow({maxHeight:1000,minHeight:100});
		    } catch (e) {}

		} catch (e) {
		    alert("transclusion error: " + e);
		}
	    },
	    
	    error: function (xhr, status, error) {
		//alert("ajax fail:"+status);
		var fail = $(this.target).attr("fail");
		if (!fail) {
		    fail = "Server says: ";
		}

		var ct = xhr.getResponseHeader("content-type"),
		xml = ct && ct.indexOf("xml") >= 0,
		data = xml ? xhr.responseXML : xhr.responseText;
		var report = "<p> <img src=/icons/exclam.gif> " + fail + " '" + status + " " + xhr.status + "'</p>" + data;
		if (this.merge == "overwrite") {
		    $(this.target).replaceWith(report);
		} else {
		    $(this.target).html(report);
		}
	    }
	}, options || {});
    
    //alert("ajax: '" + options.url + "' '" + options.arg+"'");
    $.ajax(options);
}

	
// convert .creole content into HTML
$.fn.creolize = function (value) {
    try {
	if (typeof value == "undefined") {
	    value = $(this).html();
	}

	if (value == "") {return}
	
	var creole = new Parse.Simple.Creole({
		interwiki: {
		    WikiCreole: 'http://www.wikicreole.org/wiki/',
		    Wikipedia: 'http://en.wikipedia.org/wiki/'
		},
		linkFormat: '',
	    });
	
	var node = $("<span></span>");
	creole.parse(node, value);
	//alert("Creolized: " + $(node).html());
	return $(node);
    } catch (e) {
	alert("creolize error: " + e);
    }
}

$.fn.creolizeAll = function () {
    var count = 0;
    $(this).find(".creole").each(function (i) {
	    $(this).removeClass("creole");
	    var data = $(this).creolize();
	    try {
		// convert basic content creole->html
		var data = $(this).creolize();
		$(this).replaceWith(data.contents());
		count = count+1;
	    } catch (e) {
		alert("creole rendering error: (" + $(this).html() + ") " + e);
	    }
	});
    return count;	// how many creolizations have we performed?
}

$.fn.transcludeAll = function () {
    var count = 0;
    $(this).find("span[src]").each(function(i) {
	    var url = $(this).attr("src");
	    $(this).removeAttr("src");
	    $(this).transclude({url:url, data:$(this).attr("data")});
	    count = count+1;
	});
    return count;	// how many transclusions have we processed?
}

$.fn.Tuple = function (value) {
    if (value == undefined) {
	value = $(this)
    }
    //alert("Tuple: "+value);
    var count = 1;
    while (count) {
	// recursively creolize and transclude until no changes
	count = $(this).creolizeAll();
	$(this).transcludeAll();
    }

    // perform additional lower-level translations
}
