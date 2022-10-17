/**
 *  jquery.popupt
 *  (c) 2008 Semooh (http://semooh.jp/)
 *
 *  Dual licensed under the MIT (MIT-LICENSE.txt)
 *  and GPL (GPL-LICENSE.txt) licenses.
 *
 **/
(function($){
  $.fn.extend({
    FormObserve: function(opt){
      opt = $.extend({
        changeClass: "changed",
        filterExp: "",
        msg: "Unsaved changes will be lost.\nReally continue?"
      }, opt || {});

      var fs = $(this);
      fs.each(function(){
        this.reset();
        var f = $(this);
        var is = f.find(':input');
        f.FormObserve_save();
        setInterval(function(){
          is.each(function(){
            var node = $(this);
            var def = $.data(node.get(0), 'FormObserve_Def');
            if(node.FormObserve_ifVal() == def){
              if(opt.changeClass) node.removeClass(opt.changeClass);
            }else{
              if(opt.changeClass) node.addClass(opt.changeClass);
            }
          });
        }, 1);
      });

      function beforeunload(e){
        var changed = false;
        fs.each(function(){
          if($(this).find(':input').FormObserve_isChanged()){
            changed = true;
            return false;
          }
        });
        if(changed){
          e = e || window.event;
          e.returnValue = opt.msg;
        }
      }
      if(window.attachEvent){
          window.attachEvent('onbeforeunload', beforeunload);
      }else if(window.addEventListener){
          window.addEventListener('beforeunload', beforeunload, true);
      }
    },
    FormObserve_save: function(){
      var node = $(this);
      if(node.is('form')){
        node.find(':input').each(function(){
          $(this).FormObserve_save();
        });
      } else if(node.is(':input')){
        $.data(node.get(0), 'FormObserve_Def', node.FormObserve_ifVal());
      }
    },
    FormObserve_isChanged: function(){
      var changed = false;
      this.each(function() {
        var node = $(this);
        if(node.eq(':input')){
          var def = $.data(node.get(0), 'FormObserve_Def');
          if(typeof def != 'undefined' && def != node.FormObserve_ifVal()){
            changed = true;
            return false;
          }
        }
      });
      return changed;
    },
    FormObserve_ifVal: function(){
      var node = $(this.get(0));
      if(node.is(':radio,:checkbox')){
        var r = node.attr('checked');
      }else if(node.is(':input')){
        var r = node.val();
      }
      return r;
    }
  });
})(jQuery);
