package require struct::tree
package require csv
package require Debug
Debug define STX 10

package provide stx 1.1

namespace eval stx {
    proc undent {text} {
	package require textutil
	return [::textutil::undent $text]
    }

    # count the number of characters in the set 'leadin'
    proc count {para leadin} {
	set content [string trimleft $para $leadin]
	return [expr {[string length $para] - [string length $content]}]
    }

    # tree debugging - generate the node path to root
    proc path {tree {node ""}} {
	if {$node eq ""} {
	    set node [$tree get root cursor]
	}
	if {$node eq "root"} {
	    return root
	} else {
	    return "[path [$tree parent $node]] $node/[$tree get $node type]"
	}
    }

    # tree debugging - dump node
    proc node {tree {node root}} {
	set result ""
	if {$node eq ""} {
	    set node root
	}

	$tree walk $node n {
	    append result "[string repeat > [$tree depth $n]] [$tree get $n type]: "
	    foreach k [$tree keys $n] {
		if {$k ne "type"} {
		    append result " $k \"[$tree get $n $k]\""
		}
	    }
	    append result \n
	}
	return $result
    }

    # unwind the path stack to given new level of list nesting
    proc unlist {tree {new {}}} {
	set path [$tree get root path]
	if {$path ne $new} {
	    set cursor [$tree get root cursor]
	    
	    # calculate the size of matching prefix
	    set match 0
	    foreach curr $path n $new {
		if {$curr ne $n} break
		incr match
	    }

	    # get the changes: undo set, then add set
	    set undo [lrange $path $match end]
	    set add [lrange $new $match end]
	    Debug.STX {unlist Path: $path New: $new / $match / Undo: $undo Add: $add} 10

	    # unwind the cursor, moving up the tree
	    while {[llength $undo]} {
		set cursor [$tree parent $cursor]
		set undo [lrange $undo 0 end-1]
	    }

	    # construct list elements downward
	    variable idPrefix
	    variable id
	    foreach l $add {
		set cursor [$tree insert $cursor end $idPrefix[incr id]]
		$tree set $cursor type $l
	    }
	    $tree set root cursor $cursor
	    $tree set root path $new
	}
    }

    # balance paired character-level markup, e.g. '' pairs
    proc balance {text sep fn} {
	set result ""
	foreach {pre seg} [split [string map [list $sep \x81] $text] \x81] {
	    if {$seg ne ""} {
		append result "${pre}\[$fn ${seg}\]"
	    } else {
		append result $pre
	    }
	}
	return $result
    }

    variable refs	;# set of all refs in text

