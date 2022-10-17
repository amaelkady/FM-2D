package provide Introspect 1.0

package require OO
package require HtmTable
package require Indent

# -- Introspect
# This namespace is a handler for the /introspect/ Direct domain.
class create Introspect {

	# -- /
	#
	method / {r args} {
		set content {
			<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
			<html>
			<head>
			<title>Server Introspect</title>
			</head>
			<body>
		}

		append content {
			<h1>Server Introspection</h1>
			<ul>
			<li>View image library (<a href='/introspect/imglib?size=16x16'>16x16</a>, <a href='/introspect/imglib?size=24x24'>24x24</a>, <a href='/introspect/imglib?size=48x48'>48x48</a>)</li>
			<li>Find out what has been <a href='/introspect/pkg'>loaded</a> into the main interp.</li>
			<li>View the current URL to Domain <a href='/introspect/map'>mappings</a>.</li>
			<li>View the contents of a WUB <a href='/introspect/req'>request</a> structure.</li>
			<li>View the global name space and start <a href='/introspect/ns/'>introspecting</a> WUB code.</li>
			</ul>
			</body>
			</html>
		}
		return [Http Ok $r $content text/html]
	}

	# -- /imglib
	#
	method /imglib {r size args} {
		variable home
		if { ${size} eq "" } {
			set content "<h3>Select Image Library</h3>"
			set t [HtmTable new "border='1'" -headers]
			${t} headers {{image size}}
			foreach s {16x16 24x24 48x48} {
				${t} cell "<a href='/introspect/imglib?size=${s}'>${s}</a>" incr -no-armour
				${t} row
			}
			append content [${t} render]
			${t} destroy
			return [Http Ok $r $content]
		}
		set path [file join $home images ${size}]
		set content "<center><h2>${size} Images</h2></center><hr>"
		set cwd [pwd]
		cd ${path}
		set t [HtmTable new "border='0'"]
		set col 1
		set maxcol 8
		foreach name [lsort -dictionary [glob *.png]] {
			${t} cell "[my CreateImg "${size}/${name}"]<p>${name}" incr -no-armour align=center
			if { ${col} > ${maxcol} } {
				${t} row incr
				set col 0
			}
			incr col
		}
		append content [${t} render]
		${t} destroy
		cd ${cwd}
		return [Http Ok [Http Cache $r] ${content}]
	}
	# -- /images
	#
	method /images {r} {
		set extra [split [dict get ${r} -extra] /]
		variable home
		set path [file join $home images {*}${extra}]
		return [Http CacheableFile $r ${path} text/html]
	}

	# -- /pkg
	#
	method /pkg {r args} {
		# display stuff loaded using the 'load' command
		set content "<h3>These are items that were loaded using the 'load' command.</h3>"
		set t [HtmTable new "border='1'"]
		${t} headers {package version path}
		set alist {}
		foreach a [info loaded] {
			lassign ${a} p n
			if { ${p} eq "" } {
				set p "{built in}"
			}
			if { [catch {set v [package require ${n}]} v] } {
				set v "?"
			}
			lappend alist [list ${n} ${v} ${p}]
		}
		set alist [lsort -dictionary ${alist}]
		foreach a ${alist} {
			lassign ${a} n v p
			${t} cell ${n} incr
			${t} cell ${v} incr
			${t} cell ${p} incr
			${t} row incr
		}
		append content [${t} render]
		${t} destroy

		# display packages
		append content "<h3>This is a list of all the packages that have been loaded</h3>"
		set t [HtmTable new "border='1'"]
		${t} headers {package versions}
		set alist {}
		foreach p [package names] {
			if { ![catch {package present ${p}} v] } {
				lappend alist [list ${p} ${v}]
			}
		}
		set alist [lsort -dictionary ${alist}]
		foreach a ${alist} {
			lassign ${a} p v
			${t} cell ${p} incr
			${t} cell ${v} incr
			${t} row incr
		}
		append content [${t} render]
		${t} destroy
		return [Http Ok $r ${content}]
	}

