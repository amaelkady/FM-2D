package provide HtmTable 1.0

# --
# Define a class to handle html tables
#
oo::class create ::HtmTable {

    constructor { args } {
		my variable tbl
		my variable attrs
		my variable cols
		my variable rows
		my variable curcol
		my variable currow
		my variable colmap

		set cols 0
		set rows 0
		set curcol 0
		set currow 0
		set colmap ""

		if { "-map" in ${args} } {
			set opt [lsearch -exact ${args} "-map"]
			set val [expr ${opt}+1]
			set colmap [lindex ${args} ${val}]
			set args [lreplace ${args} ${opt} ${val} {}]
			foreach c ${colmap} {
				lassign ${c} name alias
				lappend map ${name}
				if { ${alias} eq "" } {
					lappend hdr ${name}
				} else {
					lappend hdr ${alias}
				}	
			}
			set colmap ${map}
			if { "-headers" in ${args} } {
				set h [lsearch -exact ${args} "-headers"]
				set args [lreplace ${args} ${h} ${h} {}]
				my headers ${hdr}
			}	
		}
		
		set attrs  ${args}
    }

	method xmlarmour { str } {
		return [string map [list & &amp\; < &lt\; > &gt\; \" &quot\; ' &\#39\; \x00 " " \x01 " " \x02 " " \x03 " " \x04 " " \x05 " " \x06 " " \x07 " " \x08 " " \x0B " " \x0C " " \x0E " " \x0F " " \x10 " " \x11 " " \x12 " " \x13 " " \x14 " " \x15 " " \x16 " " \x17 " " \x18 " " \x19 " " \x1A " " \x1B " " \x1C " " \x1D " " \x1E " " \x1F " " \x7F " "] ${str}]
	}

    # --
    # 
    method headers { hlist } {
		my variable tbl
		my variable currow
		my variable colmap

		set currow 0
		if { ${colmap} eq "" } {
			foreach n ${hlist} {
				my cell ${n} incr
			}
		} else {
			foreach c ${colmap} n ${hlist} {
				my cell ${n} ${c}
			}
		}
		set tbl(0,attrs) "-headers"
		my row
	}

    # --
    # 
    method row { args } {
		my variable tbl
        my variable currow
        my variable curcol

		set curcol 0

		set currow [incr currow]

		if { ${args} ne "" } {
			set tbl(${currow},attrs) ${args}
		}
	}

    # --
    # 
    method col { col args } {
		my variable tbl
        my variable curcol

		if { ${col} eq "" } {
			return
		} elseif { ${col} eq "incr" } {
			set col [incr curcol]
		} else {
			set curcol ${col}
		}
		if { ${args} ne "" } {
			set tbl(attrs,${curcol}) ${args}
		}
	}

    # --
    # args:
	#	'args' is a list of attribute values that will be
	#	added to the 'td' element. If '-no-armour' is one
	#	of the args then it will be removed from the args
	#	list and the cell will not be armoured. 
	#
    method cell { value {col ""} args } {
		my variable tbl
        my variable curcol
        my variable currow
        my variable cols
        my variable rows
		my variable colmap

		if { ${colmap} ne "" } {
			set curcol [lsearch -exact ${colmap} ${col}]
		}

		# determine the max row/col here because the user
		# code may incr the row/col values before or after
		# a loop check and that leads to problem in the
		# render method
		if { ${currow} > ${rows} } {
			set rows ${currow}
		}
		if { ${curcol} > ${cols} } {
			set cols ${curcol}
		}

		set tbl(${currow},${curcol}) [list ${value} ${args}]

		# do optional post incr on col
		my col ${col}
    }

    # --
    # 
    method render { {armour 1} } {
		my variable tbl
        my variable cols
        my variable rows
		my variable attrs

		set html "<table ${attrs}>"
		for {set row 0} {${row}<=${rows}} {incr row} {
			set ctok td
			if { [array names tbl "${row},attrs"] ne "" } {
				set row-attrs $tbl(${row},attrs)
				if { "-headers" in ${row-attrs} } {
					set ctok th
				}
				append html "<tr>"
			} else {
				append html "<tr>"
			}
			for {set col 0} {${col}<=${cols}} {incr col} {
				set idx "${row},${col}"
				if { [array names tbl -exact ${idx}] eq "" } {
					append html "<${ctok}></${ctok}>"
				} else {
					lassign $tbl(${idx}) value attrs
					if { ${armour} eq 1 && "-no-armour" ni ${attrs} } {
						set value [my xmlarmour ${value}]
					}
					if { ${attrs} eq "" } {
						append html "<${ctok}>${value}</${ctok}>"
					} else {
						if { "-no-armour" in ${attrs} } {
							set pos [lsearch ${attrs} "-no-armour"]
							set attrs [lreplace ${attrs} ${pos} ${pos}]
						}
						if { ${attrs} eq "" } {
							append html "<${ctok}>${value}</${ctok}>"
						} else {
							append html "<${ctok} ${attrs}>${value}</${ctok}>"
						}
					}
				}
			}
			append html "</tr>\n"
		}
		append html "</table>\n"
		return ${html}
	}

    # --
    # 
    method list2table { alist {numcols 5} {armour 1} } {
		set len [llength ${alist}]
		if { ${len} == 0 } {
			return ""
		}
		if { [llength ${alist}] < ${numcols} } {
			set numcols [llength ${alist}]
		}
		set maxrow [expr ceil(${len}/${numcols})]
		set i 0
		for {set r 0} {${r}<${maxrow}} {incr r} {
			for {set c 0} {${c}<${numcols}} {incr c} {
				set v [lindex ${alist} ${i}]
				my cell ${v} incr
				incr i
			}
			my row incr
		}
		return [my render ${armour}]
	}

    # --
    # 
    method array2table { ar } {
		my headers [list KEY VALUE]
		foreach idx [lsort -dictionary [array names ${ar}]] {
			my cell [armour ${idx}] incr
			my cell [armour [set ${ar}(${idx})]] incr
			my row
		}
		return [my render]
	}


}