    # preprocess character-level markup
    proc char {tree text} {
	set text [string map {
	    \[\[ \x84
	    \]\] \x85
	    \; \x87
	} $text]
	
	# handle naked http references
	regsub -all "(\[^\[\]|^)http:(\[^ \]+)" $text {\1[http:\2]} text
	Debug.STX {Char: '$text'} 30

	#puts stderr "ENCODING REFS: $text"
	set refs [$tree get root refs]
	while {[regexp -- "\\\[\[^\]\]+\]" $text ref]} {
	    set index [dict size $refs]
	    Debug.STX {ENCODE REF: $index $ref} 10
	    dict set refs $index [string trim $ref {[]}]
	    regsub -- "\\\[\[^\]\]+\]" $text "\x91$index\x92" text
	}
	$tree set root refs $refs

	set text [balance $text ''' italic]
	set text [balance $text '' strong]
	set text [balance $text __ underline]
	set text [balance $text %% smallcaps]
	set text [balance $text -- strike]
	set text [balance $text ^^^ subscript]
	set text [balance $text ^^ superscript]
	set text [balance $text !! big]

	return $text	;# the list acts as a quote
    }

    variable idPrefix STX_
    variable id 0

    # create a new node of given type with value at the given path
    proc newnode {tree type lc {p {}}} {
	unlist $tree $p

	variable idPrefix
	variable id
	set cursor [$tree get root cursor]
	set node [$tree insert $cursor end $idPrefix[incr id]]

	$tree set $node type $type
	$tree set $node lc $lc
	return $node
    }

    proc nodevalue {tree node val} {
	$tree set $node val [list $val]
    }

    # character data node
    proc nodecdata {tree node val} {
	variable idPrefix
	variable id
	set cdata [$tree insert $node end $idPrefix[incr id]]

	$tree set $cdata type cdata
	$tree set $cdata val [list [list $val]]
    }

    # identity preprocess for normal
    proc +normal {tree lc para} {
	Debug.STX {normal $lc '$para'}
	nodecdata $tree [newnode $tree normal $lc] [char $tree $para]
    }

    proc +special {tree lc para} {
	Debug.STX {special $lc '$para'}
	nodecdata $tree [newnode $tree special $lc] [string range $para 1 end]
    }

    # identity preprocess for hr
    proc +hr {tree lc args} {
	Debug.STX {hr $lc '$args'}
	newnode $tree hr $lc
    }

    # identity preprocess for pre
    proc +pre {tree lc para} {
	Debug.STX {pre $lc '$para'}
	set para [string map {"\n " "\n" \[ "&#x5B;" \] "&#x5D;" \{ "&#x7B;" \} "&#x7D;" $ "&#x24;"} $para]
	nodecdata $tree [newnode $tree pre $lc] [string range $para 1 end]
    }

    # preprocess for indent elements
    proc +indent {tree lc para} {
	Debug.STX {indent $lc: '$para'}
	set path [$tree get root path]
	nodecdata $tree [newnode $tree indent $lc $path] [char $tree $para]
    }

    # preprocess for header elements
    proc +header {tree lc para} {
	Debug.STX {header $lc: '$para'}
	set count [count $para =]	;# depth of header nesting
	set para [string trimleft $para =] ;# strip leading ='s

	# we have the depth, and the start of the header
	# now we need to find the end of header.
	set p [split $para =]
	set para [lindex $p 0]
	set rest [string trimleft [join [lrange $p 1 end] =] "= "] ;# this may be a para
	
	set para [split $para "\#"]
	set tag [string trim [lindex $para end]]
	set para [string trim [lindex $para 0]]

	lassign $lc ls le
	set hnode [newnode $tree header [list $ls $ls]]
	$tree set $hnode level $count
	nodecdata $tree $hnode [char $tree $para]

	# now process any pendant para
	if {$rest ne ""} {
	    incr ls
	    dispatch $tree [list $ls $le] $rest
	}
    }

    # preprocess for list elements
    proc +li {tree lc para} {
	Debug.STX {li $lc: '$para'}
	set count [count $para "\#*"]	;# how many list levels deep?
	Debug.STX {li $count '$para'}
	set li [string range $para 0 [expr {$count - 1}]]	;# list prefix
	set li [split [string trim [string map {\# "ol " * "ul "} $li]]]
	set para [string trim [string range $para $count end]]	;# content
	nodecdata $tree [newnode $tree li $lc $li] [char $tree $para]
    }

    # table elements
    proc +table {tree lc para {cpath ""}} {
	Debug.STX {table $lc: '$para' ($cpath)}
	set para [string range $para 1 end]
	switch [string index $para 0] {
	    + {
		set para [string trimleft $para +]
		set type hrow
	    }
	    default {
		set type row
	    }
	}

	set els [::csv::split -alternate $para "|"]
	Debug.STX {TABLE: '$para' - $els}
	#puts stderr "TABLE: '$para' - $els"

	set row [newnode $tree $type $lc table]
	foreach el $els {
	    nodecdata $tree $row [char $tree $el]
	}
    }

    # preprocess for dlist elements
    proc +dlist {tree lc para {cpath ""}} {
	Debug.STX {dlist $lc: '$para' ($cpath)}
	set pp [split [char $tree [string trimleft $para ";"]] :]
	set term [lindex $pp 0]
	set def [string trim [join [lrange $pp 1 end] ": "]]
	set dlnode [newnode $tree dl $lc dlist]
	Debug.STX {DLIST: '$para' - '$para' - $term}
	nodecdata $tree $dlnode $term
	nodecdata $tree $dlnode $def
    }

    # mapping from formatting prefix character to implementation
    variable funct
    array set funct {
	" " +pre
	* +li
	# +li
	; +dlist
	= +header
	> +indent
	- +hr
	. +special
	| +table
	\x82 +li
	\x83 +li
    }
    
    proc dispatch {tree lc para} {
	set first [string index $para 0]	;# get semantic para prefix
	variable funct	;# mapping from prefix to function
	if {[info exists funct($first)]} {
	    set f $funct($first);# function to handle this prefix
	} else {
	    set f +normal	;# this is a normal para
	}
    
	#Debug.STX {para $f '$para'}
	$f $tree $lc $para	;# invoke the parser for this para type
    }

    # para - process each paragraph
    proc para {tree para} {
	# split on lc tags
	set p [split $para \x8e]
	set lc [list [lindex $p 1] [lindex $p end-1]]
	Debug.STX {para: $lc '$p'}
	# reconstruct the para without the linec tags
	set para ""
	foreach {line -} $p {
	    append para $line
	}

	if {$para eq {}} return	;# empty paras have no meaning
	dispatch $tree $lc $para
    }

    # scope processing
    proc scope {tree text} {
	set count 0
	set text [split [string map [list \{\{\{ \x8c \}\}\} \x8d] $text] \x8c]
	set result [lindex $text 0]

	set scope [$tree get root scope]
	foreach seg [lrange $text 1 end] {
	    lassign [split $seg \x8d] e rest
	    regsub -all {\x8e[^\x8e]+\x8e} $e {} e	;# remove linecounts
	    dict set scope $count $e
	    Debug.STX {scope $count: ($e)}
	    append result \x8c $count \x8d $rest
	    incr count
	}
	$tree set root scope $scope

	return $result
    }

    # translate structured text into
    # tcl function calls over paragraphs
    proc translate {original args} {
	variable id -1
	variable offset -1
	# unpack optional named args
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	set args [dict merge {tree ""} $args]
	variable {*}$args

	if {$tree eq ""} {
	    set tree [::struct::tree]
	    $tree set root type root
	    $tree set root refs {}
	    $tree set root scope {}
	}

	# our original path is always empty
	$tree set root cursor root
	$tree set root path {}
	$tree set root tagnum 0

	# append an original line number to each line
	set original [split $original \n]
	set text ""
	foreach line $original {
	    incr offset
	    #set line [string trimright $line]
	    append text $line \x8e $offset \x8e \n
	}
	set text [scope $tree $text]	;# remove scopes

	regsub -all {\n\x8e[^\x8e]+\x8e\n+} $text \x81 text	;# run blank lines together

	# tag special line start markers
	set text [string map {
	    \n# \x81\#
	    \n* \x81*
	    \n; \x81;
	    \n- \x81-
	    \n= \x81=
	    \n> \x81>
	    \n| \x81|
	} $text]

	# clean up newlines except those with spaces
	# encode special characters {}$<>
	set text [string map {
	    "\n " "\n "
	    \n " "
	    \{ "\x89"
	    \} "\x8A"
	    $ "\x8B"
	    < "&lt\x87"
	    > "&gt\x87"
	} $text]
	
	# split the text into paragraphs along line-start tags
	# process each paragraph independantly
	foreach para [split $text \x81] {
	    para $tree $para	;# process each paragraph
	}

	# generate a tcl script from the parse tree
	set result ""
	variable id; $tree set root id $id
	variable lcs {}	;# keep count of lines
	set line2node {}
	$tree walk root -order both {action node} {
	    if {$node eq "root"} continue
	    if {$action eq "enter"} {
		if {[$tree depth $node] > 1} {
		    append result " "	;# space separates commands
		}

		# on the way in we open the tcl command
		# each node has a semantic type which is its function
		# and a start/end line number from the original text
		set type [$tree get $node type]
		if {$type eq "cdata"} {
		    set lc [list $node]
		} elseif {[$tree keyexists $node lc]} {
		    # add linecount setter
		    lassign [$tree get $node lc] s e
		    dict set line2node [list $s $e] $node
		    #set lines [$tree set $node raw [lrange $original $s $e]]
		    set lines {}
		    set lc [list $node {*}[$tree get $node lc] $lines]
		    Debug.STX {"lc [$tree get $node type] - [$tree get $node lc]"}
		} else {
		    # construct a line range from children
		    set ls 9999999
		    set le -1
		    foreach kid [$tree children $node] {
			if {[$tree keyexists $kid lc]} {
			    lassign [$tree get $kid lc] ks ke
			    if {$ks < $ls} {
				set ls $ks
			    }
			    if {$ke > $le} {
				set le $ke
			    }
			}
		    }
		    #set lines [$tree set $node raw [lrange $original $ls $le]]
		    set lines {}
		    set lc [list $node $ls $le $lines]
		    Debug.STX {"lc synthetic [$tree get $node type] - $ls $le '$lines'"}
		    set lines [$tree set $node raw $lines]
		}

		append result "\[+$type [list $lc] "
		if {$type eq "header"} {
		    append result " " [$tree get $node level]
		    #append result " " [$tree get $node tag]
		}
		if {[$tree keyexists $node val]} {
		    append result " [join [$tree get $node val]]"
		}
	    } else {
		# on the way out we close the tcl command
		append result "]"
		if {[$tree depth $node] == 1} {
		    append result "\n"	;# top level commands are newline termd
		} else {
		    append result " "
		}
	     }
	}

	# after generating the tcl command stream,
	# substitute refs back in.
	set result [string map [list \x91 "\[+ref " \x92 "\]"] $result]
	
	# substitute scopes back in
	set result [string map [list \x8c "\[+scope " \x8d "\]"] $result]

	Debug.STX {RESULT: $result}
	return [list $result $tree $line2node]
    }

    proc init {args} {
	if {$args ne {}} {
	    variable {*}$args
	}
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

stx init

# special non-chars used as placeholders
# 0x81 new paragraph
# 0x81 open TOC
# 0x82 li
# 0x82 close TOC
# 0x83 li 
# 0x84 open sqbr
# 0x85 close sqbr
# 0x87 semicolon
# 0x88 "&\#"
# 0x89 {
# 0x8A }
# 0x8B $
# 0x8c open scope
# 0x8d close scope
# 0x8e linecount
# 0x91 open ref
# 0x92 close ref
