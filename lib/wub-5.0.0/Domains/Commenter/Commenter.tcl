# Commenter - a utility to parse tcl source files and associate out-line
# comments with procs.

if {[info exists argv0] && ($argv0 eq [info script])} {
    lappend auto_path ../Utilities ../extensions
}

package require fileutil
package require Html
package require functional

package provide Commenter 1.0

set ::API(Domains/Commenter) {
    {a utility to parse tcl source files and associate out-line comments with procs.}
    root {filesystem root containing source files to comment}
}

namespace eval ::Commenter {

    # gather leading comment block
    proc leadin {text} {
	set leadin {}
	set lnum 0
	foreach line $text {
	    set line [string trim $line " \t"]
	    incr lnum
	    if {[string match \#* $line]} {
		lappend leadin $line
	    } else {
		return [list $leadin [lrange $text $lnum end]]
	    }
	}
	return [list $leadin {}]
    }

    # parse a tcl source into a dict containing:
    #
    # contexts - the contexts provided by this source (namespace, global)
    # entities - the procs, vars, options and methods provided by this source

    proc parse {text {src ""}} {
	set text [split $text \n]

	# leadin is a comment block terminated by a non-comment
	lassign [leadin $text] leadin text
	set lnum [llength $leadin]
	#puts stderr "$lnum line leadin"

	set comment {}	;# free-standing comment block
	set current $src	;# current context
	array set context [list $src [list name $src type global comment $leadin]]	;# context of declaration

	set requires {} ;# packages required
	set provides ""	;# package provided
	set accum ""	;# we're not in proc scope

	foreach line $text {
	    set line [string trim $line " \t"]
	    incr lnum

	    if {$accum ne ""} {
		# we're in proc context
		append accum \n $line
		#puts stderr $accum
		if {![info complete $accum]} {
		    continue
		} else {
		    set accum ""	;# we're out of proc context
		}
	    }

	    switch -glob -- $line {
		\#* {
		    # accumulate comments en bloc
		    lappend comment $line
		}

		package* {
		    # provide
		    # require
		    regsub {[ \t]+} $line " " line
		    set line [split $line]
		    switch -- [lindex $line 1] {
			provide {
			    set provides [lindex $line 2]
			    #puts stderr "provides $provides"
			}
			require {
			    if {[string match -* [lindex $line 2]]} {
				lappend requires [lindex $line 3]
			    } else {
				lappend requires [lindex $line 2]
			    }
			    #puts stderr "requires $requires"
			}
		    }
		    set comment {}
		}

		namespace* {
		    # eval
		    regsub {[ \t]+} $line " " line
		    set line [split $line]
		    
		    if {[lindex $line 1] eq "eval"} {
			set name [string trim [lindex $line 2] :]
			set context($name) [list name $name comment $comment type namespace context $src]
			set current $name
			set comment {}
			lappend context($src) entities $name
		    }
		    #puts stderr "namespace $name"
		}

		variable* -
		option* -
		method* -
		proc* {
		    regsub {[ \t]+} $line " " line
		    set accum $line	;# enter proc context

		    set line [split $line]
		    set name [string trim [lindex $line 1] \;]
		    if {[lindex $line 0] in {variable option}} {
			set trailing [lindex [split [join $line] \#] 1]
			lappend comment $trailing
		    }
		    set entities(${current}::$name) [list name $name comment $comment line $lnum context $current type [lindex $line 0] src $src]
		    dict lappend context($current) entities $name

		    set comment {}
		    #puts stderr "[lindex $line 0] $name"
		}
	    }
	}
	dict lappend context($src) provides {*}provides
	dict lappend context($src) requires {*}$requires
	return [list contexts [array get context] entities [array get entities]]
    }

    # same as parse, but operates on the contents of a file
    proc parseF {path} {
	return [parse [::fileutil::cat $path] [file tail $path]]
    }

    # same as parse, but operates on the contents of a file system
    proc parseFS {path} {
	set contexts {}
	set entities {}

	foreach file [::fileutil::find $path [lambda {x} {
	    if {".svn" in [file split [pwd]]} {return 0}
	    return [string match {*.tcl} $x]
	}]] {
	    set x [parseF [file join $path $file]]
	    set contexts [dict merge $contexts [dict get $x contexts]]
	    set entities [dict merge $entities [dict get $x entities]]
	}
	return [list contexts $contexts entities $entities]
    }

    # enblock - turns a block of text comments into a run of blocks
    proc enblock {lines} {
	set blocks {}
	set block {}
	foreach line $lines {
	    set line [string trimleft $line \#]
	    set line [string trim $line " \t"]
	    if {$line eq ""} {
		if {$block ne ""} {
		    lappend blocks [join $block]
		}
		set block {}
	    } else {
		lappend block $line
	    }
	}
	if {$block ne ""} {
	    lappend blocks [join $block]
	}
	return $blocks
    }

    # remove a prepended "name -" formulation from a block
    proc trimname {name args} {
	set blocks {}
	foreach block $args {
	    foreach char {- :} {
		if {[string match "$name $char*" $block]} {
		    # remove leading name-dash formulation
		    set block [string trim [join [lassign [split $block $char] null] $char] "$char \t"]
		}
	    }
	    lappend blocks $block
	}
	return $blocks
    }

    # return a formatted dict for given contexts
    proc munge {comments {contexts *}} {
	set result {}
	dict for {k v} [dict filter [dict get? $comments contexts] key $contexts] {
	    if {[dict get $v type] eq "global"} continue
	    set src [dict get $comments contexts [dict get $v context]]
	    set comment [dict get $v comment]
	    if {$comment eq {}} {
		if {[llength [dict get $src entities]] == 1} {
		    set comment [trimname [dict get $v name] [trimname [dict get $src name] {*}[Commenter enblock [dict get $src comment]]]]
		}
	    } else {
		set comment [trimname [dict get $v name] {*}[Commenter enblock $comment]]
	    }
	    set cname "[dict get $v type] $k"
	    dict set result $cname "" $comment
	    dict set result $cname " requires" [dict get $src requires]
	    dict set result $cname " requires" [dict get $src requires]

	    dict for {entity ev} [dict filter [dict get $comments entities] key ${k}::*] {
		set block [Commenter enblock [dict get $ev comment]]
		set name [dict get $ev name]
		set block [trimname $name {*}$block]; # remove leading name-dash formulation
		dict set result $cname "[dict get $ev type] $name" "$block"
	    }
	}
	return $result
    }

    # munge comment dict into an HTML fragment
    proc 2html {comments args} {
	foreach {k v} {
	    contexts *
	    context_class c_context
	    entitity_class c_entity
	    container form
	    context_container fieldset
	    context_name legend
	    context_descriptor p
	    entity_container fieldset
	    entity_name legend
	    entity_descriptor p
	} {
	    if {![dict exists $args $k]} {
		dict set args $k $v
	    }
	}

	dict with args {
	    set munged [munge $comments $contexts]
	    set result ""
	    foreach context [lsort [dict keys $munged]] {
		set val [dict get $munged $context]
		append result "<$container class='$context_class'>" \n
		append result <$context_container> \n
		append result <$context_name> [armour $context] </$context_name> \n
		append result <$context_descriptor> [join [armour [dict get $val ""]] "</$context_descriptor><$context_descriptor>"] </$context_descriptor> \n

		if {[dict get $val " requires"] ne {}} {
		    append result <$context_descriptor> "packages required: " [dict get $val " requires"] </$context_descriptor>
		}

		dict unset val " requires"
		dict unset val ""

		foreach k [lsort [dict keys $val]] {
		    set c [dict get $val $k]
		    append result <$entity_container> \n
		    append result <$entity_name> [armour $k] </$entity_name> \n
		    append result <$entity_descriptor> [join [armour $c] </$entity_descriptor><$entity_descriptor>] </$entity_descriptor> \n
		    append result </$entity_container> \n
		}

		append result </fieldset> \n
		append result </form> \n
	    }
	}
	return $result
    }

    variable root [file dirname [file dirname [file normalize [info script]]]]
    variable display ""	;#
    variable munged ""

    proc / {r} {
	variable display
	variable munged
	if {$display eq ""} {
	    variable root
	    set display [Commenter parseFS $root]
	    set munged [munge $display]
	}

	set result "<dl>"
	foreach context [lsort [dict keys $munged]] {
	    set val [dict get $munged $context]
	    set ns [lindex [split $context] 1]
	    append result <dt> [<a> href "./ns?ns=$ns" [armour $context]] </dt>
	    append result <dd> [armour [lindex [dict get $val ""] 0]] </dd>
	}
	append result "</dl>"
	return [Http Ok $r $result]
    }

    proc /ns {r ns} {
	variable display
	return [Http Ok $r [Commenter 2html $display contexts "*$ns"]]
    }

    proc new {args} {
	return [Direct new {*}[Site var? Commenter] {*}$args namespace ::Commenter]
    }
    proc create {name args} {
	return [Direct create $name {*}[Site var? Commenter] {*}$args namespace ::Commenter]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    # this thing tests itself
    set root [info script]
    set comments [Commenter parseFS [file dirname [file dirname [file normalize $root]]]]
    if {0} {
	puts stderr "Contexts: [dict keys [dict get $comments contexts]]"
	puts stderr $comments

	set munge [Commenter munge $comments]
	dict for {k v} $munge {
	    puts $k
	    set result {}
	    foreach key [lsort [dict keys $v]] {
		lappend result $key [dict get $v $key]
	    }
	    puts $result
	}
    }

    puts [Commenter 2html $comments]
}
