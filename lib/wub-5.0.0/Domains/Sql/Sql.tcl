# Sql.tcl - provide a model abstraction for TDBC databases

package require OO

package require Debug
Debug define Sql 10

package provide Sql 1.0
package provide SqlT 1.0

set ::API(Domains/Sql) {
    {
	A domain to minimally implement the Sql part of MVC, where the underlying model is an SQL database.
	Sql returns each resultset record [[subst]]ed over ''form'' to give html fragments.
    }
    sql {the SQL command implementing the model (with :arg-substitution from the SQL query)}
    tdbc {the tdbc driver to use for SQL queries}
    db {optional tdbc database connection}
    maxrows {optional maximum number of rows which will be processed.}
    form {a Tcl script which will be [[subst]]ed for each element of the tdbc resultset, yielding an html fragment.}
    huddle {a Huddle descriptor for conversion to JSON}
}
set ::API(Domains/SqlT) {
    {
	A domain to minimally implement the Sql part of MVC, where the underlying model is an SQL database.
	SqlT converts the resultset into an HTML sortable table (default), a CSV file, or a Sylk spreadsheet, depending on the extension of the URL (.html, .csv or .sylk, respectively.)
    }
    sql {the SQL command implementing the model (with :arg-substitution from the SQL query)}
    tdbc {the tdbc driver to use for SQL queries}
    db {optional tdbc database connection}
    maxrows {optional maximum number of rows which will be processed.}
    csv {optional dict of args to tcllib's csv}
    report {optional dict of args to Report utility}
    sort {optional dict of args to jQ sortable}
    form {a Tcl script which will be [[subst]]ed for each element of the tdbc resultset, yielding an html fragment.}
    huddle {a Huddle descriptor for conversion to JSON}
}

class create ::Sql {
    # enform - convert resultset to html fragment in restricted scope
    method enform {:rs :form} {
	set :result ""
	set :cnt 0
	${:rs} foreach -as dicts :record {
	    dict set record "" ${:cnt}
	    dict with :record {
		append :result [subst ${:form}] \n
	    }
	    incr :cnt
	    unset :record
	}
	return ${:result}
    }

    method .x-tclobj/resultset.x-text/html-fragment {r} {
	variable form
	set rs [dict get $r -content]
	set result [my enform $rs $form]
	$rs close	;# close resultset

	return [Http Pass $r $result x-text/html-fragment]
    }

    method mime {r} {
	# calculate the suffix of the URL relative to $mount
	variable mount
	lassign [Url urlsuffix $r $mount] result r view path
	if {!$result} {
	    error "the URL isn't in $mount"
	}

	# use suffix to determine which view
	lassign [split $path .] -> ext
	Debug.Sql {$path -> $view '$ext'}

	# calculate the desired content-type
	set mime text/html
	set r [Http coerceTo $r $ext]

	Debug.Sql {desired content type of '$ext': $mime}
	return $r
    }

    method exec {args} {
	variable sqlP
	set rs [$sqlP execute $args]

	variable maxrows
	if {$maxrows > 0
	    && [$rs rowcount] > $maxrows
	} {
	    error "/ $args results in [$rs rowcount] rows, maximum is $maxrows"
	}
	return $rs
    }

    # get editable forms for matching records
    method / {r args} {
	Debug.Sql {Sql $args}
	set r [my mime $r]	;# the caller can select a mime type

	# proces the SQL generating a result set
	set rs [my exec {*}$args]
	Debug.Sql {generated [$rs rowcount] results}

	dict lappend r -convert [self]	;# convert our result
	return [Http Ok $r $rs x-tclobj/resultset]
    }

    destructor {
	variable local
	if {$local} {
	    variable db
	    $db close
	}
	catch {next}
    }

    superclass Convert
    mixin Direct
    constructor {args} {
	variable tdbc sqlite3	;# TDBC backend
	variable db ""
	variable maxrows 0
	variable sql

	# allow .ini file to modify defaults
	variable {*}[Site var? Sql]

	if {[llength $args] == 1} {
	    set args {*}$args
	}
	if {[llength $args]%2 == 1} {
	    set sql [lindex $args end]
	    set args [lrange $args 0 end-1]
	}
	variable {*}$args

	# load the tdbc drivers
	package require $tdbc
	package require tdbc::$tdbc

	if {$db eq ""} {
	    # create a local db
	    variable local 1
	    if {$file eq ""} {
		error "Sql must specify an open db or a file argument"
	    }
	    set db [self]_db
	    tdbc::${tdbc}::connection create $db $file 
	} else {
	    # use a supplied db
	    variable local 0
	}

	variable sqlP [$db prepare $sql]
	next {*}$args	;# construct Convert superclass
    }
}

class create ::SqlT {
    # convert synthetic TDBC type into CSV.
    method .x-text/dict.text/csv {r} {
	Debug.Sql {converting to text/csv}
	package require csv

	variable csv
	set sepchar [dict get $csv sepchar]
	set delchar [dict get $csv delchar]

	set content ""
	foreach record [dict get $r -content] {
	    Debug.Sql {cvs line: $record}
	    append content [::csv::join [dict values $record] $sepchar $delchar] \n
	}

	return [Http Pass $r $header$content text/csv]
    }

    # convert synthetic TDBC type into a Sylk spreadsheet.
    method .x-text/dict.application/x-sylk {r} {
	Debug.Sql {converting to x-sylk}
	package require Sylk

	variable csv
	set sepchar [dict get $p sepchar]
	
	set r [my .x-text/dict.text/csv $r]
	set content [Sylk csv2sylk [dict get $r -content] $sepchar]

	return [Http Pass $r $content application/x-sylk]
    }

    method .x-text/dict.x-text/html-fragment {r} {
	Debug.Sql {converting to html-fragment}

	# handle sortable tables
	variable report	;# report parameters
	if {[dict get? $report sortable] ne ""} {
	    package require jQ
	    variable sort	;# jQ sortable parameters
	    set r [jQ tablesorter $r .sortable {*}$sort]
	}

	set content {}
	set n 0
	foreach el [dict get $r -content] {
	    dict set content $n $el
	    incr n
	}

	return [Http Pass $r [Report html $content {*}$report] x-text/html-fragment]
    }

    method / {r args} {
	Debug.Sql {SqlT $args}
	set r [next $r {*}$args]	;# let Sql process the SQL

	# transform the resultset into a dict
	set rs [dict get $r -content]
	set content [$rs allrows -as dicts]
	Debug.Sql {fetched [$rs rowcount] data results}
	$rs close	;# close resultset

	# support huddle conversion
	variable huddle
	if {[info exists huddle]} {
	    dict set r -huddle $huddle
	}

	return [Http Pass $r $content x-text/dict]
    }

    superclass Sql
    constructor {args} {
	variable sort {}	;# parameters for jQ sortable
	variable csv {sepchar , delchar \"}	;# parameters for csv

	# parameters handed to Report for html table generation
	variable report {
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

	# allow .ini file to modify defaults
	variable {*}[Site var? SqlT]
	if {[llength $args] == 1} {
	    set args {*}$args
	}
	if {[llength $args]%2 == 1} {
	    set sql [lindex $args end]
	    set args [lrange $args 0 end-1]
	    dict set args sql $sql
	}
	variable {*}$args

	next {*}$args
    }
}

if {0} {
    package require sqlite3
    package require tdbc::sqlite3
    sqlite3 ::db_test $sqltestfile
    tdbc::sqlite3::connection create ::model $sqltestfile
    Nub domain /model/all SqlT db ::model sql "SELECT * FROM sources"
    Nub domain /model/big SqlT db ::model sql "SELECT * FROM sources WHERE size>:size"
}
