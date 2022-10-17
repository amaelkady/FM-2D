$( document ).ready( function() {
	if( jQuery.browser.mozilla ) {
		// Hide forms
		$( 'form.cmxform' ).hide();
  
		// Processing
		$( 'form.cmxform' ).find( 'li/label' ).not( '.nocmx' ).not( '.error' ).each( function( i ) {
			var labelContent = this.innerHTML;
			var labelWidth = document.defaultView.getComputedStyle( this, '' ).getPropertyValue( 'width' );
			var labelSpan = document.createElement( 'span' );
			labelSpan.style.display = 'block';
			labelSpan.style.width = labelWidth;
			labelSpan.innerHTML = labelContent;
			this.style.display = '-moz-inline-box';
			this.innerHTML = '';
			this.appendChild( labelSpan );
		});

		// Show forms
		$( 'form.cmxform' ).show();
	}
});
