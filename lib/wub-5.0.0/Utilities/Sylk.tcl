################################################################
# Access procedures for SYLK files reading/writing
# (c) Copyright 2003 LMS Deutschland GmbH
#                    Holger Zeinert
# Modified Colin McCormack colin@chinix.com 30Jan2006
#
################################################################
# feel free to use without any warrenty
################################################################
# http://mini.net/tcl/sylk
#
# internal data structure of a SYLK file is stored in an array of dicts:
#
#   SYLK
#	id	identification of the SYLK file
#
#   	xMax
#	yMax	Boundary X and Y, i.e. maximum column and row index
#
#	header	part of the header, which is not handled; this
#		is used to write it unmodified (uninterpreted)
#		back to the file
#	picture	excel picture formats (wtf they are)
#	widths	column widths
#
#   <y>,<x>
#	value       value of cell
#	formula	formula to calculate value
#		(a cell needs a value; if a formula is given, but no value, the cell
#		will not be stored into the SYLK file)
#	format	formatstring of cell
#
################################################################

package provide Sylk 1.0

set ::API(Utilities/Sylk) {
    {
	SYLK format reading/writing

	Author: (c) Copyright 2003 LMS Deutschland GmbH Holger Zeinert
    }
}

namespace eval ::Sylk {

    proc cell {sylk yx value} {
	lassign [split $yx ,] y x

	dict set sylk $y,$x value $value

	if {$y > [dict get $sylk yMax]} {
	    dict set sylk yMax $y
	}
	if {$x > [dict get $sylk xMax]} {
	    dict set sylk xMax $x
	}

	return $sylk
    }

    # set an entire row to some value
    proc setrow {sylk row args} {
	set x 0
	foreach arg $args {
	    dict set sylk $row,[incr x] value $arg
	}
	return $sylk
    }

    # set an entire column to some value
    proc setcol {sylk col args} {
	set y 0
	foreach arg $args {
	    dict set sylk [incr y],$col value $arg
	}
	return $sylk
    }

    # format a cell y,x a row y, or a column ,x
    proc format {sylk yx format {rcops 0} {overwrite 1}} {
	lassign [split $yx ,] y x

	if {$y eq ""} {
	    # column
	    if {$rcops} {
		dict lappend sylk header "F$format;C$x"
	    } else {
		foreach idx [dict keys $sylk *,$x] {
		    set sylk [format $sylk $idx $format]
		}
	    }
	} elseif {$x eq ""} {
	    # row
	    if {$rcops} {
		dict lappend sylk header "F$format;R$y"
	    } else {
		foreach idx [dict keys $sylk $y,*] {
		    set sylk [format $sylk $idx $format]
		}
	    }
	} else {
	    # cell
	    if {[dict exists $sylk $yx]
		&& 
		($overwrite || ![dict exists $sylk $yx format])
	    } {
		dict set sylk $yx format $format
	    }
	}
	return $sylk
    }

    # format a cell y,x a row y, or a column ,x
    proc formula {sylk yx formula {overwrite 1}} {
	lassign [split $yx ,] y x

	if {$y eq ""} {
	    # column
	    foreach idx [dict keys $sylk *,$x] {
		set sylk [formula $sylk $idx $formula]
	    }
	} elseif {$x eq ""} {
	    # row
	    foreach idx [dict keys $sylk $y,*] {
		set sylk [formula $sylk $idx $formula]
	    }
	} else {
	    # cell
	    if {[dict exists $sylk $yx]
		&& 
		($overwrite || ![dict exists $sylk $yx formula])
	    } {
		if {$formula eq ""} {
		    dict unset sylk $yx formula
		} else {
		    dict set sylk $yx formula $formula
		    dict unset sylk $yx value
		}
	    }
	}

	return $sylk
    }

