# SqlQ --
#
# A Wub domain to return contents of a sqlite db

# TODO: make the package return only a CSV-like format (with 1st line as header?)
# and provide CSV->HTML and CSV->Sylk as Convert domain conversions.
# - force this by interpreting .sylk and .csv suffixes as indicating client's willingness
# to accept these formats, and jam the relevant mime types at the front of the accept
# request field.
# one reason this isn't already done is that I didn't want to force dependence on Convert,
# also there's a lot of wriggle room in CSV->HTML conversion, and it's not clear
# that Convert has enough user customisability.

package require OO
package require Query
package require Mime
package require Convert
package require Report
package require Debug

Debug define SqlQ 10

package provide SqlQ 1.0

set ::API(Domains/SqlQ) {
    {
	A domain to return contents of a tdbc by Sql SELECT
    }
}

namespace eval ::SqlQConvert {
    # parameters handed to Report for html table generation
    variable params {
	sepchar ,
	delchar \"
	sortable 1
	evenodd 1
	class table
	tparam {}
	hclass ""
	hparam {}
	thparam {}
	thrparam {}
	fclass ""
	tfparam {}
	tfrparam {}
	rclass ""
	rparam {}
	eclass ""
	eparam {}
	footer {}
    }
    proc params {args} {
	variable params
	set params [dict merge $params $args]
    }

    # convert synthetic TDBC type into a Sylk spreadsheet.
    proc .x-text/tdbc.application/x-sylk {r} {
	package require Sylk

	variable params
	set p [dict merge $params [dict get? $r -params]]
	set sepchar [dict get $p sepchar]
	set r [.x-text/tdbc.text/csv $r]
	set content [Sylk csv2sylk [dict get $r -content] $sepchar]

	return [dict merge $r [list -content $content content-type application/x-sylk]]
    }

    # convert synthetic TDBC type into CSV.
    proc .x-text/tdbc.text/csv {r} {
	package require csv

	variable params
	set p [dict merge $params [dict get? $r -params]]
	set sepchar [dict get $p sepchar]
	set delchar [dict get $p delchar]

	set content ""
	foreach record [dict get $r -content] {
	    Debug.SqlQ {cvs line: $record}
	    append content [::csv::join [dict values $record] $sepchar $delchar] \n
	}
	set header "#[::csv::join [dict keys $record] $sepchar $delchar]\n"

	return [dict merge $r [list -content $header$content content-type text/csv -raw 1]]
    }

    variable sortparam {}

    # convert synthetic TDBC type into HTML.
    proc .x-text/tdbc.x-text/html-fragment {r} {
	variable params
	variable sortparam
	set p [dict merge $params [dict get? $r -params]]
	Debug.SqlQ {Report: params:($p), [dict get? $p headers]}
	if {[dict get? $p sortable] ne ""} {
	    package require jQ
	    set r [jQ tablesorter $r .sortable {*}$sortparam]
	}
	set content {}
	set n 0
	foreach el [dict get? $r -content] {
	    dict set content $n $el
	    incr n
	}

	return [dict merge $r [list -content [Report html $content {*}$p] content-type x-text/html-fragment]]
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}

class create ::SqlQ {
    method selector {r vs} {
	# use query to determine fieldset
	set display_f {}
	set order_f {}
	set select_f {}
	set flags {}

	# get field descriptors from the query
	set q [Query parse $r]
	foreach {n v m} [Query nvmlist $q] {
	    catch {unset meta}
	    array set meta $m	;# field metadata from query
	    Debug.SqlQ {parse args: $n '$v' ($m)}
	    if {[info exists meta(-unassigned)]} {
		if {[string match -* $n]} {
		    # flag from &-field&
		    dict set flags $n 1
		} elseif {[string match ^* $n]} {
		    # order from &^field&
		    lappend order_f $meta(-count) [string trim $n ^]
		} else {
		    # display field indicated by &field&
		    dict set display_f $meta(-count) $n
		}
	    } elseif {[string match -* $n]} {
		# flag from &-field&
		dict lappend flags $n $v
	    } elseif {[string match ^* $n]} {
		# order from &^field&
		lappend order_f $meta(-count) [string trim $n ^]

		# select clause element indicatd by &field=expr
		lappend select_f [string trim $n ^] $v
	    } else {
		# select clause element indicatd by &field=expr
		lappend select_f $n $v
	    }
	}

	# get display fields from query in query order
	set display {}
	foreach n [lsort -integer [dict keys $display_f]] {
	    lappend display [dict get $display_f $n]
	}

	# get order fields from query in query order
	set order {}
	foreach n [lsort -integer [dict keys $order_f]] {
	    lappend order [dict get $order_f $n]
	}

	Debug.SqlQ {SqlQ query: display:($display) order:($order) flags:($flags) select:($select_f)}
	if {![llength $display]} {
	    set display *	;# there's no display, default to all
	}

	set select "SELECT [join $display ,]"
	if {[dict exists $flags -distinct]} {
	    append select " DISTINCT "
	    dict unset flags -distinct
	}
	append select " FROM "

	foreach flag {natural left inner outer cross} {
	    if {[dict exists $flags -$flag]} {
		append select " [string toupper $flag] "
		dict unset flags -$flag
	    }
	}
	if {[dict exists $flags -on]} {
	    append select " ON [dict get $flags -on]"
	    dict unset flags -on
	}
	if {[dict exists $flags -using]} {
	    append select " USING [join [dict get $flags -using] ,]"
	    dict unset flags -using
	}
	
	append select [join $vs ,]

	# calculate the selector from select clause elements
	set selector {}
	foreach {n v} $select_f {
	    set plain [string trim $n "%@=<>!^*"]
	    switch -glob -- $n {
		*% {
		    # like
		    lappend selector [list $plain LIKE '$v']
		}

		*@ {
		    # regexp
		    lappend selector [list $plain REGEXP '$v']
		}

		*[*] {
		    # glob
		    lappend selector [list $plain GLOB '$v']
		}

		*> {
		    lappend selector [list $plain > '$v']
		}

		*!< {
		    lappend selector [list $plain >= '$v']
		}

		*< {
		    lappend selector [list $plain < '$v']
		}

		*!> {
		    lappend selector [list $plain < '$v']
		}

		*! -
		*!= {
		    lappend selector [list $plain != '$v']
		}

		default {
		    lappend selector [list $n = '$v']
		}
	    }
	}

	set selector [join $selector " AND "]

	set selector [string trim $selector]
	if {$selector ne ""} {
	    append select " WHERE $selector"
	}

	if {[dict exists $flags -group]} {
	    append select " GROUP BY [join [dict get $flags -group] ,] "
	    dict unset flags -group
	}

	if {$order ne {}} {
	    append select " ORDER BY [join $order ,]"
	}
	
	if {[dict exists $flags -limit]} {
	    append select " LIMIT [dict get $flags -limit] "
	    dict unset flags -limit
	} else {
	    append select " LIMIT 500 "
	}
	if {[dict exists $flags -offset]} {
	    append select " OFFSET [dict get $flags -offset] "
	    dict unset flags -offset
	}

	Debug.SqlQ {select: $select}
	return $select
    }

