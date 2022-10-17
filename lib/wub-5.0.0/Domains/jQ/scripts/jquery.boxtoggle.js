// http://www.stainlessvision.com/collapsible-box-jquery
// Modified

function boxToggle(boxId) {
	var box = $(boxId);

	// Get the first heading
	var firstHeading = box.find("h1, h2, h3, h4, h5")[0];

	// Select the heading's ancestors
	var headingAncestors = $(firstHeading).parents();

	// Add in the heading
	var headingAncestors  = headingAncestors.add(firstHeading);

	// Restrict the ancestors to the box
	headingAncestors = headingAncestors.not(box.parents());
	headingAncestors = headingAncestors.not(box);

	// Get the siblings of ancestors (uncle, great uncle, ...)
	var boxContents = headingAncestors.siblings();


	// *** HIDE/SHOW LINK ***
	var toggleLink = $(firstHeading).wrap("<a href='#'></a>");
	var toggleImg = $("<img src='/icons/bplus.gif'>");
	$(firstHeading).prepend($(toggleImg));


	// *** TOGGLE FUNCTIONS ***
	var hideBox = function(text) {
	    $(toggleLink).one("click", function(){
		    showBox();
		    return false;
		});
	    $(toggleLink).attr("title", "Show");
	    $(toggleLink).attr("class", "box-toggle-show");
	    $(toggleImg).attr("src", "/icons/bplus.gif");
	    
	    boxContents.attr("style", "display:none");
	}

	var showBox = function() {
	    $(toggleLink).one("click", function(){
		    hideBox();
		    return false;
		});
	    $(toggleLink).attr("title", "Hide");
	    $(toggleLink).attr("class", "box-toggle-hide");
	    $(toggleImg).attr("src", "/icons/bminus.gif");
	    
	    boxContents.removeAttr("style");
	}

	// Initiate
	hideBox();

}