    # move contents of a Sylk by some amount.
    proc move {sylk iy {ix 0}} {
	set out [dict create]

	foreach f [dict keys $sylk {[a-zA-Z]*}] {
	    dict set out $f [dict get $sylk $f]
	}

	dict set out xMax [expr {[dict get $sylk xMax] + $ix}]
	dict set out yMax [expr {[dict get $sylk yMax] + $iy}]

	if {$iy >= 0} {
	    set dir -decreasing
	} else {
	    set dir -increasing
	}

	foreach idx [lsort -dictionary $dir [dict keys $sylk *,*]] {
	    lassign [split $idx ,] y x
	    dict set out \
		[expr {$y + $iy}],[expr {$x + $ix}] \
		[dict get $sylk $idx]
	}

	return $out
    }

    proc insert_row {sylk row {iy 1}} {
	set out [dict create]

	foreach f [dict keys $sylk {[a-zA-Z]*}] {
	    dict set out $f [dict get $sylk $f]
	}

	dict set out yMax [expr {[dict get $sylk yMax] + $iy}]

	foreach idx [lsort -dictionary -decreasing [dict keys $sylk *,*]] {
	    lassign [split $idx ,] y x
	    if {$y >= $row} {
		dict set out [expr {$y + $iy}],$x [dict get $sylk $idx]
	    } else {
		dict set out $y,$x [dict get $sylk $idx]
	    }
	}

	return $out
    }

    proc insert_column {sylk col {ix 1}} {
	set out [dict create]

	foreach f [dict keys $sylk {[a-zA-Z]*}] {
	    dict set out $f [dict get $sylk $f]
	}

	dict set out xMax [expr {[dict get $sylk xMax] + $ix}]

	foreach idx [lsort -dictionary -decreasing [dict keys $sylk *,*]] {
	    lassign [split $idx ,] y x
	    if {$x >= $col} {
		dict set out $y,[expr {$x + $ix}] [dict get $sylk $idx]
	    } else {
		dict set out $y,$x [dict get $sylk $idx]
	    }
	}

	if {[dict exists $sylk widths]} {
	    dict set out widths [linsert [dict get $sylk widths] $col {*}[string repeat {{} } $ix]]
	}

	return $out
    }

    proc dup_row {sylk row} {
	set out [insert_row $sylk $row]

	# now copy back the next row
	set nr [expr {$row + 1}]
	foreach idx [lsort -dictionary -decreasing [dict keys $out $nr,*]] {
	    lassign [split $idx ,] y x
	    dict set out $row,$x [dict get $out $idx]
	}

	return $out
    }

    proc dup_column {sylk col} {
	set out [insert_column $sylk $col]

	# now copy back the next row
	set nc [expr {$col + 1}]
	foreach idx [lsort -dictionary -decreasing [dict keys $out *,$nc]] {
	    lassign [split $idx ,] y x
	    dict set out $y,$col [dict get $out $idx]
	}

	return $out
    }

    # size of spreadsheet
    proc size {sylk} {
	return [list [dict get $sylk yMax] [dict get $sylk xMax]]
    }

    # set widths of spreadsheet to max charsize of column contents
    proc widths {sylk {override 1}} {
	set xMax [dict get $sylk xMax]
	set widths [string repeat "-1 " [expr {$xMax + 1}]]
	if {[dict exists $sylk widths]} {
	    set owidths [dict get $sylk widths]
	} else {
	    set owidths [string repeat "{} " [expr {$xMax + 1}]]
	}

	foreach idx [lsort -dictionary [dict keys $sylk *,*]] {
	    if {[dict exists $sylk $idx value]} {
		set val [dict get $sylk $idx value]
		lassign [split $idx ,] y x

		if {[string length $val] > [lindex $widths $x]} {
		    lset widths $x [expr {[string length $val] + 1}]
		}
	    }
	}

	set w1 {}
	set n 0
	foreach w $widths {
	    if {$override
		||
		([lindex $owidths $n] eq {})
	    } {
		if {$w <= 0} {
		    lappend w1 {}
		} else {
		    lappend w1 $w
		}
	    } else {
		lappend w1 [lindex $owidths $n]
	    }
	    incr n
	}

	#puts stderr "WIDTHS: $w1"
	dict set sylk widths $w1
	return $sylk
    }

    # get the width of a column
    proc getwidth {sylk col} {
	if {![dict exists $sylk widths]} {
	    dict set sylk widths [string repeat "{} " [expr {[dict get $sylk xMax] + 1}]]
	}

	return [lindex [dict get $sylk widths] $col]
    }

