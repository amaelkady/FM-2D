# Report - convert a dict or csv into an HTML table

if {[info exists argv0] && ([info script] eq $argv0)} {
    lappend auto_path [file dirname [file normalize [info script]]] ../Utilities/ ../extensions/
}

package require Debug
Debug define report 10
package require Html

package provide Report 1.0

set ::API(Utilities/Report) {
    {
	Report generator - turns tcl dicts and csv strings into lovely HTML tables
    }
}


namespace eval ::Report {
    variable defaults {
	rc 0
	sortable 0
	armour 0
	evenodd 1
	odd odd
	even even
	rowp {}
	htitle 1
	ftitle 1
    }

    # header: process header args in report dict into HTML within report dict
    # header - list of report column headers
    # hclass - report header CSS class
    # headerp - dict mapping header to parameters for that element,
    #	including optonal title to display for that header
    # htitle - string totitle headers
    proc header {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	variable defaults; set args [dict merge $defaults $args]
	Debug.report {header $args}

	# header and headers are synonyms
	if {![dict exists $args header]} {
	    if {![dict exists $args headers]} {
		return $args
	    }
	    dict set args header [dict get $args headers]
	    # dict unset args headers?
	}
	
	set h {}
	foreach t [dict get $args header] {
	    if {[dict get? $args hclass] ne ""} {
		dict lappend params class [dict get $args hclass]
	    } else {
		set params {}
	    }

	    if {[dict exists $args headerp] && [dict exists $args headerp $t]} {
		set thead [dict get $args headerp $t]
		if {[dict exists $thead title]} {
		    set htext [dict get $thead title]
		    dict unset thead title
		} else {
		    set htext $t
		}
		lappend params {*}$thead
	    } else {
		set htext $t
	    }

	    if {[dict get? $args htitle] ne ""} {
		set htext [string totitle [string trim $htext _]]
	    }
	    lappend h [<th> {*}$params {*}[dict get? $args hparam] $htext]
	}
	dict append args _header [<thead> {*}[dict get? $args thparam] \n[<tr> {*}[dict get? $args thrparam] \n[join $h \n]\n]\n]
	
	# by default, headers and footers are the same
	if {[dict exists $args footer] &&
	    [dict get $args footer] eq ""
	} {
	    dict set args footer [dict get $args header]
	}
	dict unset args header

	return $args
    }

    # footer: process footer args in report dict into HTML within report dict
    # footer - list of report column footers
    # fclass - report footer CSS class
    # ftitle - [string totitle] each footer?
    # footerp - dict mapping footer to parameters for that element,
    #	including optonal title to display for that footer
    proc footer {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	variable defaults; set args [dict merge $defaults $args]
	Debug.report {footer $args}

	if {[dict exists $args footer]} {
	    set f {}
	    foreach t [dict get $args footer] {
		if {[dict get? $args fclass] ne ""} {
		    dict set params class [dict get $args fclass]
		} else {
		    set params {}
		}

		if {[dict exists $args footerp] && [dict exists $args footerp $t]} {
		    set tfoot [dict get $args footerp $t]
		    if {[dict exists $tfoot title]} {
			set htext [dict get $tfoot title]
			dict unset tfoot title
		    } else {
			set htext $t
		    }
		    lappend params {*}$tfoot
		}

		if {[dict get? $args ftitle] ne ""} {
		    set t [string totitle $t]
		}
		lappend f [<th> {*}$params $t]
	    }

	    dict append args _footer [<tfoot> {*}[dict get? $args tfparam] \n[<tr> {*}[dict get? $args tfrparam] \n[join $f \n]\n]\n]
	    dict unset args footer
	}

	return $args
    }

