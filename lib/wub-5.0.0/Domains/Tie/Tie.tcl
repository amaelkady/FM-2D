# Tie domain - maps namespace variables to Urls
package require Debug
Debug define tie 10

package require Report

package provide Tie 1.0

set ::API(Experimental/Tie) {
    {
	Experimental domain mapping from namespace variables to Urls.  Each namespace needs to [add] itself to the Tie.
    }
    mime {default mime type of responses (default: x-text/html-fragment)}
}

# TODO:
# per-variable perms
# generalise to be able to handle all the vars in a namespace, not just a specific one.
# check dict mods so they stay as dicts, else it can break
# make textareas autogrow

namespace eval ::Tie {
    variable mount /tie/	;# (default) mount point for vars
    variable mime x-text/html-fragment	;# default mime type of responses
    variable icons 
    dict set icons delete [<img> width 32px alt "delete field" src /icons/remove.gif]
    dict set icons revert [<img> width 32px alt "revert field" src /icons/rewind.gif]
    dict set icons edit [<img> width 32px alt "edit field" src /icons/notes_edit.gif]
    dict set icons add [<img> width 24px alt "add field" src /icons/add.gif]

    proc perms {r op args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}
	return 1
    }

    variable vars {}

    proc mod {nvar name1 name2 op} {
	variable vars
	dict set vars $nvar -mtime [clock seconds]
	Debug.tie {mod $nvar $name1 $name2}
    }

    proc add {name args} {
	Debug.tie {tie $name $args}
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}

	# get the variable we want to tie
	set nvar [uplevel 1 namespace which -variable $name]
	set ns [namespace qualifiers $nvar]
	set name [namespace tail $nvar]
	if {$ns eq ""} {
	    set ns ::
	}

	Debug.tie {tie nvar:'$nvar' ns:'$ns' name:'$name'}

	# get full URL of variable
	set prefix [dict get? $args -prefix]
	set fname $prefix/$name

	# store args in vars against variable's full URL
	variable vars
	dict set args -name $name
	dict set args -ns $ns
	dict set args -nvar $nvar
	dict set args -mtime [clock seconds]
	variable mime
	dict set vars $fname [dict merge [list -format {* tcl} -mode 770 -guid 0 -uid 0 -mime $mime] $args]

	Debug.tie {tie done ($vars)}

	# TODO: persist changes

	# monitor variable for changes as variable
	namespace upvar $ns $name var
	trace add variable var write [list ::Tie::mod $fname]
    }

    proc conditional {r dope} {
	# check conditional
	if {[dict exists $r if-modified-since]} {
	    set since [Http DateInSeconds [dict get $r if-modified-since]]
	    if {[dict get $dope -mtime] <= $since} {
		Debug.tie {NotModified: $dope < [dict get $r if-modified-since]}
		return -code return [Http NotModified $r]
	    }
	}
    }

    proc probe {probe format} {
	Debug.tie {probe: $format probe:$probe}
	while {[llength $format] > 1
	       && [llength $probe] > 0
	   } {
	    dict for {fk fv} $format {
		set found 0
		set p [lindex $probe 0]
		foreach m $fk {
		    if {[string match $m $p]} {
			# found a matching element
			if {[llength $probe] == 1} {
			    # finished the probe
			    Debug.tie {probe done: $probe probe:$fv}
			    return [list $probe $fv]
			} else {
			    set probe [lrange $probe 1 end]
			    set format $fv
			    Debug.tie {probe repeat: $probe in $fv}
			    set found 1
			    break
			}
		    }
		    if {$found} break
		}
		if {$found} break
	    }
	}
	Debug.tie {probe none: $format probe:$probe}
	return [list $probe $format]
    }

    proc single {r name el value format} {
	switch -- $format {
	    text -
	    bool {
		set value [string trim $value \n]
		set value [::textutil::untabify $value]
		set value [::textutil::undent $value]
		set value [armour $value]
		set form [<form> F$name action $el {
		    [<hidden> op "mod"]
		    [<hidden> field $name]
		    [<text> value $value][<submit> S$name]
		}]
		return $form
	    }

	    textarea -
	    default {
		set value [string trim $value \n]
		set value [::textutil::untabify $value]
		set value [::textutil::undent $value]
		set value [armour $value]
		append value \n
		set form [<form> F$name action $el {
		    [<hidden> op "mod"]
		    [<hidden> field $name]
		    [<textarea> value class autogrow style {width:80%} $value][<submit> S$name]
		}]
		return $form
	    }
	}
    }

    variable tparams {
	sortable 1
	evenodd 1
	class table
	tparam {style {width:80%}}
	hclass header
	hparam {title "click to sort"}
	thparam {class thead}
	fclass footer
	tfparam {class tfoot}
	rclass row
	rparam {title row}
	eclass el
	eparam {}
	footer {}
    }

    proc format {r el format path value} {
	Debug.tie {format: '$format' path:$path}
	lassign [probe $path $format] probe format
	Debug.tie {probed format: $format probe:$probe for $path}

	# header
	variable mount
	append result [<h1> "$mount$el/$path [<a> href . {(Parent Node)}]"]
	if {[llength $format] == 1} {
	    return "$result\n[single $r $probe $mount$el/$path $value $format]"
	}

	variable icons
	set count 0
	set table {}
	Debug.tie {formatting dict [dict keys $value]}
	dict for {k v} $value {
	    if {$k eq ""} continue	;# skip empty keys until we can work that out
	    set addr [string map {// /} "$mount$el/$path/$k"]
	    lassign [probe $k $format] p fm
	    if {[llength $fm] > 1} {
		set kl {}
		foreach ke [dict keys $v] {
		    lappend kl [<a> href [string map {// /} $mount$el/$k/$ke] $ke]
		}
		lappend kl [<a> href $addr?op=new [dict get $icons add]]
		set v [join $kl " "]
		set dict 1
		Debug.tie {subdict keys}
	    } else {
		Debug.tie {VAL:'$v'}
		set v [single $r $k $addr $v $fm]
		set dict 0
	    }

	    set n [<a> href $addr $k]

	    dict set table [incr count] [list name $n value $v E [<a> href $addr [dict get $icons edit]] R [<a> href $addr?op=revert [dict get $icons revert]] D [<a> href $addr?op=del [dict get $icons delete]]]
	}

	# now make a table out of it all.
	variable tparams
	append result [Report html $table {*}$tparams headers {name value E R D} evenodd 0] \n

	# form to add a new value to the dict
	append result [<form> F {
	    [<hidden> op "new"]
	    [<submit> S "New Field:"][<text> field title "field name"]
	    [<textarea> value title "field value" class autogrow style {width:80%}]
	}] \n
	
	Debug.tie {format '$path' -> '$result'}
	return $result
    }

    proc do {r} {
	# calculate the suffix of the URL relative to $mount
	variable mount
	lassign [Url urlsuffix $r $mount] result r suffix path
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	variable vars
	set s [split $suffix /]
	if {[dict exists $vars [set el [join [lrange $s 0 1] /]]]} {
	    # two element match
	    set s [lrange $s 2 end]
	} elseif {[dict exists $vars [set el [lindex $s 0]]]} {
	    # one element match
	    set s [lrange $s 1 end]
	} else {
	    # no element match - not found
	    return [Http NotFound $r]
	}

	# hook into the variable
	set dope [dict get $vars $el]
	namespace upvar [dict get $dope -ns] [dict get $dope -name] var

	Debug.tie {METHOD [dict get $r -method]}
	switch -- [dict get $r -method] {
	    PUT -
	    POST {
		Debug.tie {POST '$suffix'}
		if {![perms $r w $dope]} {
		    return [Http Forbidden $r]
		}

		# effect changes
		set query [Query parse $r]
		dict set r -Query $query
		set qf [Query flatten $query]
		Debug.tie {POST Q '$qf'}
		if {[dict exists $qf field]
		    && [set field [dict get $qf field]] ne ""
		    && [dict exists $qf value]
		} {
		    if {[dict exists $var {*}$s]} {
			namespace upvar [dict get $dope -ns] [dict get $dope -name] var
			dict set var {*}$s [dict get $qf value]
		    } else {
		    }
		} else {
		    return [Http Forbidden $r]
		}
		# TODO: persist changes

		# we've made the mod - now notify the owner
		if {[dict exists $dope -notify]
		    && [dict get $dope -notifier] ne ""
		} {
		    # tweak notifier
		    {*}[dict get $dope -notify] $el {*}$s
		}

		# return to referer
		return [Http RedirectReferer $r]
	    }
	    
	    GET {
		if {![perms $r r $dope]} {
		    return [Http Forbidden $r]
		}

		# check conditional modification
		conditional $r $dope
		set content [format $r $el [dict get? $dope -format] $s [dict get $var {*}$s]]
		set mime [dict get? $dope -mime]
		if {$mime eq ""} {
		    set mime x-text/html
		}

		set r [jQ autogrow $r .autogrow]
		set r [jQ tablesorter $r .sortable]

		# return content
		return [Http Ok [Http DCache $r 0 private] $content $mime]
	    }
	    
	    default {
		return [Http Forbidden $r]
	    }
	}
    }

    proc create {junk args} {return [new {*}$args]}
    proc new {args} {
	variable {*}[Site var? Tie]	;# allow .ini file to modify defaults

	if {$args ne {}} {
	    variable {*}$args
	}
	add tparams -format {{tparam hparam thparam tfparam rparam eparam} {* tcl} {sortable evenodd} bool footer textarea * text}
	return Tie
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}