    # set the width of a column
    proc setwidth {sylk col val} {
	set xMax [dict get $sylk xMax]
	if {$col > $xMax} {
	    return $sylk
	}

	if {![dict exists $sylk widths]} {
	    dict set sylk widths [string repeat "{} " [expr {$xMax + 1}]]
	}

	set widths [dict get $sylk widths]
	lset widths $col $val
	dict set sylk widths $widths

	return $sylk
    }

    # laminate a spreadsheet 'below' another
    proc row_laminate {s1 s2 {gap 0}} {
	set row [dict get $s1 yMax]
	return [dict merge $s1 [move $s2 [expr {$row + $gap}]]]
    }

    # laminate a spreadsheet to the right of another
    proc col_laminate {s1 s2 {gap 0}} {
	set col [dict get $s1 xMax]
	return [dict merge $s1 [move $s2 0 [expr {$col + $gap}]]]
    }

    # remove some crud from the sylk file
    proc optimise {sylk} {
	set xMax 0
	set yMax 0

	foreach idx [lsort -dictionary [dict keys $sylk *,*]] {
	    if {[dict exists $sylk $idx value]} {
		if {[dict exists $sylk $idx formula]} {
		    #puts stderr "FORMULA $idx - [dict get $sylk $idx formula]"
		}
		if {[dict exists $sylk $idx format]} {
		    #puts stderr "FORMAT $idx - [dict get $sylk $idx format]"
		}
	    } elseif {[dict exists $sylk $idx formula]} {
	    } elseif {[dict exists $sylk $idx format]} {
		# remove empty formatting cells
		dict unset sylk $idx
	    }
	}

	# calculate the true size of a spreadsheet
	foreach idx [dict keys $sylk *,*] {
	    lassign [split $idx ,] y x
	    if {$x > $xMax} {
		set xMax $x
	    }
	    if {$y > $yMax} {
		set yMax $y
	    }
	}
	
	dict set sylk xMax $xMax
	dict set sylk yMax $yMax
	
	return $sylk
    }

    #--------------------------------------------------------------------
    # parse X and Y values from a SYLK record
    #
    # Both values are optional. If a value is missing, the corresponding
    # value is not modified
    #--------------------------------------------------------------------
    proc parse {record xName yName} {
	upvar $xName x
	upvar $yName y
	
	if {[regexp {;Y([0-9]+)(;|$)} $record dummy value]} {
	    set y $value
	}
	if {[regexp {;X([0-9]+)(;|$)} $record dummy value]} {
	    set x $value
	}
    }

    # de-armour a sylk value
    proc da {value} {
	return [string map {\x81 ;} $value]
    }

    # clean up cell style
    proc style {style} {
	set result ""

	#puts stderr "STYLE $style"

	set style [string range $style 1 end]
	while {[string length $style]} {
	    set code [string index $style 0]
	    set style [string range $style 1 end]
	    switch -- $code {
		M {
		    # until I know what an SM is, out it goes
		    while {[string length $style]
			   &&
			   [string is integer -strict [string index $style 0]]
		       } {
			set style [string range $style 1 end]
		    }
		}

		default {
		    append result $code
		}
	    }
	}

	return $result
    }

    # whole spreadsheet format decoder
    proc whformat {sylk fields} {
	foreach el $fields {
	    switch -glob $el {
		E* {
		    dict set sylk -show 1
		}
		K* {
		    dict set sylk -commas 1
		}
		H* {
		    dict set sylk -hide 1
		}
		N* {
		    set el [string range $el 1 end]
		    dict set sylk -font $el
		}
		D* {
		    set el [string range $el 1 end]
		    dict set sylk -default $el
		}
		P* {
		    set el [string range $el 1 end]
		    dict set sylk -defpic $el
		}

		default {
		    error "$el in whole format"
		}
	    }
	}
	return $sylk
    }