    # body: append some elements to the report
    # rclass - CSS class for body rows
    # eclass - CSS class for body elements
    # datap - parameters for body elements
    # armour - HTML armour elements?
    # evenodd - mark even and odd rows differently?
    # even - CSS class for even rows
    # odd - CSS class for odd rows
    # rowp - dict map of "columnheader,glob" to parameters for matching elements
    # lambda - lambda to apply to each body element
    # 
    proc body {data args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	variable defaults; set args [dict merge $defaults $args]
	Debug.report {body $args}

	# traverse the data an element at a time
	dict for {k v} $data {
	    # call a lambda on each row
	    set rp {}
	    if {[dict exists $args rlambda]} {
		switch -- [catch {{*}[dict get $args rlambda] $k $v} lres eo] {
		    0 { # TCL_OK
		    }
		    1 { # TCL_ERROR
			set lres [list $lres]
		    }
		    2 { # TCL_RETURN
			break
		    }
		    3 { # TCL_BREAK
			break
		    }
		    4 { # TCL_CONTINUE
			continue
		    }
		}
		set rp [lassign $lres v]
	    }

	    if {![dict exists $v ""]} {
		# add in a special element to represent the item key
		dict set v "" $k
	    }
	    
	    set row {}
	    set rparams $rp
	    if {[dict get? $args rclass] ne ""} {
		dict lappend rparams class [dict get $args rclass]
	    }
	    
	    if {[dict exists $args evenodd] && [dict get $args evenodd]} {
		dict incr args rc
		if {[dict get $args rc] % 2} {
		    dict lappend rparams class [dict get $args even]
		} else {
		    dict lappend rparams class [dict get $args odd]
		}
	    }
	    
	    # do column content string match for row parameters
	    dict for {spec val} [dict get? $args rowp] {
		set match [lassign [split $spec ,] col]
		if {[dict exists $v $col]
		    && [string match $match [dict get $v $col]]
		} {
		    lappend rparams {*}[dict get $args rowp $spec]
		}
	    }
	    
	    # now traverse the value as a dict
	    foreach th [dict get $args headers] {
		if {[dict get? $args eclass] ne ""} {
		    set params [list class [dict get $args eclass]]
		} else {
		    set params {}
		}

		if {[dict exists $args datap] && [dict exists $args datap $th]} {
		    lappend params {*}[dict get $args datap $th]
		}

		# call a lambda on each element given its table header and row
		set ep {}
		if {[dict exists $args lambda]} {
		    switch -- [catch {{*}[dict get $args lambda] $th $v} lres eo] {
			0 { # TCL_OK
			}
			1 { # TCL_ERROR
			    set lres [list $lres]
			}
			2 { # TCL_RETURN
			    break
			}
			3 { # TCL_BREAK
			    break
			}
			4 { # TCL_CONTINUE
			    continue
			}
		    }
		    set ep [lassign $lres el]
		    dict set v $th $el
		}

		if {[dict exists $v $th]} {
		    if {[dict exists $args armour] && [dict get $args armour]} {
			set datum [armour [dict get $v $th]]	;# armour elements
		    } else {
			set datum [dict get $v $th]
		    }

		    lappend row [<td> {*}$params {*}[dict get? $args eparam] {*}$ep $datum]
		} else {
		    # empty element
		    lappend row [<td> {*}$params {*}[dict get? $args eparam] {*}$ep {}]
		}
	    }

	    dict append args body [<tr> {*}$rparams {*}[dict get? $args rparam] \n[join $row \n]\n] \n
	}

	Debug.report {body done: [dict get $args body]}
	return $args
    }

    # interpolate some raw text into the body of a report
    # armour - HTML armour interpolation?
    proc interpolate {text args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	variable defaults; set args [dict merge $defaults $args]
	dict append args body $text
	Debug.report {interpolate $args}
	return $args
    }

