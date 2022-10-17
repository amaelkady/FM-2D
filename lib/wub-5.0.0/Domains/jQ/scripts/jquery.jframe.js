// jFrame
// $Revision: 1.132 $
// Author: Frederic de Zorzi
// Contact: fredz@_nospam_pimentech.net
// Revision: $Revision: 1.132 $
// Date: $Date: 2009-01-21 11:55:29 $
// Copyright: 2007-2008 PimenTech SARL
// Tags: ajax javascript pimentech english jquery



jQuery.fn.waitingJFrame = function () {
    // Overload this function in your code to place a waiting event
    // message, like :  $(this).html("<b>loading...</b>");
}

jQuery.fn.failedJFrame = function (response, XMLHttpRequest) {
    // Overload this function in your code to place a waiting event
    // message, like :  $(this).html("<b>loading...</b>");
}

function _jsattr(elem, key) {
	var res = $(elem).attr(key);
	if (res == undefined) {
		return function() {};
	}
	if (jQuery.browser.msie) {
		return function() { eval(res); };
	}
	return res;
}


function jFrameSubmitInput(input) {
    var target = $(input).getJFrameTarget();
    if (target.length) {
        var form = input.form;
        if (form.onsubmit && form.onsubmit() == false
            || target.preloadJFrame() == false) {
            return false;
        }
        $(form).ajaxSubmit({
		target: target,
                    beforeSubmit: function(formArray) {
                    formArray.push({ name:"submit", value: $(input).attr("value") });
                },
                    success: function() {
                    target.attr("src", $(form).attr("action"));
		    _jsattr(target, "onload")();
                    target.activateJFrame();
                }
            });
        return false;
    }
    return true;
}

jQuery.fn.preloadJFrame = function(initial) {
	if (!initial && _jsattr(this, "onunload")() == false) {
		return false;
	}
    $(this).waitingJFrame();
}


jQuery.fn.getJFrameTarget = function() {
    // Returns first parent jframe element, if exists
    var div = $(this).parents("div[src]").get(0);
    if (div) {
        var target = $(this).attr("target");
        if (target) {
            return $("#" + target);
        }
    }
    return $(div);
};



jQuery.fn.loadJFrame = function(url, callback, initial) {
    // like ajax.load, for jFrame. the onload attribute is supported
    var this_callback = _jsattr(this, "onload");
    callback = callback || function(){};
    url = url || $(this).attr("src");
    if (url && url != "#") {
        if ($(this).preloadJFrame(initial) == false) {
            return false;
        }
        $(this).load(url,
                     function(response, status, xhr) {
			 if (status != "error") {
			     $(this).attr("src", url);
			     $(this).activateJFrame();
			     $(this).find("div[src]").each(function(i) {
				     $(this).loadJFrame(undefined, callback);
				 });
			     $(this).find("span[src]").each(function(i) {
				     $(this).loadJFrame(undefined, callback);
				 });
			     this_callback(xhr);
			 } else {
			     $(this).failedJFrame(response, XMLHttpRequest);
			 }
			 callback(status);
		     });
    }
    else {
        $(this).activateJFrame();
    }
};

jQuery.fn.activateJFrame = function() {
    // Add an onclick event on all <a> and <input type="submit"> tags
    $(this).find("a")
    .not("[jframe='no']")
    .unbind("click")
    .click(function() {
            var target = $(this).getJFrameTarget();
            if (target.length) {
                var href = $(this).attr("href");
                if (href && href.indexOf('javascript:') != 0) {
                    target.loadJFrame(href);
                    return false;
                }
            }
            return true;
        } );

    $(":image,:submit,:button", this)
    .not("[jframe='no']")
    .unbind("click")
    .click(function() {
			return jFrameSubmitInput(this);
		} );

	// Only for IE6 : enter key invokes submit event
    $(this).find("form")
    .unbind("submit")
    .submit(function() {
			return jFrameSubmitInput($(":image,:submit,:button", this).get(0));
    } );
};


$(document).ready(function() {
    $(document).find("div[src]").each(function(i) {
            $(this).loadJFrame(undefined, undefined, true);
    } );
    $(document).find("span[src]").each(function(i) {
            $(this).loadJFrame(undefined, undefined, true);
    } );
} );