    # row/column format decoder
    proc rcformat {sylk fields} {
	set result ""
	foreach el $fields {
	    set code [string index $el 0]
	    switch $code {
		C {
		    set dir cols
		    set num [string range $el 1 end]
		}
		R {
		    set dir rows
		    set num [string range $el 1 end]
		}
		F -
		P {
		    append result ";$el"
		}

		S {
		    # clean up style
		    #puts stderr "cell $el"
		    set body [style $el]
		    if {$body ne ""} {
			append result ";S$body"
		    }
		}
		default {
		    error "$el in rc format"
		}
	    }
	}
	if {$result ne ""} {
	    dict set sylk $dir $num $result
	}

	return $sylk
    }

    # cell format decoder
    proc cellformat {sylk index fields} {
	# cell format
	set value {}
	foreach el $fields {
	    set code [string index $el 0]
	    switch $code {
		X - Y {
		    set el {}
		}

		F - P - G {}

		S {
		    # clean up style
		    set body [style $el]
		    if {$body ne ""} {
			#puts stderr "cell S $body"
			set el "S$body"
		    } else {
			set el {}
		    }
		}

		default {
		    error "$el in cell format"
		}
	    }

	    if {$el != {}} {
		append value ";$el"
	    }
	}

	dict set sylk $index format $value

	return $sylk
    }

    # decode format descriptor
    proc fdecode {line} {
	upvar 1 pictures pictures
	upvar 1 piccnt piccnt
	upvar 1 widths widths

	set flist [lrange [split $line \;] 1 end]
	set result {}
	foreach el $flist {
	    set code [string index $el 0]
	    switch $code {
		X - Y {
		    set kind cell
		}
		
		C - R {
		    if {[info exists kind]} {
			error "$el in $kind format"
		    }
		    set kind rc
		}

		F - D -
		S - G {}

		P {
		    set picnum [string trim $el P]
		    if {![info exists pictures($picnum)]} {
			set pictures($picnum) [incr piccnt]
		    }
		    set el "P$pictures($picnum)"
		}

		W {
		    # column width descriptor
		    lappend widths [string range $el 1 end]
		    set el {}

		    if {[info exists kind]} {
			error "$el in $kind format"
		    }
		    set kind whole
		}

		H - E - K - N {
		    # global stuff 'show formulas', 'show commas' 'font'
		    if {[info exists kind]} {
			error "$el in $kind format"
		    }
		    set kind whole
		}

		default {
		    #puts stderr "Unknown Format: $el"
		    set el {}
		}
	    }

	    if {$el ne {}} {
		lappend result $el
	    }
	}

	if {![info exists kind]} {
	    set kind cell
	}

	return [list $kind $result]
    }