	# -- /sourced
	#
	method /sourced {r args} {
		# display stuff loaded using the 'source' command
		append content "<h3>The following files were sourced in the order shown.<br>(Note: Some files are sourced more than once.)</h3>"
		set t [HtmTable new "border='1'"]
		${t} headers {path}
		foreach p $::__source_log {
			${t} cell "<a href='pkg/view?path=${p}'>${p}</a>" incr -no-armour
			${t} row incr
		}
		append content [${t} render]
		${t} destroy
		return [Http Ok $r ${content}]
	}

	# -- /pkg/view
	#
	method /pkg/view {r path args} {
		set fid [open ${path} r]
		set raw [read ${fid}]
		close ${fid}
		set buffer [Indent code ${raw} ]
		set content [Indent code2html ${path} ${buffer}]
		return [Http Ok $r ${content}]
	}

	# --
	#
	method CreateImg { img args } {
		set attrs [dict create border 0]
		append content "<img src='images/${img}'"
		foreach arg ${args} {
			lassign [split ${arg} {=}] attr val
			set val [string trim ${val} \'\"]
			dict set attrs ${attr} ${val}
		}
		dict for {attr val} ${attrs} {
			append content " ${attr}='${val}'"
		}
		append content " >"
		return ${content}
	}

	# --
	#
	method CreateImgLink { img href args } {
		set attrs [dict create border 0]
		set imglnk "<a href='${href}'>"
		append imglnk [my CreateImg ${img} ${args}]
		append imglnk "</a>"
		return ${imglnk}
	}

	# -- /map
	#
	# This method displays the contents of the nubs ::Nub::urls variable.
	#
	method /map {r args} {
		set content "<h3>URL to Domain mappings</h3>"
		set names {{pattern url} domain body section}
		set t [HtmTable new "border='1'" -map ${names} -headers]
		foreach {k a} $::Nub::urls {
			${t} cell ${k} pattern
			foreach {n v} ${a} {
				${t} cell ${v} ${n}
			}
			${t} row
		}
		append content [${t} render]
		${t} destroy
		return [Http Ok $r $content]
	}

	# -- /req
	#
	# This method displays the content of the current request.
	#
	method /req {r args} {
		if { [dict get ${r} -extra] eq "help" } {
			variable home
			set path [file join $home help request_dict.html]
			return [Http CacheableFile $r ${path} text/html]
		}
		return [Http Ok $r [my dump_req ${r}]]
	}

	# -- req_help
	#
	method req_help { } {
		set help {


		}
	}

	# -- dump_req
	#
	# This method displays the content of the current request dict.
	#
	method dump_req { r } {
		set keys [lsort -dictionary [dict keys ${r}]]
		append content "</br><h2>CURRENT REQUEST [my CreateImgLink 16x16/About.png req/help]</h2>"
		append content {<p>
			The table below conatins the contents of the request that is
			currently being processed. For more information about the
			request sturcture in WUB, click on the info icon.
			</p>
		}
		set t [HtmTable new "border='1'"]
		foreach k ${keys} {
			set v [dict get ${r} ${k}]
			${t} col 0
			${t} cell ${k} incr
			${t} cell ${v}
			${t} row incr
		}
		append content [${t} render]
		${t} destroy
		return ${content}
	}

	# -- /ns
	#
	# This method displays the content of a namespace.
	#
	method /ns {r args} {
		set ns [split [dict get ${r} -extra] /]
		set content [my dump_ns ${r} ${ns}]
		return [Http Ok $r ${content}]
	}

	method GetNumCols { alist page_width } {
		set maxwidth 0
		if { [llength ${alist}] == 0 } { return 1 }
		foreach a ${alist} {
			set awidth [string length ${a}]
			if { ${awidth} > ${maxwidth} } {
				set maxwidth ${awidth}
			}
		}
		return [expr floor(${page_width}/${maxwidth})]
	}

	method GetCommandType { cmd } {
		set cmd [string trimleft ${cmd} :]
		set x "{[regsub -all {::} ${cmd} "} {"]}"
		set ns [join ::[lrange ${x} 0 end-1] "::"]
		set cmd ::${cmd}
		set clist [lsort -dictionary [namespace children ${ns}]]
		set plist [lsort -dictionary [info procs ${cmd}]]
		set nlist [lsort -dictionary [interp aliases {}]]
		if { ${cmd} in ${clist} } {
			# command is ensembled namespace
			if { [info object isa object ${cmd}] } {
				return "obj"
			} else {
				return "ensemble"
			}
		} elseif { [llength [info procs ${cmd}]] > 0 } {
			return "proc"
		} elseif { [info object isa object ${cmd}] } {
			if { [info object isa class ${cmd}] } {
				return "class"
			} elseif { [info object isa metaclass ${cmd}] } {
				return "metaclass"
			} else {
				return "obj"
			}
		} elseif { [string trimleft ${cmd} :] in ${nlist} } {
			return "alias"
		}
		return "builtin"
	}

	method GetCommandLink { cmd {prefix ""} } {
		variable built-in-commands
		set ctype [my GetCommandType ${cmd}]
		if { ${prefix} ne "" } {
			set prefix "{${ctype}}"
		}
		set href [string trimleft ${cmd} {:}]
		switch -exact -- ${ctype} {
			"ensemble" {
				return "<font color='orange'>${prefix}</font>&nbsp;<a href='${href}'>[xmlarmour "${cmd}"]</a>"
			}
			"proc" {
				return "{proc}&nbsp;<a href='cmd?name=${cmd}'>[xmlarmour "${href}"]</a>"
			}
			"class" {
				return "<font color='red'>${prefix}</font>&nbsp;<a href='class?obj=${href}'>[xmlarmour "${cmd}"]</a>"
			}
			"metaclass" {
				return "<font color='red'>${prefix}</font>&nbsp;<a href='class?obj=${href}'>[xmlarmour "${cmd}"]</a>"
			}
			"obj" {
				return "<font color='red'>${prefix}</font>&nbsp;<a href='obj?obj=${href}'>[xmlarmour "${cmd}"]</a>"
			}
			"alias" {
				return "<font color='tan'>${prefix}</font>&nbsp;<a href='alias?token=${href}'>[xmlarmour "${cmd}"]</a>"
			}
			default {
				lassign [string map {"::" { }} ${href}] prefix name
				if { ${prefix} eq "tcl" } {
					return "<a href='http://www.tcl.tk/man/tcl8.6/TclCmd/${name}.htm'>[xmlarmour "${href}"]</a>"
				} elseif { ${prefix} in ${built-in-commands} } {
					return "<a href='http://www.tcl.tk/man/tcl8.6/TclCmd/${prefix}.htm'>[xmlarmour "${href}"]</a>"
				}
				# must be a package subcommand
				return [xmlarmour "${href}"]
		}}
	}

	# -- dump_ns
	#
	method dump_ns {r NS} {

		set ns ${NS}
		if { [string equal -length 2 ${NS} "::"] == 0 } {
			set ns "::${NS}"
		}
		set content ""
		append content "<h2>INTROSPECTION FOR NAMESPACE (${ns})</h2>"

		if { [namespace exists ${ns}] == 0 } {
			append content "<p> NOT FOUND"
			return [Http Ok $r ${content}]

		}

		if { [string range ${ns} end-1 end] eq "::" } {

			set pat ${ns}*
		} else {

			set pat ${ns}::*
		}

		# namespaces
		append content "<h3>CHILD NAMESPACES</h3>"
		set alist ""
		set clist [lsort -dictionary [namespace children ${ns}]]
		set numcols [my GetNumCols ${clist} 120]

		foreach k ${clist} {
			lappend alist "<a href='${k}'>[xmlarmour ${k}]</a>"
		}
		if { ${alist} eq "" } {
			append content "<p>&nbsp;&nbsp;&nbsp;&nbsp;{NO-CHILD-NAMESPACES}</p>"
		} else {
			set t [HtmTable new "border='1'"]
			append content [${t} list2table ${alist} ${numcols} no_armour]
			${t} destroy
		}

		# commands
		append content "<h3> COMMANDS </h3>"
		set alist ""
		set alist [lsort -dictionary [info commands ${pat}]]
		set numcols [my GetNumCols ${alist} 100]
		if { ${alist} eq "" } {
			append content "<p>&nbsp;&nbsp;&nbsp;&nbsp;{NONE}</p>"
		} else {
			set hlist ""
			foreach k ${alist} {
				lappend hlist [my GetCommandLink ${k} prefix]
			}
			set t [HtmTable new "border='1'"]
			append content [${t} list2table ${hlist} ${numcols} no_armour]
			${t} destroy
		}

		# variables
		append content "<h3>VARIABLES</h3>"
		set vlist [lsort -dictionary [info vars ${pat}]]
		if { ${vlist} eq "" } {
			append content "<p>&nbsp;&nbsp;&nbsp;&nbsp;{NONE}</p>"
		} else {
			set t [HtmTable new "border='1'"]
			foreach k ${vlist} {
				${t} col 0
				if { ${k} eq "" } {
					${t} cell "{NULL}" incr
				} else {
					${t} cell ${k} incr
				}
				if { [array exists ${k}] == 1 } {
					# insert table of array values
					set ta [HtmTable new "border='0'"]
					set str [${ta} array2table ${k}]
					${ta} destroy
					${t} cell ${str} incr -no-armour
				} else {
					if { [catch {set v [set ${k}]} msg ] } {
						${t} cell "{VALUE-NOT-SET}" incr
					} else {
						${t} cell ${v} incr
					}
				}
				${t} row
			}
			append content [${t} render]
			${t} destroy
		}

		return ${content}
	}

	method CleanCode { code {inset 1} } {
		set str ${code}
		set str [Indent code ${str} -inset ${inset}]
		set str [string map {"\t" {    }} ${str}]
		return [armour ${str}]
	}

	# -- /ns/cmd
	#
	method /ns/cmd {r args} {
		set a [dict create {*}${args}]
		set name [dict get ${a} name]
		set cargs [info args ${name}]
		set content "<h2> COMMAND ([armour ${name}])</h2>"
		append content "<pre><font color='red'>proc</font>&nbsp;[armour [string trimleft ${name} :]]&nbsp;{&nbsp;${cargs}}&nbsp;{ [my CleanCode [info body ${name}]]\n}</pre>"
		return [Http Ok $r ${content}]
	}

	method GetClassMethodDef {class method} {
		# check for method in the object first
		if { [catch {info class definition ${class} ${m}} def] == 0 } {
			lassign ${def} params body
			return "<pre><font color='red'>method</font> [armour ${method}] { [armour ${params}] } { [my CleanCode ${body}]\n    }</pre>"
		} elseif { [catch {info class forward ${class} ${m}} def] == 0 } {
			return "<pre><font color='red'>forward</font> [armour ${method}] { ${def} }</pre>"
		} elseif { ${method} in [info class methods ${class} -all] } {
			if { [catch {info class definition ${class} ${method}} def] == 0 } {
				lassign ${def} params body
				set content "<pre><font color='red'>method</font> [armour ${method}] { [armour ${params}] } { [my CleanCode ${body}]\n    }</pre>"
				return ${content}
			} else {
				return "<pre><font color='red'>method</font> [armour ${method}] { <font color='red'>OPAQUE</font> }</pre>"
			}
		} else {
			return "<pre><font color='red'>method</font> [armour ${method}] { <font color='red'>UNKNOWN</font> }</pre>"
		}
	}

	# -- /ns/class
	#
	method /ns/class {r args} {
		set a [dict create {*}${args}]
		set obj [dict get ${a} obj]

		set content "<h2>CLASS INSTANCES</h2>"
		set clist ""
		set instances [info class instances  ${obj}]
		if { [llength ${instances}] == 0 } {
			append content "{NONE}"
		} else {
			foreach c ${instances} {
				lappend clist [my GetCommandLink ${c}]
			}
			set ta [HtmTable new "border='1'"]
			append content "<dl><dd>"
			append content [${ta} list2table ${clist} 8 no_armour]
			append content "</dd></dl>"
			${ta} destroy
		}

		append content "<h2>SUBCLASSES</h2>"
		set clist ""
		set classes [info class subclasses ${obj}]
		if { [llength ${classes}] == 0 } {
			append content "{NONE}"
		} else {
			foreach c ${classes} {
				lappend clist [my GetCommandLink ${c}]
			}
			append content "<pre>[join ${clist} {, }]</pre>"
		}

		append content "<h2>CLASS IMPLEMENTATION</h2>"


		set class [info object class ${obj}]
		append content "<pre><font color='red'>[my GetCommandLink ${class}] create</font> [armour ${obj}] {"

			set clist ""
			set classes [info class superclasses ${obj}]
			if { ${classes} ne "" } {
				foreach c ${classes} {
					lappend clist [my GetCommandLink ${c}]
				}
				append content "<pre><font color='red'>superclass</font> [join ${clist} { }] </pre>"
			}

			set mlist ""
			set mixins [info class mixins ${obj}]
			if { ${mixins} ne "" } {
				foreach m ${mixins} {
					lappend mlist "<a href='class?obj=${m}'>[xmlarmour "${m}"]</a>"
				}
				append content "<pre><font color='red'>mixin</font> [join ${mlist} { }]</pre>"
			}

			set flist ""
			set filters [info class filters ${obj}]
			if { ${filters} ne "" } {
				foreach f ${filters} {
					lappend flist "<a href='class?obj=${f}'>[xmlarmour "${f}"]</a>"
				}
				append content "<pre><font color='red'>filter</font> [join ${flist} { }]</pre>"
			}

			set exports [info class methods ${obj}]
			if { ${exports} ne "" } {
				append content "<pre><font color='red'>export</font> [join ${exports} { }]</pre>"
			}

			set vars [info class variables ${obj}]
			if { ${vars} ne "" } {
				append content "<pre>"
				foreach v [lsort -dictionary ${vars}] {
					append content "variable&nbsp;[xmlarmour ${v}]\n"
				}
				append content "</pre>"
			}

			lassign [info class constructor ${obj}] parms code
			append content "<pre><font color='red'>constructor</font> { ${parms} } { [my CleanCode ${code}]\n    }</pre>"

			lassign [info class destructor ${obj}] parms code
			append content "<pre><font color='red'>destructor</font> ${obj} { ${parms} } { [my CleanCode ${code}]\n    }</pre>"

			foreach m [info class methods ${obj} -all] {
				append content [my GetClassMethodDef ${obj} ${m}]
			}

		append content "}"

		return [Http Ok $r ${content}]
	}

	#[15:40]	dkf	you can get a list of methods that are not errors with
	#			[info class definition], and you can get a list of methods that are
	#			not errors with [info class forward]
	#[15:40]	dkf	those will be disjoint
	#[15:40]	dkf	all others listed in [info class methods] are opaque
	#[15:41]	dkf	all others listed in [info class methods -all] are defined
	#			by superclasses

	method GetObjectMethodDef {obj method} {
		# check for method in the object first
		if { [catch {info object definition ${obj} ${m}} def] == 0 } {
			lassign ${def} params body
			return "<pre><font color='red'>method</font> [armour ${method}] { [armour ${params}] } { [my CleanCode ${body}]\n    }</pre>"
		} elseif { [catch {info object forward ${obj} ${m}} def] == 0 } {
			return "<pre><font color='red'>forward</font> [armour ${method}] { ${def} }</pre>"
		} elseif { ${method} in [info object methods ${obj}] } {
			return "<pre><font color='red'>method</font> [armour ${method}] { args } { <font color='red'>OPAQUE</font> }</pre>"
		} elseif { ${method} in [info object methods ${obj} -all] } {
			set class [info object class ${obj}]
			if { [catch {info class definition ${class} ${method}} def] == 0 } {
				lassign ${def} params body
				set content "<pre><font color='red'>method</font> [armour ${method}] { [armour ${params}] } { [my CleanCode ${body}]\n    }</pre>"
				return ${content}
			}
			foreach mixin [info object mixins ${obj}] {
				if { [catch {info class definition ${mixin} ${method}} def] == 0 } {
					return "<pre><font color='red'>method</font> [armour ${method}] in mixin [my GetCommandLink ${mixin}] </pre>"
				}
			}
			# method is defined in superclass
			while {${method} ni [info class methods ${class}]} {
				# Assume the simple case
				set class [lindex [info class superclass ${class}] 0]
				if {${class} eq {}} {
					return "<pre><font color='red'>method</font> [armour ${method}] { <font color='red'>unknown</font> }</pre>"
				}
			}
			# Assume no forwards
			lassign ${def} params body
			set content "<pre><font color='blue'># method '[armour ${method}]' found in superclass</font> [my GetCommandLink ${class}]\n"
			append content "<font color='red'>method</font> [armour ${method}] { [armour ${params}] } { [my CleanCode ${body}]\n    }</pre>"
			return ${content}
		} else {
			return "<pre><font color='red'>method</font> [armour ${method}] { <font color='red'>UNKNOWN</font> }</pre>"
		}
	}

	# -- /ns/obj
	#
	method /ns/obj {r args} {
		set a [dict create {*}${args}]
		set obj [dict get ${a} obj]

		append content "<h1>OBJECT(&nbsp;${obj}&nbsp;)</h1>"

		set class [info object class ${obj}]
		append content "<pre><font color='red'>class is:</font> [my GetCommandLink ${class}]</pre>"

		set mixins [info object mixins ${obj}]
		append content "<pre><font color='red'>mixins:</font> [armour ${mixins}]</pre>"

		set filters [info object filters ${obj}]
		append content "<pre><font color='red'>filters:</font> [armour ${filters}]</pre>"

		append content "<pre>"
		set vars [info object variables ${obj}]
		foreach var ${vars} {
			append content "<font color='red'>variable</font> ${var}\n"
		}
		append content "</pre>"

		append content "<pre>"
		append content "<font color='red'>var:</font>\n"
		append content "</pre>"
		set names {var value}
		set t [HtmTable new "border='1'" -map ${names} -headers]
		foreach n [info object vars ${obj}] {
			${t} cell ${n} var
			set fullname "[info object namespace $obj]::${n}"
			if { [array exists ${fullname}] } {
				set t2 [HtmTable new]
				foreach k [array names ${fullname}] {
					${t2} cell ${k} incr
					${t2} cell [set ${fullname}(${k})]
					${t2} row
				}
				set value [${t2} render]
				${t2} destroy
			} else {
				set value [set ${fullname}]
			}
			${t} cell ${value} value
			${t} row
		}
		append content [${t} render]
		${t} destroy

		foreach m [info object methods ${obj} -all] {
			append content [my GetObjectMethodDef ${obj} ${m}]
		}

		return [Http Ok $r ${content}]
	}

	# -- /ns/alias
	#
	method /ns/alias {r args} {
		set a [dict create {*}${args}]
		set token [dict get ${a} token]
		set content "<h2> INTERP ALIAS ([armour ${token}])</h2>"
		set more [lassign [interp alias {} [string trimleft ${token} :]] cmd]
		append content "<b>POINTS TO:</b> [my GetCommandLink "${cmd}" prefix] { [armour ${more}] }"

		return [Http Ok $r ${content}]
	}

	superclass Direct
	constructor {args} {
		variable home [file dirname [lindex [package ifneeded Introspect [package present Introspect] ] 1]]
		variable built-in-commands [lsort -dictionary [namespace children ::tcl]]
		next? {*}$args
	}
}
