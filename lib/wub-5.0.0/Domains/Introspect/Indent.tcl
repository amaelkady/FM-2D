package provide Indent 1.0

namespace eval ::Indent {

	namespace ensemble create
	namespace export code metadata code2html

	# rules
	variable _comment		{^[ \t]*\#}

	
	variable buffer ""
	variable meta [dict create]
	variable dmsg "" 
	variable ln
	variable -d
	variable spaces
	

	# -- DebugMsg
	#
	proc DebugMsg { str } {
		variable dmsg
		variable -d
		if { ${-d} == 1 } {
			append dmsg "------${str}\n"
		}
	}

	# -- buffer
	#
	proc buffer { } {
		variable buffer
		return ${buffer}
	}

	# -- metadata
	#
	proc metadata { } {
		variable metadata
		return ${metadata}
	}
	
	proc xmlarmour { str } {
		return [string map [list & &amp\; < &lt\; > &gt\; \" &quot\; ' &\#39\; \x00 " " \x01 " " \x02 " " \x03 " " \x04 " " \x05 " " \x06 " " \x07 " " \x08 " " \x0B " " \x0C " " \x0E " " \x0F " " \x10 " " \x11 " " \x12 " " \x13 " " \x14 " " \x15 " " \x16 " " \x17 " " \x18 " " \x19 " " \x1A " " \x1B " " \x1C " " \x1D " " \x1E " " \x1F " " \x7F " "] ${str}]
	}

	# -- AppendBuffer
	#
	proc AppendBuffer { str } {
		variable buffer
		variable dmsg
		variable ln
		variable -d
		if { ${dmsg} ne "" } {
			append buffer ${dmsg}
			set dmsg ""
		}
		if { ${-d} == 1 } {
			append buffer "([format "%03s" ${ln}]) [string trimright ${str} "\ \t"]"
		} else {
			append buffer [string trimright ${str} "\ \t"]
		}
	}

	# -- AppendBufferWithIndent
	#
	proc AppendBufferWithIndent { indent line } {
		variable spaces
		return [AppendBuffer [lindex ${spaces} ${indent}]${line}\n]
	}

	# -- GetBracetIndent
	#
	proc GetBracetIndent { str indent_value} {
		upvar ${indent_value} indent
		
		set lbraces [CountChars ${str} \{]
		set rbraces [CountChars ${str} \}]
		set net-braces [expr ${lbraces}-${rbraces}]
		set undent [string equal [string index ${str} 0] \}]
		set str_indent ${indent}
		if { ${net-braces} > 0 } {
			# increase undent for next str
			incr indent ${net-braces}
		} elseif { ${net-braces} < 0 } {
			# reduce indent starting with current str
			incr indent ${net-braces}
			set str_indent ${indent}
		} elseif { ${undent} } {
			set str_indent [expr ${indent}-1]
		}
		DebugMsg "lb: ${lbraces} rb: ${rbraces} nb: ${net-braces} u: ${undent} indent: $indent"
		return ${str_indent}
	}

	# -- code
	#
	# Reformat the text found in tclcode so it has a consistent
	# look and indentation.
	#
	# OPTIONS:
	# -d		debug: 1=on,0=off (default=0)
	# -o		output file name (default="")
	# -inset	initial indent level (default=0)
	# -ts		spaces per tab (default=4)
	# -ut		use tab characters (default=0)
	#
	proc code { tclcode args } {
		variable _comment
		variable buffer
		variable ln
		variable -d
		variable spaces

		set buffer ""
		
		# set option defaults
		set options {
			-d 0
			-o {}
			-inset 0
			-ts 4
			-ut 0
		}
		# override defaults from args
		foreach {opt val} ${options} {
			if { ${opt} in ${args} } {
				set val [lindex ${args} [lsearch ${args} ${opt}]+1]
			}
			set ${opt} ${val}
		}

		# split code on newlines
		set lines [split ${tclcode} \n]
		set maxln [llength ${lines}]

		set spaces ""
		if { ${-ut} == 0 } {
			# create list of spaces for each indent level
			set -ts [string repeat " " ${-ts}]
			for {set i 0} {${i}<20} {incr i} {
				lappend spaces [string repeat ${-ts} ${i}]
			}
		} else {
			# create list of tabs for each indent level
			for {set i 0} {${i}<20} {incr i} {
				lappend spaces [string repeat "\t" ${i}]
			}
		}
		
		set buffer ""		;# output buffer
		set oddquotes 0		;# string quote flag (0 = balanced, 1 = not balanced)
		set quoted 0

		set indent ${-inset}
		set current_indent ${indent}

		for {set ln 0} {${ln}<${maxln}} {incr ln} {
			set raw [lindex ${lines} ${ln}]
			set line [string trim ${raw} "\ \t"]

			# blank line
			if { ${line} eq "" } {
				AppendBuffer \n
				continue
			}

			# full line comment
			if { [regexp ${_comment} ${line}] } {
				DebugMsg "# ...comment line"
				AppendBufferWithIndent ${indent} ${line}
				continue
			}
			
			# handle quote string
			set oddquotes [expr {[CountChars $line \"] % 2}]
			if { ${quoted} == 0 && ${oddquotes} == 1 } {
				# indent first line of quote
				set quoted 1
				DebugMsg "# ...quote start"
				# ajust indent based on text before first quote
				set current_indent ${indent}
				set str [string trimleft ${raw} "\ \t"]
				set i [string first \" ${str}]
				if { ${i} > 0 } {
					set current_indent [GetBracetIndent [string range ${str} 0 ${i}] indent]
				}
				AppendBufferWithIndent ${current_indent} ${str}
				continue
			} elseif { ${quoted} == 1 && ${oddquotes} == 1 } {
				set quote_start 0
				set quoted 0
				DebugMsg "# ...quote end"
				AppendBuffer ${raw}\n
				continue
			} elseif { ${quoted} == 1 } {
				set quote_start 0
				DebugMsg "# ...quote"
				AppendBuffer ${raw}\n
				continue
			}

			# quotes are balances so ajust the line indent
			set current_indent [GetBracetIndent ${line} indent]
			
			if { ${indent} < 0 } {
				DebugMsg "ERROR: unbalanced left braces - indent=${indent}"
				AppendBuffer ${raw}\n
				if { ${-o} ne "" } {
					set fid [open ${-o} w]
					puts ${fid} ${buffer}
					close ${fid}
				}
				
				error "${buffer}\nunbalanced left braces"
			}
			
			AppendBufferWithIndent ${current_indent} ${line}
		}

		# check to see if we returned to our initial indent level
		if { ${indent} > ${-inset} } {
			DebugMsg "ERROR: unbalanced right braces - indent=${indent} -inset=${-inset}"
			AppendBuffer \n
			if { ${-o} ne "" } {
				set fid [open ${-o} w]
				puts ${fid} ${buffer}
				close ${fid}
			}
			error "unbalanced right braces"
		}

		# write result to file if requested
		if { ${-o} ne "" } {
			set fid [open ${-o} w]
			puts ${fid} [string trimright ${buffer} "\n"]
			close ${fid}
		}

		set buffer [string trimright ${buffer} "\n"]
		
		return ${buffer}
	}

	# --
	#
	# Return the number of 'char' characters in string 'str'.
	#
	proc CountChars {str char} {
		set count 0
		while { [set idx [string first ${char} ${str}]] >= 0 } {
			set backslashes 0
			set nidx ${idx}
			while { [string equal [string index ${str} [incr nidx -1]] \\] } {
				incr backslashes
			}
			if {${backslashes} % 2 == 0} {
				incr count
			}
			set str [string range ${str} [incr idx] end]
		}
		return ${count}
	}

	# --
	#
	# Create an html page for tclcode
	#
	proc code2html { filename tclcode  } {
		variable buffer
		variable meta

		set meta [dict create -file ${filename} -provide {} -require {} -namespace {} -proc {}]
		set buffer "<html>"
		append buffer {
			<header>
			<script type="text/javascript" src="http://wiki.tcl.tk/sh_main.js"></script>
			<script type="text/javascript" src="http://wiki.tcl.tk/lang/sh_tcl.js"></script>
			<link type="text/css" rel="stylesheet" href="http://wiki.tcl.tk/css/sh_style.css">	
			</header>
		}
		append buffer "<body onload='sh_highlightDocument();'>\n"
		append buffer "<pre class='sh_tcl' style='background-color: #ffffff;'>"

		set _req_pat {^[ \t]*package[ \t]+require[ \t]+([^ \t$]+)([ \t]+[.0-9]+)?.*}
		set _pro_pat {^[ \t]*package[ \t]+provide[ \t]+([^ \t$]+)([ \t]+[.0-9]+)?.*}
		set _ns_pat {^[ \t]*namespace[ \t]+eval[ \t]+([^ \t]+)[ \t].*}
		set _proc_pat {^[ \t]*proc[ \t]([^ \t$]+)[ \t].*}
		
		foreach line [split ${tclcode} \n] {
			switch -regexp -- ${line} {
				
				{^[ \t]*package[ \t]+require[ \t].*} {
					# extract 'package require ...' statements
					#puts stderr "@${line}"
					regexp ${_req_pat} ${line} m0 pkg ver
					if { ${ver} eq "" } {
						dict lappend meta -require ${pkg}
					} else {
						dict lappend meta -require "${pkg} ${ver}"
					}
					append buffer [xmlarmour ${line}]\n
				}
				
				{^[ \t]*package[ \t]+provide[ \t].*} {
					# extract 'package provide ...' statements
					#puts stderr "@${line}"
					regexp ${_pro_pat} ${line} m0 pkg ver
					if { ${ver} eq "" } {
						dict lappend meta -provide ${pkg}
					} else {
						dict lappend meta -provide "${pkg} ${ver}"
					}
					append buffer [xmlarmour ${line}]\n
				}
				
				{^[ \t]*namespace[ \t]+eval[ \t].*} {
					# extract 'namespace eval ...' statements
					#puts stderr "@${line}"
					regexp ${_ns_pat} ${line} m0 ns
					if { [string first "\$" ${ns}] == -1 } {
						dict lappend meta -namespace "${ns}"
					}
					append buffer [xmlarmour ${line}]\n
				}
				
				{^[ \t]*proc[ \t]+[^ \t]+[ \t].*} {
					# extract 'proc ...' statements
					#puts stderr "@${line}"
					regexp ${_proc_pat} ${line} m0 name
					dict lappend meta -proc ${name}
					append buffer "<a name='${name}'></a>[xmlarmour ${line}]\n"
				}

				default {
					append buffer [xmlarmour ${line}]\n
				}
			}
		}
		append buffer "</pre>"
		
		dict set meta -require [lsort -unique [dict get ${meta} -require]]
		dict set meta -provide [lsort -unique [dict get ${meta} -provide]]
		dict set meta -namespace [lsort -unique [dict get ${meta} -namespace]]
		dict set meta -proc [lsort -unique [dict get ${meta} -proc]]

		set html "<html>"
		append html {
			<header>
			</header>
		}
		append html "<body>\n"
		append html "<h2>FILE: ${filename}</h2>"

		set names {PROVIDES REQUIRES NAMESPACES PROCEEDURES}
		set t [HtmTable new "border='1'" "cellpadding='6'" -map ${names} -headers]

		set provide [dict get ${meta} -provide]
		set content ""
		if { ${provide} ne "" } {
			set content "<pre>"
			foreach p ${provide} {
				lassign ${p} pkg ver
				if { ${ver} eq "" } {
					append content "[xmlarmour ${pkg}]\n"
				} else {
					append content "[xmlarmour ${pkg}] (${ver})\n"
				}
			}
			append content "</pre>"
		}
		${t} cell ${content} PROVIDES -no-armour "valign='top'"
		
		set require [dict get ${meta} -require]
		set content ""
		if { ${require} ne "" } {
			set content "<pre>"
			foreach p ${require} {
				lassign ${p} pkg ver
				if { ${ver} eq "" } {
					append content "[xmlarmour ${pkg}]\n"
				} else {
					append content "[xmlarmour ${pkg}] (${ver})\n"
				}
			}
			append content "</pre>"
		}
		${t} cell ${content} REQUIRES -no-armour "valign='top'"
		
		set namespace [dict get ${meta} -namespace]
		set content ""
		if { ${namespace} ne "" } {
			set content "<pre>"
			foreach ns ${namespace} {
				append content "[xmlarmour ${ns}]\n"
			}
			append content "</pre>"
		}
		${t} cell ${content} NAMESPACES -no-armour "valign='top'"
		
		set proc [dict get ${meta} -proc]
		set content ""
		if { ${proc} ne "" } {
			set content "<pre>"
			foreach p ${proc} {
				append content "<a href='#${p}'>[xmlarmour ${p}]</a>\n"
			}
			append content "</pre>"
		}
		${t} cell ${content} PROCEEDURES -no-armour "valign='top'"

        append html [${t} render]
		${t} destroy

		append html "<h2>Source</h2>"
		append html ${buffer}
		append html "</body></html>"


		return ${html}
	}
	
}
