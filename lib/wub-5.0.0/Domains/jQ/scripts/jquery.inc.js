/*

inc v5

A super-tiny client-side include JavaScript jQuery plugin

<http://johannburkard.de/blog/programming/javascript/inc-a-super-tiny-client-side-include-javascript-jquery-plugin.html>

MIT license.

Johann Burkard
<http://johannburkard.de>
<mailto:jb@eaio.com>

<ul>
<li onclick="$(this).inc('/resources/Johann/inc-1.html');"><strong>Replace this text with a mildly amusing text.</strong></li>
<li onclick="$(this).inc('/resources/Johann/inc-2.html', function(a) { return a.toUpperCase() });">Include another text snippet and uppercase it.</li>
<li class="inc:/resources/Johann/inc-3%20la%20la%20la.html">This pseudo text will be replaced on load.</li>
<li onclick="$(this).inc('/resources/Johann/inc-4.html', null, function() { alert('Check it.'); });">Test callback method.</li>
</ul>


*/

jQuery.fn.inc = function(url, transform, post) {
 return this.each(function() {
  var t = $(this);

  var transfer = function(txt) {
      if (transform) {
	  txt= $.isFunction(transform) ? transform(txt) : txt
      }
	  
      t.html(txt);
      if ($.isFunction(post)) {
	  post(t);
      }
  };

  if ($.browser.msie) {

   do {
    var f = 'inc' + (Math.round(Math.random() * 999));
   }
   while ($('#' + f).length);

   $('<iframe><\/iframe>').hide().attr('id', f).bind('readystatechange', function() {
    if (this.readyState == 'complete') {
     transfer(document.frames(f).document.body.innerHTML);
    }
   }).attr('src', url).appendTo(document.body);

  }
  else {
   $.ajax({
    url: url,
    complete: function(res, status) {
     if (status == 'success') transfer(res.responseText);
    }
   });
  }
 });
};

$(function() {
 $('[class*=inc]').each(function() {
  var arg = unescape(this.className.replace(/.*inc:([^ ]+)( .*|$)/, '$1')).split('#');
  if (arg[1]) {
      arg[1]=eval(arg[1].replace(/@/g,' '));
  }
  if (arg[2]) {
      arg[2]=eval(arg[2].replace(/@/g,' '));
  }

  $(this).inc(arg[0], arg[1], arg[2]);
 });
});