    proc import {input} {
	set sylk [dict create]
	set input [string map {;; \x81} $input]	;# armour quoted semicolons

	set piccnt -1	;# count of pictures seen
	set widths {}	;# widths array

	# store table boundaries
	set xMax 0
	set yMax 0
	
	# pass 1: scan the whole spreadsheet marking existing cells
	set x 0; set y 0
	foreach line $input {
	    parse $line x y
	    if {[string index $line 0] eq "C"} {
		# C record: Cell definition.
		# e.g. C;Y1;X1;K"Name"
		dict set sylk $y,$x [dict create]
		if {$y > $yMax} {
		    set yMax $y
		}
		if {$x > $xMax} {
		    set xMax $x
		}
	    }
	}

	# pass 2: decode the cells
	set xAct 0; set yAct 0	;# hold current postition
	foreach line $input {
	    switch -glob $line {
		ID* {
		    # ID SYLK file identification record
		    # e.g. ID;PWXL;N;E
		    regexp {^ID;(.*)$} $line -> value
		    dict set sylk id [da $value]
		}

		B* {
		    #B Cell boundary - ignore theirs, we have ours
		    # e.g. B;Y107;X105;D0 0 106 104
		    #regexp {^B;Y([0-9]+);X([0-9]+)} $line dummy yMax xMax
		    #puts stderr "MAX: $yMax $xMax"
		}

		F* {
		    # F Cell formatting parameter
		    parse $line xAct yAct

		    lassign [fdecode $line] kind fields	;# decode format
		    switch $kind {
			whole {
			    # format applies to whole sheet
			    set sylk [whformat $sylk $fields]
			}

			rc {
			    # format applies to a row or column
			    set sylk [rcformat $sylk $fields]
			}

			cell {
			    # format applies to cell
			    if {[dict exists $sylk $yAct,$xAct]} {
				set sylk [cellformat $sylk $yAct,$xAct $fields]
			    } else {
				# ignore format of empty cells
			    }
			}
		    }
		}

		C* {
		    # C record: Cell definition.
		    # e.g. C;Y1;X1;K"Name"
		    parse $line xAct yAct

		    if {[regexp {;K([^;]*)(;E|$)} $line -> value]} {
			set value [string trim $value \"]
			dict set sylk $yAct,$xAct value [da $value]
		    }

		    # with formula?
		    # E.g. C;K-1188;E(R[+1]C-0.5)*(R3C2-R2C2)/R4C2+R2C2
		    if {[regexp {;E(.*)(;|$)} $line dummy value]} {
			dict set sylk $yAct,$xAct formula [da $value]
		    }
		}

		NE* {
		    # NE Link to an inactive spreadsheet file
		    # just strip 'em out
		}

		P* {
		    # Pictures - keep a list of 'em
		    dict lappend sylk picture $line
		}

		E {
		    # E End of file
		    # SYLK file ends here
		    break
		}

		default {
		    # add to header (uninterpreted)

		    # NN Name given to a rectangluar area of cells
		    # NU Substitute filename

		    puts stderr "UNKNOWN: $line"
		    dict lappend sylk header $line
		}
	    }
	}

	# remember dimensions of sheet
	dict set sylk xMax $xMax
	dict set sylk yMax $yMax

	# reduce the pictures to those actually referenced
	foreach {n v} [array get pictures] {
	    set outpic($v) $n
	}
	set pp {}
	foreach n [lsort -integer [array names outpic]] {
	    lappend pp [lindex [dict get $sylk picture] $outpic($n)]
	}
	dict set sylk picture $pp

	# store the widths as a list widths or {}, one per column
	if {[llength $widths]} {
	    # aggregate widths
	    set widthpic [string repeat "{} " [expr {$xMax + 1}]]
	    foreach {w} $widths {
		lassign $w start end chars
		for {set i $start} {($i <= $end) && ($i <= $xMax)} {incr i} {
		    lset widthpic $i $chars
		}
	    }
	    dict set sylk widths $widthpic
	}

	return $sylk
    }

    #--------------------------------------------------------------------
    # read a SYLK file into the internal structure
    #--------------------------------------------------------------------
    proc read {filename} {
	set fp [open $filename r]
	set sylk [import [split [::read $fp] \n]]
	close $fp
	return $sylk
    }

    proc export {sylk {rc 0}} {
	set r ""

	# write
	if {[dict exists $sylk id]} {
	    append r "[dict get $sylk id]" \n
	} else {
	    append r "ID;PWXL;N;E" \n
	}
	
	# boundary?
	if {[dict exists $sylk yMax] && [dict exists $sylk yMax]} {
	    append r "B;Y[dict get $sylk yMax];X[dict get $sylk xMax]" \n
	}
	
	# first, write picture set
	if {[dict exists $sylk picture]} {
	    foreach line [dict get $sylk picture] {
		append r $line \n
	    }
	}

	# write header
	if {[dict exists $sylk header]} {
	    foreach line [dict get $sylk header] {
		append r $line \n
	    }
	}

	# write whole-sheet defaults
	set def ""
	if {[dict exists $sylk -default]} {
	    set def ";D[dict get $sylk -default]"
	}
	if {[dict exists $sylk -defpic]} {
	    set def ";P[dict get $sylk -default]"
	}
	if {$def ne ""} {
	    append r "F$def" \n
	}

	# write widths
	if {[dict exists $sylk widths]} {
	    set col 0
	    foreach w [lrange [dict get $sylk widths] 1 end] {
		incr col
		if {[llength $w]} {
		    append r "F;W$col $col $w" \n
		}
	    }
	}

	# write any column formats
	if {[dict exists $sylk cols]} {
	    dict for {col val} [dict get $sylk cols] {
		append r "F$val;C$col" \n
	    }
	}

	# write any row formats
	if {[dict exists $sylk rows]} {
	    dict for {row val} [dict get $sylk rows] {
		append r "F$val;R$row" \n
	    }
	}

	# write data
	foreach idx [lsort -dictionary [dict keys $sylk *,*]] {
	    lassign [split $idx ,] y x
	    
	    if {[dict exists $sylk $y,$x format]} {
		set format "F[dict get $sylk $y,$x format];Y$y;X$x"
		append r $format \n
	    }

	    set line "C;Y$y;X$x"

	    if {[dict exists $sylk $y,$x value]} {
		set value [dict get $sylk $y,$x value]
		if {![string is double -strict $value]} {
		    set value "\"[string map {; ;;} $value]\""
		}

		append line ";K$value"
	    }

	    if {[dict exists $sylk $y,$x formula]} {
		append line ";E[string map {; ;;} [dict get $sylk $y,$x formula]]"
		#puts stderr "LINE: $line"
	    }

	    append r $line \n
	}
	
	# end-of-file marker
	append r "E" \n

	return $r
    }

    #--------------------------------------------------------------------
    # write a SYLK file from the internal structure
    #--------------------------------------------------------------------
    proc write {filename sylk} {
	set fp [open $filename w]
	puts $fp [export $sylk]
	close $fp
    }

    # convert a csv file to a sylk
    proc csv2sylk {csv {sep ","} {alternate 0}} {
	package require csv

	dict set sylk id "ID;PTCL;E"
	set xMax 0
	set y 0

	set accum ""
	foreach ll [split $csv \n] {
	    append accum $ll \n
	    if {![::csv::iscomplete $accum]} {
		continue
	    } else {
		set line [string trim $accum \n]; set accum ""
	    }
	    set line [string map {\n "\x1b0d"} $line]

	    incr y

	    if {$alternate} {
		set csvl [csv::split -alternate $line ${sep}]
	    } else {
		set csvl [csv::split $line ${sep}]
	    }

	    # keep track of max width
	    if {[llength $csvl] > $xMax} {
		set xMax [llength $csvl]
	    }

	    # traverse columns in row
	    set x 0
	    foreach el $csvl {
		incr x
		if {$el ne ""} {
		    # only write actual cells
		    dict set sylk $y,$x value $el
		}
	    }
	}

	# remember size
	dict set sylk xMax $xMax
	dict set sylk yMax $y

	return $sylk
    }

    proc csv {sylk {sep ","}} {

	set idxs [lsort -dictionary [dict keys $sylk *,*]]
	set curY [lindex [split [lindex $idxs 0] ,] 0] ;# initial row
	set curX 0		;# initial column
	set result ""	;# accumulator

	# process each cell
	foreach idx $idxs {
	    lassign [split $idx ,] y x	;# decode row,column

	    if {$curY != $y} {
		# new row - emit it
		append result [join $line $sep] \n
		incr curY
		while {$curY < $y} {
		    incr curY
		    append result \n
		}
		#set curY $y	;# remember current row
		set curX 0		;# we always start from 0
		set line {}
	    }

	    while {[incr curX] != $x} {
		lappend line {}	;# we've changed column
	    }
	    set curX $x	;# remember current column

	    # emit value
	    set value [dict get $sylk $idx value]
	    if {[regexp "\[\"$sep \t\]" $value]} {
		# we must armour value against separator
		set value [string map {\" ""} $value]
		set value \"$value\"
	    }

	    lappend line $value	;# accumulate part of a row
	}

	# emit last line
	if {[llength $line]} {
	    append result [join $line $sep] \n
	}

	return $result
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

if {$argv0 eq [info script]} {
    set sylk [Sylk read [lindex $argv 0]]
    #puts $sylk
    set sylk [Sylk optimise $sylk]
    set sylk [Sylk widths $sylk]
    #set sylk [Sylk move $sylk 10 10]
    set sylk [Sylk insert_col $sylk 3 2]
    dict unset sylk header
    puts [Sylk export $sylk]
    puts stderr [Sylk csv $sylk]
}
