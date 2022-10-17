/*
 * jQuery Form'n'Field plug-in
 *
 * Copyright (c) 2007 BeFruit.com
 *   http://labs.befruit.com/
 *
 * Licensed under the GPL license:
 *   http://www.gnu.org/licenses/gpl.html
 */
jQuery.iField={
	version:'0.5',
	// Predefined data types, used to analyze field values and check their validity
	tDataTypes:{
		// Default data type leaving the field value without conversion
		free:{
			onInit:function(){},
			onFocus:function(){},
			getTyped:function(){return this.get();},
			setTyped:function(value){return this.set(value);}
		},
		// Converts the provided value into an integer,
		// or returns undefined if the string value is not an integer
		int:{
			onValidate:function(){return (/^\d+$/).test(this.get());},
			getTyped:function(){
				if(this.onValidate())
					return parseInt(this.get());
				else
					return undefined;
			},
			setTyped:function(value){return this.set(value===undefined?'':value.toString());}
		},
		// Converts the provided value into a float,
		// or returns undefined if the string value is not a float
		float:{
			onValidate:function(){return (/^\d+[,\.]?\d*$/).test(this.get());},
			getTyped:function(){
				var value=parseFloat(this.get());
				return value;
			},
			setTyped:function(value){return this.set(''+value);}
		},
		// The text field is valid if it matches the e-mail pattern
		email:{
			onValidate:function(){return (/^[A-Za-z0-9._-]+@[A-Za-z0-9.-]{2,}[.][A-Za-z]{2,4}$/).test(this.get());}
		}
	},
	// Predefined input types linked to the DOM element of the field.
	// Defines the methods to read and write values.
	tInputTypes:{
		// Standard textbox input (<input type="text" ...)
		textbox:{
			basicType:true,
			set:function(value){
				if(value===undefined){
					value='';
				}
				this.ctl.val(value);
				return value;
			},
			get:function(){
				return this.ctl.val();
			},
			detect:function(field){
				var ctl=jQuery('#'+field.name);
				var bDetect=ctl.length===1&&(
					(ctl[0].tagName==='INPUT'&&(ctl[0].type==='text'||ctl[0].type==='password'))||
					ctl[0].tagName==='TEXTAREA');
				if(bDetect)field.ctl=ctl;
				return bDetect;
			}
		},
		// Standard radio buttons.
		// The field name is not the control ID as for other fields, but the group name (<input type="radio" name="thisFieldId" ...).
		radiolist:{
			basicType:true,
			set:function(value){
				var ret=undefined;
				this.ctl.each(function(){
					if(this.value===value){
						this.checked=true;
						ret=value;
					}
				});
				return ret;
			},
			get:function(){
				var value=undefined;
				this.ctl.each(function(){
					if(this.checked){
						value=this.value;
					}
				});
				return value;
			},
			detect:function(field){
				var ctl=jQuery('input[type=radio][name='+field.name+']');
				var bDetect=ctl.length>0;
				if(bDetect)field.ctl=ctl;
				return bDetect;
			}
		},
		// Single check box
		checkbox:{
			basicType:true,
			set:function(value){
				if(value===undefined){
					value=false;
				}
				value=!!value;//ensure that we have a boolean
				this.ctl[0].checked=value;
				return value;
			},
			get:function(){
				return this.ctl[0].checked;
			},
			detect:function(field){
				var ctl=jQuery('#'+field.name);
				var bDetect=ctl.length===1&&ctl[0].tagName==='INPUT'&&ctl[0].type==='checkbox';
				if(bDetect)field.ctl=ctl;
				return bDetect;
			}
		},
		// Standard dropdown or single select list (<select ...><option ...)
		choicelist:{
			basicType:true,
			set:function(value){
				var ret=undefined;
				this.ctl.each(function(){
					this.selectedIndex=-1;
					for(var i=0;i<this.options.length;++i){
						if(this.options[i].value===value){
							this.selectedIndex=i;
							ret=value;
							break;
						}
					}
				});
				return ret;
			},
			get:function(){
				var i=this.ctl[0].selectedIndex;
				return(i===-1?undefined:this.ctl[0].options[i].value);
			},
			detect:function(field){
				var ctl=jQuery('#'+field.name);
				var bDetect=ctl.length===1&&ctl[0].tagName==='SELECT';
				if(bDetect)field.ctl=ctl;
				return bDetect;
			},
			changeEvents:['change']
		}
	},
	// Adds a data type to the list of predefined types.
	registerDataType:function(sDataType,settings){
		this.tDataTypes[sDataType]=jQuery.extend({
			basicType:false,
			detect:function(){return false;}
		},settings);
	},
	// Adds an input type to the list of predefined types.
	registerInputType:function(sInputType,settings){
		this.tInputTypes[sInputType]=settings;
	},
	// Creates a new field, initializes the event handlers and member methods.
	create:function(sName,settings){
		var field=jQuery.extend({name:sName},jQuery.iField,{
			inputType:'auto',
			dataType:'auto',
			focus:false,
			valid:true,
			onValidate:function(){return true;},
			onUpdateAspect:function(){},
			setInitial:this.setInitialValue,
			changeEvents:['keyup','keypress','change','click'],
			changed:this.fieldChanged
		},settings);
		field=jQuery.extend(field,this.tDataTypes.free);
		field=jQuery.extend(field,this.tDataTypes[field.dataType]);

		if(field.inputType==='auto'){
			this.detectInputType(field);
		}
		field=jQuery.extend(field,this.tInputTypes[field.inputType]);
		if(field.ctl===undefined){
			field.ctl=jQuery('#'+field.name);
		}

		field.ctl.each(function(){this.field=field;});
		field.ctl.focus(function(ev){
			var field=ev.target.field;
			field.focus=true;
			field.onUpdateAspect();
			field.onFocus();
		}).blur(function(ev){
			ev.target.field.focus=false;
			ev.target.field.onUpdateAspect();
			ev.target.field.onFocus();
		}).keypress(function(ev){
			var field=ev.target.field;
			if(ev.keyCode===13&&field.form.onSubmit!==undefined){//Enter pressed
				return field.form.onSubmit(field.form);
			}
		});
		for(var i in field.changeEvents)
			field.ctl.bind(field.changeEvents[i],function(ev){ev.target.field.changed(ev);});
		if(field.ctl.length===0){
			throw "jquery.field.create: the field \""+sName+"\" was not found.";
		}

		if(field.initialValue===undefined){
			field.initialValue=field.getTyped();
		}else{
			field.setTyped(field.initialValue);
		}
		field.dirty=false;
		return field;
	},
	// Tries to guess what is the input type of this field
	detectInputType:function(field){
		var types=jQuery.iField.tInputTypes;
		// first check for custom types (that have the basicType attribute set to false)
		for(var sType in types){
			if(types[sType].basicType===false&&types[sType].detect(field)){
				field.inputType=sType;
				return;
			}
		}
		// if no custom type matched, check for basic types
		for(var sType in types){
			if(types[sType].basicType===true&&types[sType].detect(field)){
				field.inputType=sType;
				return;
			}
		}
		throw "Field '" + field.name+"' not found."
	},
	// Cancels changes to this field, reseting it to its initial value.
	cancel:function(){
		this.setTyped(this.initialValue);
		this.dirty=false;
		this.valid=this.onValidate();
		this.onUpdateAspect();
	},
	// Called each time when the field state may have changed.
	// Its valid, dirty states and aspect are updated.
	fieldChanged:function(){
		this.onCheckDirty();
		this.valid=this.onValidate();
		this.onUpdateAspect();
		// Signal that the form is dirty
		if(this.form){
			if(this.dirty){//if this field is dirty, no need to check the whole form
				this.form.onDirtyChange(true);
			}else{
				this.form.onDirtyChange(this.form.isDirty());
			}
		}
	},
	// Defines an initial value for the field,
	// that is used when the field is cancelled or to test if it is dirty.
	setInitialValue:function(value){
		this.initialValue=this.getTyped(this.setTyped(value));
		this.dirty=false;
		this.valid=this.onValidate();
	},
	// Returns true if the current value is different from the initial value
	onCheckDirty:function(){
		return (this.dirty=(this.getTyped()!==this.initialValue));
	}
};
jQuery.iForm={
	version:'0.5',
	// Stores references to iForm objects
	tForms:{},
	// Creates a form object and instanciates field objects
	create:function(sForm,settings){
		var form=this.tForms[sForm]=jQuery.extend({
			onDirtyChange:function(){},
			onUpdateAspect:function(){},
			name:sForm,
			fields:{},
			isDirty:this.isFormDirty,
			fill:this.fill,
			read:this.read,
			cancel:this.cancel,
			saved:this.saved
		},settings);
		for(var sField in form.fields){
			var field=form.fields[sField];
			field=jQuery.extend({
				form:form,
				onUpdateAspect:form.onUpdateAspect
			},field);
			form.fields[sField]=jQuery.iField.create(sField,field);
		}
		for(var sField in form.fields)
			form.fields[sField].onInit();
		return form;
	},
	// Retrieves a form from its name
	getForm:function(sForm){
		return jQuery.iForm.tForms[sForm];
	},
	// Sets some values in the form, replacing initial values.
	// Not all values have to be provided. The fields are marked as not dirty.
	fill:function(values){
		for(var sField in values){
			var field=this.fields[sField];
			field.setInitial(values[sField]);
			field.onUpdateAspect();
		}
		this.onDirtyChange(false);
	},
	// Retrieves the values from each field, and returns an associative array where keys are field IDs
	read:function(){
		var values={};
		for(var sField in this.fields){
			var field=this.fields[sField];
			values[sField]=field.getTyped();
		}
		return values;
	},
	// Cancels all changes, reseting the field values to their initial value
	cancel:function(){
		for(var sField in this.fields){
			this.fields[sField].cancel();
		}
		this.onDirtyChange(false);
	},
	// Checks whether the form fields have been changed, compared to initial values
	// Returns true if at least one field has been changed
	isFormDirty:function(){
		this.dirty=false;
		for(var sField in this.fields){
			var field=this.fields[sField];
			this.dirty=this.dirty||field.onCheckDirty();
			if(this.dirty)break;
		}
		return this.dirty;
	},
	// Called to inform the form that its data have been saved.
	// Initial values are updated and fields are not dirty any more.
	saved:function(){
		for(var sField in this.fields){
			var field=this.fields[sField];
			field.setInitial(field.getTyped());
			field.dirty=false;
		}
		this.onDirtyChange(false);
	}
};
