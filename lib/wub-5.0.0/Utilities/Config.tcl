# Config.tcl - support tcl-like config files

if {[info exists argv0] && ($argv0 eq [info script])} {
    lappend auto_path ~/Desktop/Work/Wub/ [file dirname [info script]]
}

if {[catch {package require Debug}]} {
    #proc Debug.config {args} {}
    proc Debug.config {args} {puts stderr HTTP@[uplevel subst $args]}
} else {
    Debug define config 10
}

package require parsetcl
package provide Config 1.0

set ::API(Utilities/Config) {
    {
	Configuration parser
    }
}

oo::class create Config {
    # parse a single section into raw alist, comments and metadata
    method parse_section {section script} {
	variable raw; variable comments; variable metadata
	variable clean 0

	# perform script transformation
	set varname ""	;# initial name used to collect per-section comments
	set body [parsetcl simple_parse_script $script]
	parsetcl walk_tree body index Rs {} C.* {
	    set cmd [lindex $body {*}$index]
	    if {[llength $index] == 1} {
		set meta [lassign $cmd . . . left]
		set right [lindex $meta end]
		set meta [lrange $meta 0 end-1]

		set varname [parsetcl unparse $left]	;# literal name
		if {![string match L* [lindex $left 0]]} {
		    error "variable name '$varname' must be a literal ($left)"
		}

		# accumulate per-variable metadata
		foreach md $meta {
		    dict set metadata $section $varname [parsetcl unparse $md]
		}

		# set raw value
		set rl [parsetcl unparse $right]
		dict set raw $section $varname $rl
		Debug.config {BCMD $index: ($left) ($right) '$rl' - MD:($metadata)}
	    } else {
		# we only transform the script top level
	    }
	} Nc {
	    # comment associates with immediately prior variable
	    dict set comments $section $varname [lindex $body {*}$index]
	} Ne {
	    set cmd [lindex $parse {*}$index]
	    error "Syntax Error - $cmd"
	}

	Debug.config {section: raw:($raw)}
    }

    # parse a file in config format
    method load_section {section file} {
	package require fileutil
	my parse_section $section [::fileutil::cat -- $file]
    }

    # merge raw, comments and metadata dicts for given section
    method merge_section {section args} {
	variable raw; variable comments; variable metadata
	variable clean 0
	lassign $args _raw _comments _metadata
	dict set raw $section [dict merge [dict get? $raw $section] $_raw]
	dict set comments $section [dict merge [dict get? $comments $section] $_comments]
	dict set metadata $section [dict merge [dict get? $metadata $section] $_metadata]
    }

    # parse a complete configuration into raw, comments and metadata
    method parse {script} {
	variable raw; variable comments; variable metadata

	set parse [parsetcl simple_parse_script $script]
	parsetcl walk_tree parse index Cd {
	    set cmd [lindex $parse {*}$index]
	    if {[llength $index] == 1} {
		set meta [lassign $cmd . . . left]
		set right [lindex $meta end]
		set meta [lrange $meta 0 end-1]

		set section [parsetcl unparse $left]
		if {![string match L* [lindex $left 0]]} {
		    error "section name '$section' must be a literal ($left)"
		}

		# accumulate per-section metadata
		foreach md $meta {
		    dict set metadata $section "" [parsetcl unparse $md]
		}
		
		# parse raw body of section
		my parse_section $section [lindex [parsetcl unparse $right] 0]
	    } else {
		# we only transform the top level of script
	    }
	} C.* {
	    error "Don't know how to handle [lindex $parse {*}$index]"
	} Nc {
	    # comment
	    set cmd [lindex $parse {*}$index]
	    #puts stderr "Comment - $cmd"
	} Ne {
	    set cmd [lindex $parse {*}$index]
	    error "Syntax Error - $cmd"
	}

	Debug.config {parse: ($raw)}
    }

    # merge a raw, commants and metadata dicts
    method merge {args} {
	lassign $args _raw _comments _metadata
	foreach section [dict keys $_raw] {
	    my merge_section $section [dict get $_raw $section] [dict get? $_comments $section] [dict get? $_metadata $section]
	}
    }

    # parse a file in config format
    method load {file} {
	package require fileutil
	my parse [::fileutil::cat -- $file]
    }

    method assign {args} {
	variable raw; dict set raw {*}$args
	variable clean 0	
    }
    method assign? {args} {
	variable raw; 
	if {![dict exists $raw {*}[lrange $args 0 end-1]]} {
	    dict set raw {*}$args
	    Debug.config {assign? $args -> [dict get $raw {*}[lrange $args 0 end-1]]}
	}
	variable clean 0	
    }

    method get {args} {
	my eval
	variable extracted
	return [dict get $extracted {*}$args]
    }

    # substitute section-relative names into value scripts
    method VarSub {script} {
	set NS [namespace current]
	Debug.config {VarSubbing: '$script'}

	# perform variable rewrite
	set body [parsetcl simple_parse_script $script]
	parsetcl walk_tree body index Sv {
	    set s [lindex $body {*}$index 3 2]
	    if {![string match ::* $s] && [string match *::* $s]} {
		# this is section-relative var - we need to make a fully qualified NS
		set s "${NS}::_C::$s"
		lset body {*}$index 3 2 $s
	    }
	    Debug.config {Varsub: $s}
	}
	set subbed [parsetcl unparse $body]
	set subbed [join [lrange [split $subbed \n] 1 end-1] \n]	;# why is this necessary?
	Debug.config {VarSubbed: '$script' -> '$subbed'}
	return $subbed
    }

    # eval_section - evaluate a section dict after variable substitution
    method eval_section {section} {
	variable raw
	set ss {}
	Debug.config {evaling section '$section'}
	dict for {n v} [dict get $raw $section] {
	    set sv [my VarSub $v]
	    Debug.config {eval section '$section': $n $v ($sv)}
	    namespace eval _C::$section "variable $n $sv"
	}
    }

    # evaluate a raw dict after variable substitution
    method eval {} {
	variable clean
	variable raw
	if {!$clean} {
	    # only re-evaluate if not clean
	    foreach section [dict keys $raw] {
		my eval_section $section
	    }
	    set clean 1
	    return 1
	} else {
	    return 0
	}
    }

    # sections - a list of sections
    method sections {{glob {}}} {
	variable raw; return [dict keys $raw {*}$glob]
    }

    # section - get evaluated section
    method section {section} {
	my eval	;# evaluate any changes in raw
	Debug.config {getting section '$section'}
	set result {}
	foreach var [info vars _C::${section}::*] {
	    try {
		set val [set $var]
		dict set result [namespace tail $var] $val
		Debug.config "got '$section.[namespace tail $var]' <- '$val'"
	    } on error {e eo} {
		Debug.error "Config [self]: can't read '[namespace tail $var]' while evaluating section '$section'"
	    }
	}
	return $result
    }

    method exists {args} {
	variable raw
	return [dict exists $raw {*}$args]
    }

    # extract naming context from configuration and aggregated namespace
    method extract {{config ""}} {
	if {$config ne ""} {
	    # parse $config if proffered
	    my parse $config
	}

	# evaluate any changes in raw
	variable extracted
	if {![my eval]} {
	    return $extracted
	}

	# extract the accumulated values from _C namespace children
	set extracted {}
	foreach section [my sections] {
	    dict set extracted $section [my section $section]
	}

	return $extracted
    }

    # bind - bind all values to their evaluated value
    method bind {} {
	variable raw [my extract]
    }

    method todict {} {
	dict set result raw [my raw]
	dict set result comments [my comments]
	dict set result metadata [my metadata]
	return $result
    }

    method tolist {} {
	return [list [my raw] [my comments] [my metadata]]
    }

    # raw - access raw values
    method raw {{section ""}} {
	variable raw
	if {$section eq ""} {
	    return $raw
	} else {
	    return [dict get $raw $section]
	}
    }

    # comments - access comment values
    method comments {{section ""}} {
	variable comments
	if {$section eq ""} {
	    return $comments
	} else {
	    return [dict get $comments $section]
	}
    }

    # metadata - access metadata values
    method metadata {{section ""}} {
	variable metadata
	if {$section eq ""} {
	    return $metadata
	} else {
	    return [dict get? $metadata $section]
	}
    }

    # aggregate a list of Config objects
    method aggregate {args} {
	foreach a $args {
	    my merge {*}[$a tolist]
	}
    }

    # destroy context namespace
    method clear {} {
	variable raw {}	;# association between name and tcl script giving value
	variable comments {}	;# association between name and run-on comments
	variable metadata {}	;# association between name and metadata

	# destroy evaluation namespace
	catch {namespace delete _C}
	namespace eval _C {}
	variable clean 1
    }

    constructor {args} {
	Debug.config {Creating Config [self] $args}
	if {[llength $args]%2} {
	    set cf [lindex $args end]
	    set args [lrange $args 0 end-1]
	    dict set args config $cf
	}
	variable {*}$args
	#catch {set args [dict merge [Site var? Config] $args]}	;# allow .ini file to modify defaults -- config is, itself, not Configurable

	my clear	;# start with a clean slate

	if {[info exists file]} {
	    my load $file	;# parse any file passed in
	}

	if {[info exists config]} {
	    my parse $config	;# parse any literal config passed in
	}
    }
}

if {[info exists argv0] && ($argv0 eq [info script])} {
    Debug on config 10

    Config create config
    puts stderr "DICT: [config extract {
	section {
	    var val	;# this is a variable
	    var1 val1
	    v1 2
	    v2 [expr {$v1 ** 2}]
	}
	# another section 
	sect1 {
	    v1 [expr {$section::v1 ^ 10}]
	    ap -moop moopy [list moop {*}$::auto_path]
	}
	sect_err -sectmetadata yep {
	    xy -varmetadata yep {this is an error $moop(m}
	}
    }]"
}