    method /_cass {r} {
	variable css
	return [Http Ok $r $css text/css]
    }

    method /_tables {r {table {}}} {
	set result {}
	if {$table eq {}} {
	    Debug.SqlQ {tables: [$db tables]}
	    foreach {table v} [$db tables] {
		set key [<a> href _tables?table=$table $table]
		dict set v name $key
		dict unset v type
		dict set result $table $v
	    }
	} else {
	    dict for {n v} [$db columns $table] {
		dict set result [<a> href _columns?table=$table&column=$n $n] $v
	    }
	}
	set result [Report html $result]
	return [Http Ok $r $result]
    }

    method / {r} {
	# calculate the suffix of the URL relative to $mount
	lassign [Url urlsuffix $r $mount] result r view path
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	# use suffix to determine which view
	lassign [split $path .] -> ext
	Debug.SqlQ {$path -> $view '$ext'}

	# determine which views must be joined
	set view [split $view /]
	if {$views ne {}} {
	    foreach v $view {
		if {$v ni $views} {
		    do respond NotFound $r
		}
	    }
	}
	if {$view eq {}} {
	    return [my /_tables $r]
	}

	# generate a select from the query
	set select [my selector $r $view]

	# run the select and generate list-of-dicts content
	if {[info exists stmts($select)]} {
	    set stmt $stmts($select)
	} else {
	    set stmts($select) [set stmt [$db prepare $select]]
	}
	set content [$stmt allrows -as dicts]

	# calculate the desired content-type
	set mime [Mime MimeOf [string tolower $ext]]
	if {$mime eq "" || $mime eq "text/plain"} {
	    set mime text/html
	}
	Debug.SqlQ {desired content type of '$ext': $mime}

	# generate and pre-convert the response
	set r [Http Ok $r $content x-text/tdbc]
	dict set r -content $content

	dict set r -params $params	;# send parameters to conversion
	set r [::convert convert! $r $mime]
	return $r
    }

    variable db views csv tdbc local params stmts mount

    destructor {
	if {$local} {
	    $db close
	}
    }

    mixin Direct	;# use Direct to map urls to /methods

    constructor {args} {
	set db ""
	set file ""		;# db file
	set views {}		;# views which can be accessed by the domain
	set tdbc sqlite3	;# TDBC backend
	set params {}	;# parameters for Report in html table generation
	array set stmts {}
	variable css ""
	variable {*}[Site var? SqlQ]	;# allow .ini file to modify defaults

	foreach {n v} $args {
	    set [string trimleft $n -] $v
	    Debug.SqlQ {variable: $n $v}
	}

	# load the tdbc drivers
	package require $tdbc
	package require tdbc::$tdbc

	if {$db eq ""} {
	    # create a local db
	    set local 1
	    if {$file eq ""} {
		error "SqlQ must specify an open db or a file argument"
	    }
	    set db [self]_db
	    tdbc::${tdbc}::connection create $db $file 
	} else {
	    # use a supplied db
	    set local 0
	}

	Debug.SqlQ {Database $db: tables:([$db tables])}
    }
}

# add the tdbc converters to Convert
::convert namespace ::SqlQConvert
