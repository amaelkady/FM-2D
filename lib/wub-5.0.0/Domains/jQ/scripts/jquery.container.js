/*
 *         developed by Matteo Bicocchi on JQuery
 *         © 2002-2009 Open Lab srl, Matteo Bicocchi
 *			    www.open-lab.com - info@open-lab.com
 *       	version 2.1
 *       	tested on: 	Explorer and FireFox for PC
 *                  		FireFox and Safari for Mac Os X
 *                  		FireFox for Linux
 *         MIT - GPL (GPL-LICENSE.txt) licenses.
 *
 * CONTAINERS BUILD WITH BLOCK ELEMENTS
 */

(function($){
  //	var msie6=$.browser.msie && $.browser.version=="6.0";
  //	var Opera=$.browser.opera;
  jQuery.fn.buildContainers = function (options){
    return this.each (function ()
    {
      if ($(this).is("[inited=true]")) return;

      this.options = {
        containment:"document",
        elementsPath:"elements/",
        onCollapse:function(){},
        onIconize:function(){},
        onClose: function(){},
        onResize: function(){},
        onDrag: function(){},
        onRestore:function(){},
        minimizeEffect:"slide", //or "fade"
        effectDuration:300
      };

      $.extend (this.options, options);
      var container=$(this);

      container.attr("inited","true");
      container.attr("iconized","false");
      container.attr("collapsed","false");
      container.attr("closed","false");
      container.attr("options",this.options);
      container.css({position: "relative"});

      if ($.metadata){
        $.metadata.setType("class");
        if (container.metadata().skin) container.attr("skin",container.metadata().skin);
        if (container.metadata().collapsed) container.attr("collapsed",container.metadata().collapsed);
        if (container.metadata().iconized) container.attr("iconized",container.metadata().iconized);
        if (container.metadata().icon) container.attr("icon",container.metadata().icon);
        if (container.metadata().buttons) container.attr("buttons",container.metadata().buttons);
        if (container.metadata().content) container.attr("content",container.metadata().content); //ajax
        if (container.metadata().aspectRatio) container.attr("aspectRatio",container.metadata().aspectRatio); //ui.resize
        if (container.metadata().grid) container.attr("grid",container.metadata().grid); //ui.grid
        if (container.metadata().gridx) container.attr("gridx",container.metadata().gridx); //ui.grid
        if (container.metadata().gridy) container.attr("gridy",container.metadata().gridy); //ui.grid
        if (container.metadata().handles) container.attr("handles",container.metadata().handles); //ui.resize
        if (container.metadata().dock) container.attr("dock",container.metadata().dock);

        if (container.metadata().width) container.attr("width",container.metadata().width);
        if (container.metadata().height) container.attr("height",container.metadata().height);
      }

      if (container.attr("content"))
        container.mb_changeContainerContent(container.attr("content"));

      container.addClass(container.attr("skin"));
      container.find(".n:first").attr("unselectable","on");
      if (!container.find(".n:first").html()) container.find(".n:first").html("&nbsp;");
      container.containerSetIcon(container.attr("icon"), this.options.elementsPath);
      if (container.attr("buttons")) container.containerSetButtons(container.attr("buttons"),this.options);

      if (container.attr("width")){
        var cw= $.browser.msie? container.attr("width"):container.attr("width")+"px";
        container.css({width:cw});
      } else {
	  container.css({width:"99.9%"});
      }

      if (container.attr("height")){
        container.find(".c:first , .mbcontainercontent:first").css("height",container.attr("height")-container.find(".n:first").outerHeight()-(container.find(".s:first").outerHeight()));
      }

      if (container.hasClass("draggable")){
        container.css({position:"absolute", margin:0});
        container.find(".n:first").css({cursor:"move"});
        container.mb_BringToFront();
        container.draggable({
          handle:".n:first",
          delay:0,
          containment:this.options.containment,
          stop:function(){
            var opt=$(this).attr("options");
            if(opt.onDrag) opt.onDrag($(this));
          }
        });
        if (container.attr("grid") || (container.attr("gridx") && container.attr("gridy"))){
          var grid= container.attr("grid")? [container.attr("grid"),container.attr("grid")]:[container.attr("gridx"),container.attr("gridy")];
          container.draggable('option', 'grid', grid);
          //alert( container.draggable('option', 'grid'))
        }
        container.bind("mousedown",function(){
          $(this).mb_BringToFront();
        });
      }
      if (container.hasClass("resizable")){
        container.containerResize();
      }
      if (container.attr("collapsed")=="true"){
        container.attr("collapsed","false");
        container.containerCollapse(this.options);
      }
      if (container.attr("iconized")=="true"){
        container.attr("iconized","false");
        container.containerIconize(this.options);
      }
    });
  };

  jQuery.fn.containerResize = function (){
    var isDraggable=$(this).hasClass("draggable");
    var handles= $(this).attr("handles")?$(this).attr("handles"):"s";
    var aspectRatio= $(this).attr("aspectRatio")?$(this).attr("aspectRatio"):false;

    $(this).resizable({
      handles:isDraggable ? "":handles,
      aspectRatio:aspectRatio,
      minWidth: 150, //todo: move to properties
      minHeight: 150,//todo: move to properties
      iframeFix:true,
      helper: "mbproxy",
      start:function(e,o){
        o.helper.mb_BringToFront();
      },
      stop:function(){
        var resCont= $(this);//$.browser.msie || Opera ?o.helper:
        var elHeight= resCont.outerHeight()-$(this).find(".n:first").outerHeight()-($(this).find(".s:first").outerHeight());
        $(this).find(".c:first , .mbcontainercontent:first").css({height: elHeight});
        if (!isDraggable && !$(this).attr("handles")){
          var elWidth=$(this).attr("width") && $(this).attr("width")>0 ?$(this).attr("width"):"99.9%";
          $(this).css({width: elWidth});
        }
        var opt=$(this).attr("options");
        if(opt.onResize) opt.onResize($(this));
      }
    });

    /*
     *TO SOLVE UI CSS CONFLICT I REDEFINED A SPECIFIC CLASS FOR HANDLERS
     */

    $(this).find(".ui-resizable-n").addClass("mb-resize").addClass("mb-resize-resizable-n");
    $(this).find(".ui-resizable-e").addClass("mb-resize").addClass("mb-resize-resizable-e");
    $(this).find(".ui-resizable-w").addClass("mb-resize").addClass("mb-resize-resizable-w");
    $(this).find(".ui-resizable-s").addClass("mb-resize").addClass("mb-resize-resizable-s");
    $(this).find(".ui-resizable-se").addClass("mb-resize").addClass("mb-resize-resizable-se");

  };

  jQuery.fn.containerSetIcon = function (icon,path){
    if (icon && icon!="" ){
	if (icon[0] != "/") {
	    $(this).find(".ne:first").prepend("<img class='icon' src='"+path+"icons/"+icon+"' style='position:absolute'/>");
	} else {
	    $(this).find(".ne:first").prepend("<img class='icon' src='"+icon+"' style='position:absolute'/>");
	}
      $(this).find(".n:first").css({paddingLeft:25});
    }else{
      $(this).find(".n:first").css({paddingLeft:0});
    }
  };

  jQuery.fn.containerSetButtons = function (buttons,opt){
    if (!opt) opt=$(this).attr("options");
    var path= opt.elementsPath;
    var container=$(this);
    if (buttons !=""){
      var btn=buttons.split(",");
      $(this).find(".ne:first").append("<div class='buttonBar'></div>");
      for (var i in btn){
        if (btn[i]=="c"){
          $(this).find(".buttonBar:first").append("<img src='"+path+$(this).attr('skin')+"/close.png' title='close' class='close'/>");
          $(this).find(".close:first").bind("click",function(){
            if (!$.browser.msie) container.fadeOut(opt.effectDuration);
            else container.hide();
            container.attr("closed","true");
            if (opt.onClose) opt.onClose(container);
          });
        }
        if (btn[i]=="m"){
          $(this).find(".buttonBar:first").append("<img src='"+path+$(this).attr('skin')+"/min.png' title='minimize' class='collapsedContainer'/>");
          $(this).find(".collapsedContainer:first").bind("click",function(){container.containerCollapse(opt);});
          $(this).find(".n:first").bind("dblclick",function(){container.containerCollapse(opt);});
        }
        if (btn[i]=="p"){
          $(this).find(".buttonBar:first").append("<img src='"+path+$(this).attr('skin')+"/print.png' title='print' class='printContainer'/>");
          $(this).find(".printContainer:first").bind("click",function(){});
        }
        if (btn[i]=="i"){
          $(this).find(".buttonBar:first").append("<img src='"+path+$(this).attr('skin')+"/iconize.png' title='iconize' class='iconizeContainer'/>");
          $(this).find(".iconizeContainer:first").bind("click",function(){container.containerIconize(opt);});
        }
        $(this).find(".buttonBar:first").hide("fast");
      }
      var fadeOnClose=$.browser.mozilla || $.browser.safari;
      if (fadeOnClose) $(this).find(".buttonBar:first img")
              .css({opacity:.5, cursor:"pointer","mozUserSelect": "none", "khtmlUserSelect": "none"})
              .mouseover(function(){$(this).fadeTo(200,1);})
              .mouseout(function(){if (fadeOnClose)$(this).fadeTo(200,.5);});
      $(this).find(".buttonBar:first img").attr("unselectable","on");
    }
  };

  jQuery.fn.containerCollapse = function (opt){
    this.each (function () {
      if (!opt) opt=$(this).attr("options");
      var container=$(this);
      if ($(this).attr("collapsed")=="false"){
        container.attr("w" , container.outerWidth());
        container.attr("h" , container.outerHeight());
        if (opt.minimizeEffect=="fade")
          container.find(".o:first").fadeOut(opt.effectDuration,function(){});
        else{
          container.find(".icon:first").hide();
          container.find(".o:first").slideUp(opt.effectDuration,function(){});
          container.animate({height:container.find(".n:first").outerHeight()+container.find(".s:first").outerHeight()},opt.effectDuration,function(){container.find(".icon:first").show();});
        }
        container.attr("collapsed","true");
        container.find(".collapsedContainer:first").attr("src",opt.elementsPath+$(this).attr('skin')+"/max.png");
        container.resizable("disable");
        if (opt.onCollapse) opt.onCollapse(container);
      }else{
        if (opt.minimizeEffect=="fade")
          container.find(".o:first").fadeIn(opt.effectDuration,function(){});
        else{
          container.find(".o:first").slideDown(opt.effectDuration,function(){});
          container.find(".icon:first").hide();
          container.animate({height:container.attr("h")},opt.effectDuration,function(){container.find(".icon:first").show();});
        }
        if (container.hasClass("resizable")) container.resizable("enable");
        container.attr("collapsed","false");
        container.find(".collapsedContainer:first").attr("src",opt.elementsPath+$(this).attr('skin')+"/min.png");
        container.find(".mbcontainercontent:first").css("overflow","auto");

      }
    });
  };

  jQuery.fn.containerIconize = function (opt){
    if (!opt) opt=$(this).attr("options");
    return this.each (function ()
    {
      var container=$(this);
      container.attr("iconized","true");
      if(container.attr("collapsed")=="false"){
        container.attr("h",container.outerHeight());
      }
      container.attr("w",container.attr("width") && container.attr("width")>0 ? (!container.hasClass("resizable")? container.attr("width"):container.width()):!$(this).attr("handles")?"99.9%":container.width());
      container.attr("t",container.css("top"));
      container.attr("l",container.css("left"));
      container.resizable("disable");
      var l=0;
      var t= container.css("top");
      var dockPlace= container;
      if (container.attr("dock")){
        dockPlace = $("#"+container.attr("dock"));
        var icns= dockPlace.find("img").size();
        l=$("#"+container.attr("dock")).offset().left+(32*icns);
        t=$("#"+container.attr("dock")).offset().top;
      };
      /*
       ICONIZING CONTAINER
       */
      this.dockIcon= $("<img src='"+opt.elementsPath+"icons/"+(container.attr("icon")?container.attr("icon"):"restore.png")+"' class='restoreContainer' width='32'/>").appendTo(dockPlace)
              .css("cursor","pointer")
              .hide()
              .attr("contTitle",container.find(".n:first").html())
              .bind("click",function(){


        container.attr("iconized","false");
        if (container.is(".draggable"))
          container.css({top:$(this).offset().top, left:$(this).offset().left});
        else
          container.css({left:"auto",top:"auto"});
        container.show();

        if (!$.browser.msie) {
          container.find(".no:first").fadeIn("fast");
          if(container.attr("collapsed")=="false"){
            container.animate({height:container.attr("h"), width:container.attr("w"),left:container.attr("l"),top:container.attr("t")},opt.effectDuration,function(){
              container.find(".mbcontainercontent:first").css("overflow","auto");
              if(container.hasClass("draggable")) {
                container.mb_BringToFront();
              }
            });
            container.find(".c:first , .mbcontainercontent:first").css("height",container.attr("h")-container.find(".n:first").outerHeight()-(container.find(".s:first").outerHeight()));
          }
          else
            container.animate({height:"60px", width:container.attr("w"), left:container.attr("l"),top:container.attr("t")},opt.effectDuration);
        } else {
          container.find(".no:first").show();
          if(container.attr("collapsed")=="false"){
            container.css({height:container.attr("h"), width:container.attr("w"),left:container.attr("l"),top:container.attr("t")},opt.effectDuration);
            container.find(".c:first , .mbcontainercontent:first").css("height",container.attr("h")-container.find(".n:first").outerHeight()-(container.find(".s:first").outerHeight()));
          }
          else
            container.css({height:"60px", width:container.attr("w"),left:container.attr("l"),top:container.attr("t")},opt.effectDuration);
        }
        if (container.hasClass("resizable") && container.attr("collapsed")=="false") container.resizable("enable");
        $(this).remove();
        if(container.hasClass("draggable")) container.mb_BringToFront();
        $(".iconLabel").remove();
        if(opt.onRestore) opt.onRestore(container);        
      })
              .bind("mouseenter",function(){
        var label="<div class='iconLabel'>"+$(this).attr("contTitle")+"</div>";
        $("body").append(label);
        $(".iconLabel").hide().css({
          position:"absolute",
          top:$(this).offset().top-15,
          left:$(this).offset().left+15,
          opacity:.9
        }).fadeIn("slow").mb_BringToFront();
      })
              .bind("mouseleave",function(){
        $(".iconLabel").remove();
      });
      

      if (!$.browser.msie) {
        container.find(".mbcontainercontent:first").css("overflow","hidden");
        container.find(".no:first").slideUp("fast");
        container.animate({ height:"32px", width:"32px",left:l,top:t},opt.effectDuration,function(){
          $(this.dockIcon).show();
          if (container.attr("dock")) container.hide();
        });
      }else{
        container.find(".no:first").hide();
        container.css({ height:"32px", width:"32px",left:l,top:t});
        $(this.dockIcon).show();
        if (container.attr("dock")) container.hide();
      }
      if (opt.onIconize) opt.onIconize(container);
    });
  };

  jQuery.fn.mb_resizeTo = function (h,w){
    if (!w) w=$(this).outerWidth();
    if (!h) h=$(this).outerHeight();
    $(this).animate({"height":h,"width":w},500,function(){
      var elHeight= $(this).outerHeight()-$(this).find(".n:first").outerHeight()-($(this).find(".s:first").outerHeight());
      $(this).find(".c:first , .mbcontainercontent:first").animate({height: elHeight});
    });
  };

  jQuery.fn.mb_iconize = function (){
    if ($(this).attr("closed")=="false"){
      if ($(this).attr("iconized")=="true"){
        var icon=$(this)[0].dockIcon;
        $(icon).click();
        $(this).mb_BringToFront();
      }else{
        $(this).containerIconize();
      }
    }
  };

  jQuery.fn.mb_open = function (url,data){
    if ($(this).attr("closed")=="true"){
      if (!data) data="";
      if (url){
        $(this).mb_changeContainerContent(url,data);
      }
      if (!$.browser.msie) $(this).fadeIn(300);
      else $(this).show();
      $(this).attr("closed","false");
      $(this).mb_BringToFront();
    }
  };

  jQuery.fn.mb_close = function (){
    if ($(this).attr("closed")=="false"){
      $(this).find(".close:first").click();
    }
  };

  jQuery.fn.mb_toggle = function (){
    if ($(this).attr("closed")=="false" && $(this).attr("iconized")=="false"){
      $(this).containerCollapse();
    }
  };

  jQuery.fn.mb_BringToFront= function(){
    var zi=10;
    $('*').each(function() {
      if($(this).css("position")=="absolute"){
        var cur = parseInt($(this).css('zIndex'));
        zi = cur > zi ? parseInt($(this).css('zIndex')) : zi;
      }
    });
    $(this).css('zIndex',zi+=1);
  };

  jQuery.fn.mb_changeContent= function(url, data){
    var where=$(this);
    if (!data) data="";
    $.ajax({
      type: "POST",
      url: url,
      data: data,
      success: function(html){
        where.html(html);
      }
    });
  };

  jQuery.fn.mb_changeContainerContent=function(url, data){
    $(this).find(".mbcontainercontent:first").mb_changeContent(url,data);
  };

  jQuery.fn.mb_getState= function(attr){
    var state = $(this).attr(attr);
    state= state == "true";
    return state;
  };

  jQuery.fn.mb_fullscreen= function(){
    //  console.log(!$(this).is(".draggable"),$(this).is("[iconized='true']"),$(this).is("[collapsed='true']"))
    if (!$(this).is(".draggable") || $(this).is("[iconized='true']") || $(this).is("[collapsed='true']")) return;

    $(this).attr("w",$(this).width());
    $(this).attr("h",$(this).height());
    $(this).attr("t",$(this).css("top"));
    $(this).attr("l",$(this).css("left"));

    $(this).animate({top:10,left:10, position:"relative"});
    $(this).mb_resizeTo("98%", "98%");
  };

})(jQuery);