    # returns a table with all kinds of options
    # class - table CSS class
    # header - headers for table
    # footer - footers for table
    # sortable - will table be marked as sortable?
    proc html {data args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	variable defaults; set args [dict merge $defaults $args]
	Debug.report {html $args}

	if {![dict exists $args headers]} {
	    Debug.report {Syn Headers: [dict keys [lindex [dict values $data] 0]]}
	    dict set args headers [dict keys [lindex [dict values $data] 0]]
	}

	if {![dict exists $args _header]} {
	    set args [header {*}$args]
	}

	if {![dict exists $args _footer]
	    && [dict exists $args footer]
	} {
	    set args [footer {*}$args]
	}

	set args [body $data $args]

	set classT {}
	if {[dict exists $args class]} {
	    lappend classT class [dict get $args class]
	}
	if {[dict exists $args sortable] && [dict get $args sortable]} {
	    lappend classT class sortable
	} else {
	}
	if {[dict exists $args summary]} {
	    lappend classT summary [dict get $args summary]
	} else {
	    lappend classT summary ""
	}
	set caption [dict get? $args caption]
	if {$caption ne ""} {
	    set caption [<caption> class adorn $caption]
	}

	return [<table> {*}$classT {*}[dict get? $args tparam] "
		$caption
		[dict get? $args _header]
		[<tbody> [dict get? $args body]]
		[dict get? $args _footer]
	"]
    }

    # convert a text formatted suitably for csv into a list containing:
    # header for Report and data for Report
    proc csv2dict {csv args} {
	package require csv
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	if {[dict exists $args -alternate]} {
	    set alt "-alternate"
	} else {
	    set alt ""
	}

	if {[dict exists $args sep]} {
	    set sep [dict get $args sep]
	} else {
	    set sep ,
	}
	if {[dict exists $args quote]} {
	    set quote [dict get $args quote]
	} else {
	    set quote \"
	}

	set x {}
	foreach line [split $csv \n] {
	    if {[string trim $line] eq ""} continue
	    lappend x [::csv::split {*}$alt $line $sep $quote]
	}
	set data [lassign $x h1]
	foreach h $h1 {
	    lappend header [string trim $h]
	}
	if {[dict exists $args key]} {
	    set key [lsearch $header [dict get $args key]]
	    if {$key == -1} {
		set key 0
	    }
	} else {
	    set key 0
	}

	set result {}
	foreach r $data {
	    set row {}
	    foreach h $header el $r {
		set h [string trim $h]
		set el [string trim $el]
		lappend row $h $el
	    }
	    lappend result [string trim [lindex $r $key]] $row
	}
	return [list $result headers $header]
    }

    # convert a TDBC result set into a list containing:
    # header for Report and data for Report
    proc rs2dict {rs args} {
	package require tdbc
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}

	set key [dict get? $args key]
	set rsc [$rs columns]
	set result {}
	if {$key ne ""} {
	    if {$key ni $rsc} {
		error "key '$key' does not occur in resultset '$rs' ($rsc)"
	    }
	    set unique [dict get? $args unique]

	    # ensure the key is unique across recordset
	    $rs foreach -as dicts -- record {
		set k [dict get $record $key]
		if {[dict exists $result $k]} {
		    if {$unique} {
			error "key element '$key' valued '$k' is not unique."
		    }
		} else {
		    dict set result [dict get $record $key] $record
		}
	    }
	} else {
	    set cnt -1
	    $rs foreach -as dicts -- record {
		dict set result [incr cnt] $record
	    }
	}

	return [list $result headers $rsc]
    }

    proc init {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args]
	}
	if {[llength $args]} {
	    variable {*}$args
	}
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

if {[info exists argv0] && ([info script] eq $argv0)} {
    lappend auto_path .
    package require Dict
    Report init 
    if {1} {
	set csv {name,address,phone
	    fred, 11 stone drive, 123
	    wilma, 11 stone drive, 123
	    barney, 13 stone drive, 345
	}
	set data [Report csv2dict $csv]
	set params {
	    sortable 1
	    evenodd 1
	}
	set params1 {
	    class table
	    tparam {title table}
	    hclass header
	    hparam {title column}
	    thparam {class thead}
	    thrparam {class thead}
	    fclass footer
	    tfparam {class tfoot}
	    tfrparam {class tfoot}
	    rclass row
	    rparam {}
	    eclass el
	    eparam {}
	    footer {}
	}
	set params2 {
	    footerp {name {class fname} phone {colspan 2}}
	    headerp {name {class hname} phone {colspan 2}}
	    rowp {name,fred {class fred}}
	}
	puts "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"><html><head></head><body>"
	puts [Report html {*}$data {*}$params {*}$params1 {*}$params2]
	puts "</body>\n</html>"
    }
}
