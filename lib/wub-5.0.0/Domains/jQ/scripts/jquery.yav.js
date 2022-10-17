/*
 * jQuery.yav - Easy Form validation with YAV
 * 
 * Copyright (c) 2007 Jose Francisco Rives Lirola (http://letmehaveblog.blogspot.com)
 * Dual licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) 
 * and GPL (http://www.opensource.org/licenses/gpl-license.php) licenses.
 *
 * $LastChangedDate: 2007-10-24 10:00:00 +0100 (wed, 24 oct 2007) $
 *
 * Version: 1.2.0
 * Requires: jQuery v1.2.1+ , YAV v1.4.0+ (http://yav.sourceforge.net/)
 */

jQuery.fn.extend({
	/**
	 * Integrates YAV form validation library as jQuery plugin
	 * adding accesibility, no intrusive, and standards compliant
	 * inline validation in web forms.
	 * 
	 * Setup a form object with YAV validation with no intrusive
	 * HTML code and minimal JS code. The errors messages are associated
	 * to each form field that generates the error, and they are shown
	 * in a position related to the field (after, before, in the parent...)
	 * for better accesibility and screen reader improve.
	 * 
	 * @example $("#myForm").yav();
	 * 
	 * @desc Setup a simple validation for the form with id #myForm using
	 * the default yav rules:
	 * "alnumhyphen","alnumhyphenat","alphabetic","alphanumeric","alphaspace",
	 * "date","date_le","date_lt","double","email","empty","equal","integer",
	 * "keypress","maxlength","minlength","notequal","numeric","numrange",
	 * "regexp" and "required".
	 * Set the proper rule in the class of the form field, the error message
	 * in the title attribute, and the param (if the rule requires it in the
	 * alt attribute as Map object:
	 * alt="{'params':'the param'}"
	 * or
	 * alt="{'params':['oneparam','twoparam',...]}"
	 * If the validation is ok then the form is submited (if the rest of form
	 * submit events handlers returns true), in other case shows the errors.
	 * Also you can set more than one rule using multiple classes (also you can
	 * use a CSS class normally) and the params must be as array of arrays (one
	 * array for each rule)
	 * class="equal maxlength another_css_class_not_rule" alt="{'params':[['one'],[10]]}"
	 * Alternatelly, because textarea and select fields has not alt attribute in
	 * W3C XHTML 1.0 standard, you can set the alt attribute inside the class attribute
	 * like this:  class="rule another_rule {'params':[['one'],[10]]}"
	 * 
	 * @before <form id="myForm" action="url_to_go" method="post|get">
	 * 	<label>Name: 
	 * 		<input type="text" id="name" name="name" class="alphaspace required" title="Please write only chars and spaces characters, this field is required"/>
	 *  </label>
	 * 	<label>Email: 
	 * 		<input type="email" id="email" name="email" title="Write a correct email address" />
	 * 	</label>
	 * 	<input type="submit" value="Send" />
	 * </form>
	 * 
	 * @after <form id="myForm" action="url_to_go" method="post|get">
	 * 	<label>Name: 
	 * 		<p class="error">Please write only chars and spaces characters, this field is required</p>
	 * 		<input type="text" id="name" name="name" class="alphaspace required" 
	 * 			title="Please write only chars and spaces characters, this field is required"/>
	 *  </label>
	 * 	<label>Email: 
	 * 		<p class="error">Write a correct email address</p>
	 * 		<input type="email" id="email" name="email" title="Write a correct email address" />
	 * 	</label>
	 * 	<input type="submit" value="Send" />
	 * </form>
	 * 
	 * @example $("#myForm").yav({
	 * 	"errorDiv":"TopError",
	 * 	"errorMessage":"Some errors are found, please correct them",
	 * 	"custom":{
	 * 		"myCustomRule1": function(returnvalue, param1, param2,...){
	 * 			if ($("textfield1").val() == param1){
	 * 				return null;
	 * 			}else{
	 * 				return returnvalue;
	 * 			}
	 * 		},
	 * 		"anotherCustomRule":....
	 * 	  }
	 * 	}
	 * );
	 * @desc You can set a top message showing a custom message (a default text is
	 * used if you can not set "errorMessage" param and the errorDiv is found). Also
	 * you can indicate another ID for the top message div (default is "errorDiv").
	 * If the validation process on submit is not OK then the errors are show and the
	 * page is scrolled to the top message.
	 * 
	 * In the "custom" param, you can set and indefinited number of custom rules. A custom
	 * rule, returns null id OK and returnvalue (allways the first param) if is not OK.
	 * The custom rule can have any number of params. You can use then, the custom rule
	 * name in the class of the field for the validation.
	 * 
	 * @before <form id="myForm" action="url_to_go" method="post|get">
	 * 	<label>Name: 
	 * 		<input type="text" id="name" name="name" class="myCustomRule1 required" title="Error message" 
	 * 			alt="{
	 * 				params:
	 * 					[
	 * 						['param1','param2'],
	 * 						['']
	 * 				]
	 * 			}"/>
	 *  </label>
	 * 	<input type="submit" value="Send" />
	 * </form>
	 * 
	 * @example $("#myForm").yav();
	 * @desc You can validate any field on event trigger using event parameter in alt attribute.
	 * This event parameter is one or a comma separated event list.
	 * 
	 * @before <form id="myForm" action="url_to_go" method="post|get">
	 * <label>Name: 
	 * 		<input type="text" id="name" name="name" class="required" title="Error message" 
	 * 			alt="{event:'blur, change'}"/>
	 *  </label>
	 * 	<input type="submit" value="Send" />
	 * </form>
	 * 
	 * @example $("#myForm").yav({
	 * 	"errorMessage":"Errors are found"
	 * },{
	 * 	"DATE_FORMAT":"MM/dd/yyyy",
	 * 	"inputclasserror":"fieldError"
	 * });
	 * 
	 * @desc A second Map (object) param in the plugin call you can set all the
	 * global variables for YAV config (you have not use yav-config.js file any more).
	 * 
	 * @example $("#myForm").yav({
	 * 	"onOk":function(form){
	 * 		//executes any code before submit (the validation has been OK)
	 * 		//This is a simple method for cancel the normal way of submit and
	 * 		//submit the validated data using AJAX calls
	 * 
	 * 		return true|false;  //if returns true form is submited, if false, form submit is cancelled
	 * 	},
	 * 	"onError":function(form){
	 * 		//executes any code if validation is not passed (the validation has been ERROR)
	 * 	}
	 * });
	 * 
	 * @desc In the first Map param, you have two more params ("onOk" and "onError"),
	 * these functions are called when the validation process is finished as passed or
	 * not passed. The function "onOk" is used by example, for AJAX submition of the 
	 * data and it not submit the form normally. "form" param is the reference of the 
	 * validated form.
	 * 
	 * @example $("#myForm").yav({
	 * 	"errorDiv": "mainError",
	 * 	"errorMessage": "There are errors in the form",
	 * 	"errorClass": "error",
	 * 	"errorTag": "p",
	 * 	"errorPosition": "before"
	 * });
	 * 
	 * @desc The rest of valid params for the plugin are: "errorDiv", the id of the
	 * div (normally on the top of the form) that shows that errors have been found.
	 * The text of the div "errorDiv" is setted with "errorMessage" param. If errorDiv
	 * is not found the first error gets the focus, in other case "errorDiv" gets the
	 * focus. "errorClass" is the CSS class for the errors messages, the messages are
	 * inside a tag "p" by default, you can set other tag if you want ("div","span",...)
	 * "errorPosition" sets the position of the message over the affected id, this position
	 * use the common jQuery transversing functions, example of valid values ("before",
	 * "after","parent().before","parent().after",...
	 * 
	 * @example $("#myForm").yav();
	 * 
	 * @before <form id="myForm" action="url_to_go" method="post|get">
	 * 	<label>Name: 
	 * 		<input type="text" id="name" name="name" class="numeric" title="Error message" 
	 * 			alt="{
	 * 				condition:{
	 * 					name:'first_and',
	 * 					type:'and',
	 * 					msg:'Checks Name and Email field'
	 * 				}
	 * 			}"/>
	 * 		<input type="text" id="email" name="email" class="alphabetic" title="Error message" 
	 * 			alt="{
	 * 				condition:{name:'first_and'}
	 * 			}"/>
	 *  </label>
	 * 	<input type="submit" value="Send" />
	 * </form>
	 * 
	 * @desc You have 3 rules, the first for the numeric field called "name", the second for the 
	 * alphabetic field called "email" and the third condition related the first and the second
	 * rule with a and rule, this conditional rule is passed if the first AND the second are passed.
	 * In the condition rule you set 'name' (an string for identify the condition rule), a 'type' of
	 * the condition, and the message to show the error. By default the message is show related with the
	 * ID of the first field of the rule (you don't need set all the condition params in the rest of the
	 * fields, only the 'name' identifier is necessary), if you want show the error message in other place,
	 * then set another param 'id' in the condition rule.
	 * {'condition':{'id':'another_id','name':'first_and','type':'and','msg':'Checks Name and Email field'}
	 * You can set three types of conditional rules 'and','or' and 'implies'. The validation dispatch
	 * an error if any of 3 before rules are not passed.
	 * 
	 * @example $("#myForm").yav();
	 * 
	 * @before <form id="myForm" action="url_to_go" method="post|get">
	 * 	<label>Name: 
	 * 		<input type="text" id="name" name="name" class="numeric" title="Error message" 
	 * 			alt="{
	 * 				require:'pre-condition',
	 * 				condition:{name:'first_and',type:'and',msg:'Checks Name and Email field'}
	 * 			}"/>
	 * 		<input type="text" id="email" name="email" class="alphabetic" title="Error message" 
	 * 			alt="{
	 * 				require:'pre-condition',
	 * 				condition:{'name':'first_and'}
	 * 			}"/>
	 *  </label>
	 * 	<input type="submit" value="Send" />
	 * </form>
	 * 
	 * @desc The 'require' param works only with condition rules. You can set this param to 'pre-condition'
	 * (in AND and OR rules) or 'post-condition' (for the final IMPLIES rule). If require param is set, then
	 * the origin rule doesn't dispatch an error if fails, but the condition rule works normally. In the example
	 * case, the numeric and alphabetic rule don't generate an error message but if the AND condition fail then
	 * the condition message is shown.
	 * 
	 * @example $("#myForm").yav();
	 * 
	 * @before <form id="myForm" action="url_to_go" method="post|get">
	 * 	<label>Name: 
	 * 		<input type="text" id="name" name="name" class="numeric" title="Error message" 
	 * 			alt="{
	 * 				require:'pre-condition',
	 * 				condition:[
	 * 					{
	 * 						name:'first_and',
	 * 						type:'and',
	 * 						require:'pre-condition'
	 *					},
	 * 					{
	 * 						name:'group_or',
	 * 						group:['first_and','second_and'],
	 * 						type:'or',
	 * 						msg:'You need validate the first group or the second almost'
	 * 					}
	 * 				]
	 * 			}"/>
	 * 		<input type="text" id="email" name="email" class="alphabetic" title="Error message" 
	 * 			alt="{
	 * 				require:'pre-condition',
	 * 				condition:{'name':'first_and'}
	 * 			}"/>
	 * 		<input type="text" id="name2" name="name2" class="numeric" title="Message" 
	 * 			alt="{
	 * 				require:'pre-condition',
	 * 				condition:{
	 * 					name:'second_and',
	 * 					type:'and',
	 * 					require:'pre-condition'
	 * 				}
	 * 			}"/>
	 * 		<input type="text" id="email2" name="email2" class="alphabetic" title="Message" 
	 * 			alt="{
	 * 				require:'pre-condition',
	 * 				condition:{'name':'second_and'}
	 * 			}"/>
	 *  </label>
	 * 	<input type="submit" value="Send" />
	 * </form>
	 * 
	 * @desc Multiple condition validation. You can write others 'condition's using an
	 * array of conditions. Alternately, you can express conditions over other conditions.
	 * By example, the this HTML code, you need express the conditions 
	 * ('name' AND 'email') OR ('name2' AND 'email2'), each AND condition is defined by a
	 * NAME identifier 'first_and' and 'second_and', in the OR condition you can write a new
	 * param 'group' as array of the name of the others conditions.
	 * Also you can write the 'require' param in each condition if you don't want generate
	 * error messages.
	 * 
	 * @name yav
	 * @param Map params The parameters list for the plugin (see the examples)
	 * @param Map yav_config The yav variables list (not requires yav-config.js file)
	 * 
	 * @type jQuery
	 * @return Object jQuery
	 * @cat Plugins/Integration/Forms
	 * @author SeViR · José Francisco Rives Lirola (http://letmehaveblog.blogspot.com | http://www.sevir.org/en/)
	 */
	yav:function(params,yav_config){
		var yavC = jQuery.extend({
			//yav config settings
			errorsdiv : "yavDiv",
			debugmode: false,
			DEFAULT_MSG : "",
			inputclassnormal : "i",
			inputhighlight : "h",
			inputclasserror : "c",
			trimenabled : true,
			RULE_SEP : "|",
			multipleclassname: true
		}, yav_config);
		
		var params = jQuery.extend({
			errorDiv : "errorDiv",
			errorMessage : "ERROR, please correct",
			errorClass : "error",
			errorTag : "p",
			errorPosition : "before",
			onError : "",
			onOk : ""
		}, params);
		
		//Extend the yav config and set the global settings
		for(var name in yavC){
			window[name]=yavC[name];
		}
		
		var yav_defRules = new Array(
			"alnumhyphen","alnumhyphenat","alphabetic","alphanumeric","alphaspace",
			"date","date_le","date_lt","double","email","empty","equal","integer",
			"keypress","maxlength","minlength","notequal","numeric","numrange",
			"regexp","required"
		);
		
		/*
		 * Creates YAV array rules from the form 
		 */
		function setRules(o){
			var rules = new Array();
			var conds = new Array();
			var str_rule = "";
			
			if (jQuery(o).is("form")){
				jQuery("input, textarea, select", o).each(function(){
					m = this.className.match(/\{.*\}/);
					if (m != null){
						$(this).attr("alt", m);
						this.className = this.className.replace(/\{.*\}/,"");
					}
					var f_alt = {};
					try{
						f_alt = eval("(" + $(this).attr("alt") + ")");
						f_alt = (typeof f_alt == "undefined")?{}:f_alt;
					}catch(e){}
					
					var the_rule = setRules(this);
					
					for (var j=0;j<the_rule.length;j++){
						try{
							var condition = f_alt.condition;
							var require_condition = f_alt.require;
							if (typeof condition != "undefined"){
								if (typeof condition.name != "undefined"){
									condition = [condition]; //converts object in array
								}
								var cond_index = "";
								for (var i=0; i < condition.length; i++){
									if (typeof conds[condition[i].name] != "undefined"){
										conds[condition[i].name].indexes.push(((cond_index == "")?cond_index = rules.push(the_rule[j]):cond_index) - 1);
										if (typeof require_condition != "undefined" && require_condition == "post-condition"){
											conds[condition[i].name].postcondition = conds[condition[i].name].indexes.length - 1;
										}
									}else{
										conds[condition[i].name] = {
											id:((typeof condition[i].id == "undefined")?this.id:condition[0].id),
											type:condition[i].type,
											msg:condition[i].msg,
											indexes: [((cond_index == "")?cond_index = rules.push(the_rule[j]):cond_index) - 1],
											require: ((typeof condition[i].require == "undefined")?null:condition[i].require),
											group: ((typeof condition[i].group != "undefined")?condition[i].group:null),
											postcondition: ((typeof require_condition != "undefined" && require_condition == "post-condition")?0:null)
										}
									}
								}
							}else{
								//doesn't check null value because if eval works this object has a rule
								rules.push(the_rule[j]);
							}
						}catch(e){
							if (the_rule[j] != null){
								rules.push(the_rule[j]);
							}
						}
					}
					
		            if (the_rule[0] != null && typeof(f_alt.event) != "undefined"){
		              this.yavrules = the_rule;
		              var yavhandler = function(){
		                resetMsgs();
		                var parent_form = $(this).parents("form");
		                if (!performCheck(parent_form[0].id, this.yavrules,'jsVar')){
		                  showErrors(parent_form[0]);
		                }
		              }
		              var fieldevents = f_alt.event.replace(" ","").split(",");
		              for (var e=0; e<fieldevents.length;e++){
		                $(this).bind(fieldevents[e], yavhandler);
		              }
		            }
				});
				
				//Sets the conds
				var conditional_rule = "";
				for (var name in conds){
					if (conds[name].group == null){						
						if (conds[name].postcondition != null){
							conds[name].indexes.push(conds[name].indexes[conds[name].postcondition]);
							conds[name].indexes.splice(conds[name].postcondition,1);
						}
						conds[name].indexes = conds[name].indexes.reverse();
						conditional_rule = conds[name].indexes.pop() + "|" + 
										   conds[name].type + "|" + strParams(conds[name].indexes,"-") +
										   "|" + ((conds[name].require == null)?"{id:'"+conds[name].id+"',msg:'"+conds[name].msg+"'}":conds[name].require);
						conds[name].rule_index = rules.push(conditional_rule) - 1;
					}
				}
				//Set the conds over conds (groups)
				for (var name in conds){
					if (conds[name].group != null){
						//get the first index
						conds[name].group = conds[name].group.reverse();
						conditional_rule = conds[conds[name].group.pop()].rule_index + "|" +
										   conds[name].type + "|";
						for (var i=0; i<conds[name].group.length;i++){
							conds[name].group[i] = conds[conds[name].group[i]].rule_index;
						}
						conditional_rule += strParams(conds[name].group,"-") + 
											"|" + ((conds[name].require == null)?"{id:'"+conds[name].id+"',msg:'"+conds[name].msg+"'}":conds[name].require);
						rules.push(conditional_rule);
					}	
				}
				
				return rules;
			}else{
				var arr_rules = new Array();
				var num_rules = 0;
				for(var i=0;i<yav_defRules.length;i++){
					if(jQuery(o).is("."+yav_defRules[i])){	
						try{
							str_rule = 
								createRule(o,yav_defRules[i],(jQuery(o).attr("title")),((typeof eval("("+jQuery(o).attr("alt")+")").params != "undefined" && typeof eval("("+jQuery(o).attr("alt")+")").params[0] == "object")?eval("("+jQuery(o).attr("alt")+")").params[num_rules]:eval("("+jQuery(o).attr("alt")+")").params),eval("("+jQuery(o).attr("alt")+")").require);
						}catch(e){
							str_rule =
								createRule(o,yav_defRules[i],(jQuery(o).attr("title")));
						}
						arr_rules.push(str_rule);
						num_rules++;
					}
				}
				var rulename;
				for(rulename in jQuery.yav_customfunctions){
					if(jQuery(o).is("."+rulename)){
						try{
							str_rule =
								createRule(o,"jQuery.yav_customfunctions."+rulename,(jQuery(o).attr("title")),((typeof eval("("+jQuery(o).attr("alt")+")").params[0] == "object")?eval("("+jQuery(o).attr("alt")+")").params[num_rules]:eval("("+jQuery(o).attr("alt")+")").params),eval("("+jQuery(o).attr("alt")+")").require);
						}catch(e){
							str_rule =
								createRule(o,"jQuery.yav_customfunctions."+rulename,(jQuery(o).attr("title")));
						}
						arr_rules.push(str_rule);
						num_rules++;
					}
				}
			}
			
			return ((arr_rules.length > 0)?arr_rules:[null]);
		}
		
		function createRule(o, rulename, text, rule_params, require){
			if (typeof rule_params != "undefined" && typeof rule_params != "object"){
				rule_params = [rule_params];
			}else if(typeof rule_params == "undefined"){
				rule_params = [];
			}
			if (rulename.indexOf("jQuery.yav") >= 0){
				return rulename+"({id:'" + o.id + "',msg:'" + text + "'"+((typeof(require) == "undefined")?"":",require:'"+require+"'") +"}"+
						((rule_params.length == 0)?"":",") + 
						strParams(rule_params, ",") +")|custom";
			}else{
				return o.id+"|"+rulename+"|" + ((rule_params.length > 0)?(strParams(rule_params,"-")+"|"):"") + ((typeof(require) == "undefined")?"{id:'"+o.id+"',msg:'"+text+"'}":require);
			}
		}
		
		function strParams(arrParam, separator){
			var str = "";
			for (var i=0;i<arrParam.length;i++){
				str += ((separator == "-")?"":"'") + arrParam[i] + ((separator == "-")?"":"'") + separator;
			}
			return str.substr(0, str.length -1);
		}
		
		function showErrors(o){
			var error_is_shown = new Array();
			jQuery(params.errorTag + "."+params.errorClass,o).remove();
			
			jQuery("#"+params.errorDiv).html(
				"<" + params.errorTag + " class='"+params.errorClass+"'>" + params.errorMessage + "</" + params.errorTag + ">"
			);
			
			//shows the errors
			for (var i=0; i<jsErrors.length;i++){
				objError = (typeof(jsErrors[i]) == "object")?jsErrors[i]:eval("("+ jsErrors[i] +")");
				if (typeof error_is_shown[objError.id] =="undefined" && typeof objError.require == "undefined"){
					error_is_shown[objError.id] = 1;
					evalText = "jQuery('#"+ objError.id +"')." + params.errorPosition + 
								"(\"" + 
								"<" + params.errorTag + " class='"+params.errorClass+"'>" + objError.msg + "</" + params.errorTag + ">"
								+ "\")";
					eval(evalText);
					jQuery("#"+objError.id).addClass(inputclasserror);
				}
			}
			
			if (jQuery("#"+params.errorDiv).size()>0){
				jQuery("#"+params.errorDiv)[0].scrollIntoView(true);	
			}
		}
		
		function resetMsgs(){
	      jQuery("#"+yavC.errorsdiv).remove();
	      jQuery("#"+params.errorDiv).html("");
	      jQuery(params.errorTag + "."+params.errorClass,this).remove();
	      jQuery("body").append("<div id='"+yavC.errorsdiv+"'></div>");
	      jQuery("."+yavC.inputclasserror).removeClass(yavC.inputclasserror);
		}
		
		//Extends the custom functions in jQuery Object
		jQuery.yav_customfunctions = params.custom;
		
		//creates the rules
		return this.each(function(){
	      	setRules(this);
			jQuery(this).bind("submit",function(){
				resetMsgs();
				var formRules = setRules(this);
				if (formRules.length == 0 || performCheck(this.id, formRules,'jsVar')){
					return ((typeof params.onOk == "function")?params.onOk(this):true);
				}else{
					showErrors(this);
					return ((typeof params.onError == "function")?params.onError(this):false);
				}
			});
		});
	}
});

if (typeof(deleteInline) == "function"){
  //Patches YAV > 1.4.0
  jQuery.deleteInline = deleteInline;
  deleteInline = function(msg){
    if(typeof(msg) == "string"){ return jQuery.deleteInline(msg); }else{ return msg; }
  }
}else{
  //Patches YAV for multiples classNames for YAV < 1.4.0
  function highlight(el, clazz) {}
}