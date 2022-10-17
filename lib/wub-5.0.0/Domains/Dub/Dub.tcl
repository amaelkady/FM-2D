# Dub - database thingo for Wub
package require TclOO
namespace import oo::*

package require Debug
Debug define dub 10

package require Form
package require Report
package require jQ
package require View

package provide Dub 2.0

set ::API(Domains/Dub) {
    {
	provides a database view for Wub
    }
}

class create ::Dub {
    method literal {view} {return $view}
    method view {view} {
	if {![info exists names($view)]} {
	    puts stderr "view creating '$view' as $db.$view"
	    if {[catch {
		set names($view) [View create $db.$view]
		set v2n($names($view)) $view
	    } e eo]} {
		error "creating $db.$view - got this error '$e'"
	    }
	}
	return $names($view)
    }

    method open {view rec field} {
	set view [my {*}$view]
	if {[llength $view] > 1} {
	    error "Asked to open a non-view"
	}
	if {$field in [$view fields]} {
	    # we've actually been asked to fetch a field, not a view
	    return [list $field [$view get $rec $field]]
	}

	set key /$v2n($view)/$rec/$field
	if {![info exists names($key)]} {
	    puts stderr "open: $key"
	    set names($key) [$view open $rec $field]
	    Debug.dub {open: $names($key)}
	    set v2n($names($key)) "SubView $v2n($view)!$rec.$field"
	}
	return $names($key)
    }

    foreach n {join union concat different intersect minus map pair product hash indexed} {
	{*}[string map [list %M $n] {
	    method %M {lhs rhs args} {
		set key [list $lhs %M $rhs $args]
		Debug.dub {'$lhs' %M '$rhs' with '$args'}
		if {![info exists names($key)]} {
		    set vlhs [my {*}$lhs]
		    set vrhs [my {*}$rhs]
		    set names($key) [$vlhs %M $vrhs {*}$args]
		    if {$args ne ""} {
			set a " on [join $args ,]"
		    } else {
			set a ""
		    }
		    set v2n($names($key)) "%M of $v2n($vlhs) and $v2n($vrhs)$a"
		}
		return $names($key)
	    }
	}]
    }

    foreach n {flatten groupby ordered range} {
	{*}[string map [list %M $n] {
	    method %M {view args} {
		set key [list %M $view {*}$args]
		if {![info exists names($key)]} {
		    set names($key) [[my {*}$view] %M {*}$args]
		    set v2n($names($key)) "%M of $v2n($names($view))"
		}
		return $names($key)
	    }
	}]
    }

    method select {view} {
	corovars query
	set q {}
	dict for {n v} $query {
	    if {$v ne ""} {
		lappend q $n $v
	    }
	}
	set key [list select $view {*}$q]
	Debug.dub {select looking for 'select $view $q' over view:'$view'}
	if {![info exists names($key)]} {
	    set v [my {*}$view]
	    set names($key) [$v select {*}$q]
	    set v2n($names($key)) "select $v2n($v) with '$q'"
	}
	Debug.dub {select over '$view' ($v size [$v size]) with ($q) -> $names($key) of size [$names($key) size]}
	return $names($key)
    }

    method toplevel {r} {
	set vi {}
	foreach v [::mk::file views $db] {
	    lappend vi [<li> [<a> href $v/ $v]]
	}
	append result [<h2> "Native Views"]
	append result [<ul> [join $vi \n]] \n

	if {$canned ne ""} {
	    set c {}
	    foreach v [$canned list name] {
		lappend c [<li> [<a> href $v/ $v]]
	    }
	    append result [<h2> "Canned Views"]
	    append result [<ul> [join $c \n]] \n
	}

	return [Http Ok $r $result x-text/html-fragment]
    }

    method /info {r cmd {rec ""}} {
	if {[string is integer -strict $rec]} {
	    error "Can't get .info on a single record"
	}
	set view [my {*}$cmd]
	dict for {n v} [$view info2dict] {
	    lappend result [<tr> "[<th> $n][<td> [<text> $n ""]]"]
	}
	set result [<table> [join $result \n]]
	append result \n [<submit> search]
	set result [<form> action select $result]

	return [Http Ok $r $result x-text/html-fragment]
    }

    method record {r view record rec} {
	dict for {n v} $record {
	    lappend fields [<text> $n label $n $v]
	}
	lappend fields [<div> style {margin-top: 10px} "[<a> href . class paginate_button Up] [<a> class paginate_button href 0 First] [<a> class paginate_button href .prev Prev] [<a> class paginate_button href .next Next] [<a> class paginate_button href [expr {[$view size]-1}] Last]"]
	set result [<fieldset> record [join $fields <br>\n]]
	set result [<form> fields action .save $result]\n

	corovars query
	set script ""
	set subv ""
	foreach s [$view subviews] {
	    set id $v2n($view)_$s
	    set url ./$rec/$s/
	    append subv [<div> id $id [<a> href $url $s]] \n

	    set load [string map [list %ID #$id] {
		$('%ID .dubtable').dataTable({sPaginationType:'full_numbers', sDom:'tr<"bottom"pifl<"clear">'});
		$('%ID').buildContainers({elementsPath:'/jquery/elements/',containment:'document'});
	    }]
	    append script "\$('#$id').load('$url',{IN_:1},function (responseText, textStatus, XMLHttpRequest) \{$load\});" \n
	}

	append result $subv

	set result [jQ container id record title "$v2n($view) #$rec" resizable true draggable false collapsed false iconized false $result]

	if {[dict get? $query IN_] eq ""} {
	    set r [jQ style $r jquery.datatables.css]
	    set r [jQ style $r mbContainer.css]
	    set r [jQ datatable $r .dubtable]
	    set r [jQ containers $r .containerPlus]
	}

	if {$script ne ""} {
	    append script {
		$.datepicker.setDefaults({dateFormat: 'dd/mm/yy'});
		$('input[title!=""]').hint();
	    }

	    set r [jQ ready $r $script]
	}
	return [Http Ok [Http NoCache $r] $result x-text/html-fragment]
    }

    method /find {r view} {
	corovars query
	set q {}
	dict for {n v} $query {
	    if {$v ne ""} {
		lappend q $n $v
	    }
	}

	Debug.dub {find '$q' over '$view'}
	set v [my {*}$view]
	set rec [$v find {*}$q]
	return [Http Redirect $r $rec]
    }

    method /form {r cmd {rec ""}} {
	corovars query
	Debug.dub {PRE /form ($query)}

	# filter out the dels
	set dels {} 
	foreach n [dict keys $query *.delete] {
	    lappend dels [lindex [split [dict get $query $n] .] end]
	    dict unset query $n
	}
	foreach n [dict keys $query *.delete,*] {
	    lappend dels [lindex [split [dict get $query $n] .] end]
	    dict unset query $n
	}

	# filter out the ops
	set ops {}
	foreach n [dict keys $query *._*] {
	    lappend ops [lindex [split $n .] end] [lindex [split [dict get $query $n] .] end]
	    dict unset query $n
	}

	# what remains is the record
	set record {}
	set external {}
	dict for {n v} $query {
	    lassign [split $n .] did name
	    if {$name eq ""} {
		dict set external $n $v
	    } elseif {$v ne ""} {
		dict set record $name $v
	    }
	    dict unset query $n
	}

	Debug.dub {/form '$cmd' DELETES $dels - $ops - ($record) - ($external)}

	set view [my {*}$cmd]

	foreach el [lsort -integer -decreasing $dels] {
	    $view delete $el
	}

	if {[join [dict values $record] ""] ne ""} {
	    $view append {*}$record
	}

	return [my / $r $cmd]
    }

    # range - construct a display for a dict representing a range of records
    method range {r view range} {
	set vn $v2n($view)

	if {$types ne ""} {
	    set ts [[[$types select view $vn] local] dict]
	    foreach key [dict keys $range] {
		dict set range $key @@view $vn
		dict set range $key @@types [dict get? $ts $vn]
	    }
	}

	set did DUB[incr idCnt]
	corovars query
	if {[dict get? $query IN_] eq ""} {
	    # load up editable
	    set r [jQ editable $r ".tedit" '.set' type 'text' submit "" cancel ""]

	    # load up datatables
	    set r [jQ style $r jquery.datatables.css]
	    set r [jQ style $r mbContainer.css]
	    set r [jQ hint $r]
	    set r [jQ datatable $r #$did]
	    set r [jQ datepicker $r .date]
	    set r [jQ containers $r .containerPlus]
	    set style {}
	    set drag false
	} else {
	    set style {}
	    set drag true
	}

	set params {}

	# per-element lambda to associate it with an id
	dict set params lambda [lambda {header record} {
	    set id ID_[lindex $record 0].[lindex $record 1]
	    append id _[string map {" " _} $header]
	    set value [dict get? $record $header]
	    if {$header eq "op_"} {
		return [list $value]
	    }

	    set class [list class tedit]
	    set type [dict get? [dict get? $record @@types] $header]

	    switch -- $type {
		date {
		    set value [clock format $value -format {%Y/%m/%d}]
		    set class [list class date]
		}
	    }
	    return [list $value id $id {*}$class]
	}]

	dict set params tparam id $did

	# calc header
	if {![dict exists $params headers]} {
	    set headers {}
	    foreach h [dict keys [$view fields]] {
		if {[dict get? $ts $h hide] ni {"" 0}} continue
		lappend headers $h
	    }
	} else {
	    set headers [dict get $params headers]
	}

	# calc footer
	set footer {}
	foreach h $headers {
	    lappend footer [<text> $did.$h title [string toupper $h] ""]
	}

	# add footer
	lappend footer [<submit> $did._submit DO]
	Debug.dub {FOOTER: $footer}
	dict set params footer $footer

	# add header
	lappend headers op_
	dict set params headers $headers

	# add 'op' element
	dict for {n v} $range {
	    #Debug.dub {op: $n ($v)}
	    dict set range $n op_ [<checkbox> $did.delete title Delete? value [dict get $v ""] checked 0]
	}

	set report [Report html $range {*}$params class dubtable id $did]
	set report [<form> $did._form action .form \n$report\n]
	set result [<div> class alt_pagination \n$report]

	set result [jQ container id record title $v2n($view) resizable true draggable $drag collapsed false iconized false {*}$style $result]

	return [Http Ok [Http NoCache $r] $result x-text/html-fragment]
    }

    method /layout {r cmd {rec ""}} {
	corovars query
	set view [my {*}$cmd]

	# set the view (layout)
	if {$view in [::mk::file views $db]} {
	    error "View $view already exists"
	}

	set layout {}
	dict for {n v} $query {
	    if {$v ne ""} {
		lappend layout $n:$v
	    } else {
		lappend layout $n
	    }
	}
	set layout [join $layout]
	
	set names($view) [View create $db.$view layout $layout]
	set v2n($names($view)) $view
	return [my / $r [list view $view] $rec]
    }

    method / {r cmd {rec ""}} {
	set view [my {*}$cmd]
	if {[llength $view] > 1} {
	    # got a field, not a view.
	    return [Http Ok [Http NoCache $r] [lindex $view 1] text/plain]
	}
	set rrange [split $rec -]
	if {[string is integer -strict $rec]} {
	    # single record
	    return [my record $r $view [$view get $rec] $rec]
	} elseif {[llength $rrange]} {
	    # subrange
	    lassign $rrange start end
	    for {set r $start} {$r < $end} {incr r} {
		dict set range $r [$view get $r]
	    }
	} else {
	    # whole view
	    Debug.dub {whole view: $view ($v2n($view)) [$view info]}
	    set range [$view dict]
	}

	return [my range $r $view $range]
    }

    method parse_referer {r} {
	set referer [Url parse [Http Referer $r] 1]
	lassign [Url urlsuffix $referer $mount] result r suffix
	if {!$result || $suffix eq "/"} {
	    error "$referer can't use .next"
	}

	set result [my parse $suffix]
	Debug.dub {parse_referer: $result}
	return $result
    }

    method /prev {r args} {
	lassign [my parse_referer $r] cmd parsed rec

	if {[string is integer -strict $rec]} {
	    if {$rec > 0} {
		incr rec -1
	    }
	} else {
	    set view [my {*}$parsed]
	    set rec [$view size]
	    incr rec -1
	}
	return [Http Redirect $r $rec]
    }

    method /next {r args} {
	lassign [my parse_referer $r] cmd parsed rec

	if {[string is integer -strict $rec]} {
	    set view [my {*}$parsed]
	    if {$rec < [$view size]-1} {
		incr rec
	    }
	} else {
	    set rec 0
	}
	return [Http Redirect $r $rec]
    }

    method /append {r cmd {rec ""}} {
	corovars query
	set view [my {*}$cmd]
	if {[llength $view] > 1} {
	    # asked to append to a field, not a view
	    lassign $cmd surview rec field
	    set surview [my {*}$surview]
	    set value "[$surview get $rec $field][dict get $query value]"
	    $surview set $rec $field $value
	    return [Http Ok [Http NoCache $r] $value text/plain]
	}
	if {[string is integer -strict $rec]} {
	    $view insert $rec {*}$query
	} else {
	    set rec [$view append]
	    $view set $rec {*}$query
	}
	return [my / $r $cmd $rec]
    }

    method /set {r cmd {rec ""}} {
	corovars query
	set view [my {*}$cmd]
	if {[llength $view] > 1} {
	    # asked to set a field, not a view
	    lassign $cmd surview rec field
	    set surview [my {*}$surview]
	    set value [dict get $query value]
	    $surview set $rec $field $value
	    return [Http Ok [Http NoCache $r] $value text/plain]
	}

	if {[string is integer -strict $rec]} {
	    $view set $rec {*}$query
	} else {
	    if {[dict exists $query id]} {
		set field [join [lassign [split [dict get $query id] _] -> id] _]
		lassign [split $id .] keyf keyv
		if {[catch {$view find $keyf $keyv} rec eo]} {
		    error "Can't find '$keyf' with value $keyv in view '$v2n($view)' to set field '$field'"
		} else {
		    set value [dict get $query value]
		    Debug.dub {Setting: view:$view rec:$rec field:$field to value:'$value'}
		    $view set $rec $field $value
		    return [Http Ok [Http NoCache $r] $value text/plain]
		}
	    } else {
		error "Can't set an entire view (yet)"
	    }
	}
	return [my / $r $cmd $rec]
    }

    # V == /$rec/$field+
    # FR == (/$field/$frec)*
    # RF == /$rec/$field* /$rec

    # VIEW == /$view
    #	| VIEW V
    #	| VIEW (/(join|union|concat|different|intersect|minus|map|pair|product|hash|indexed...) VIEW)*
    #	| VIEW (/blocked|clone|copy|dup|readonly|unique|...)
    #	| VIEW /select ?$select

    # VIEW /flatten/$property
    # VIEW /groupby (/$property*)
    # VIEW /range/$from/$to
    # VIEW /ordered (/$property*)

    # VIEW /name/$name - create a named temporary

    # VIEW RF ... - get a record
    # VIEW RF.edit ?$fields - get a given record in an editable form
    # VIEW - display range of view
    # VIEW RF /save ?$fields - save content
    # VIEW RF /insert ?$fields - insert content
    # VIEW /append ?$fields - append new content
    
    # VIEW RF /edit ?$fields - get a given record in an editable form
    
    # /$view/ /$el ?$search - element of a given search

    # /report/$report/ - get the results of a canned report over a canned selection
    # /report/$report/$search - get the results of a canned report over a specified selection

    # /next - next record in a given search order
    # /prev - previous record in a given search order

    method parse1 {path {parsed {}}} {
	# collect a run of record,fieldname
	set path [lassign $path view]
	if {$view in [::mk::file views $db]} {
	    Debug.dub {found '$view' in native views}
	    set parsed [list view $view]
	} elseif {$canned ne ""
		  && [$canned exists name $view]
	      } {
	    # is it a canned search?
	    Debug.dub {found canned search '$view' in native views}
	    lassign [my parse1 [$canned get [$canned find name $view] script]] path parsed
	} else {
	    Debug.dub {decided '$view' is literal}
	    set parsed [list literal $view]
	    #error "$view is not a known native or canned view"
	}

	Debug.dub {parser: path:$path parsed:$parsed}
	while {[llength $path]} {
	    Debug.dub {parser1: '$path' ($parsed)}
	    catch {unset field}
	    catch {unset rec}
	    if {[string is integer -strict [lindex $path 0]]} {
		set path [lassign $path rec field]
		if {$field eq ""} {
		    # field eq "" ... so we have a trailing rec
		    Debug.dub {trailing rec: '$path' ($parsed)}
		    lappend path $rec
		    return [list $path $parsed]
		} else {
		    # accumulate VIEW
		    Debug.dub {accumulate view: '$path' ($parsed)}
		    set parsed [list open $parsed $rec $field]
		}
	    } elseif {[llength [split [lindex $path 0] -]] == 2} {
		# range of results
		Debug.dub {range: '$path' ($parsed)}
		set path [lassign $path rec]
		lappend path $rec
		return [list $path $parsed]
	    } else {
		set path [lassign $path op]
		Debug.dub {op $op: path:'$path' ($parsed)}
		switch -glob -- [string tolower $op] {
		    join* - indexed*  {
			set args [lassign [split [string tolower $op] ,] op]
			set lhs $parsed
			lassign [my parse1 $path] path rhs
			set parsed [list $op $lhs $rhs {*}$args]
		    }

		    union - concat - different -
		    intersect - minus - map - pair -
		    product - hash {
			set lhs $parsed
			lassign [my parse1 $path] path rhs
			set parsed [list $op $lhs $rhs]
		    }

		    do {
			return [list $path $parsed]
		    }

		    find - 
		    search -
		    select {
			set parsed [list $op $parsed]
		    }

		    flatten {}
		    groupby {}
		    ordered {
			set parsed [list $op $parsed [lindex $path 0]]
			set path [lrange $path 1 end]
		    }
		    range {
			set parsed [list $op $parsed [lindex $path 0] [lindex $path 1]]
			set path [lrange $path 2 end]
		    }
		    name {
			set parsed [list name [lindex $path 0] $parsed]
			set path [lrange $path 1 end]
		    }
		    default {}
		}
	    }
	}
	Debug.dub {parser done: path:'$path' parsed:'$parsed'}
	return [list $path $parsed]
    }

    method parse {suffix} {
	set x [split $suffix .]
	set fop /[string trim [lindex $x end] .]
	set path [split [join [lrange $x 0 end-1]] /]
	set parsed {}
	Debug.dub {parse: fop:'$fop' path:'$path' suffix:'$suffix'}
	while {[llength $path]} {
	    lassign [my parse1 $path] path parsed
	    if {[llength $path] == 1
		&& [string is integer -strict [lindex $path 0]]
	    } break
	}
	Debug.dub {parsed:'$parsed' path:'$path'}
	return [list $fop $parsed {*}$path]
    }

    method do {r} {
	# calculate the suffix of the URL relative to $mount
	lassign [Url urlsuffix $r $mount] result r suffix
	if {!$result} {
	    return $r	;# the URL isn't in our domain
	}

	corovars query
	dict set r -Query [Query parse $r]
	set query [Query flatten [dict get $r -Query]]
	Debug.dub {Query $query ([dict get $r -Query])}

	if {$suffix eq "/"} {
	    return [my toplevel $r]	;# special case for top level
	}

	lassign [my parse $suffix] cmd parsed rec
	Debug.dub {doing cmd:'$cmd' parsed:'$parsed' rec:$rec suffix:$suffix query: ($query)}
	return [my $cmd $r $parsed {*}$rec]
    }

    variable file mount flags db names v2n types idCnt canned

    constructor {args} {
	set flags {}
	set canned ""
	set types ""
	set db [namespace tail [self]]
	foreach {n v} $args {
	    set [string trimleft $n -] $v
	}
	variable {*}[Site var? Dub]	;# allow .ini file to modify defaults

	::mk::file open $db $file {*}$flags

	if {$canned eq ""} {
	    if {[catch {View create $db.canned layout {name script}} canned]} {
		set canned ""
	    } else {
		set names(canned) $canned
		set v2n($canned) canned
	    }
	}

	if {$types eq ""} {
	    if {[catch {View create $db.types layout {view field info}} types]} {
		set types ""
	    } else {
		set names(types) $types
		set v2n($types) types
	    }
	}
	puts stderr "DUB [self] db:$db mount:$mount open:([::mk::file open])"
    }

    destructor {
    }
}

if {0} {
    set test [Dub new]
    foreach x {
	view/1
	view/1/subview/.append
	view/1/subview/2
	view/join/view2
	view/select
	view/select/5
	view/select/join/view1
	view/ordered/3
	view/join/view1/select
	view/1/subview/join/view1/2/subview2/select/5
	view/1/subview/ordered/1/select/join/view1/2/subview2/select/5
	view/1/subview/ordered/1/select/join/view1/2/subview2/pop/select/5
	view/1/subview/select/name/fred/join/view1/2/subview2/select/5
	view/1/subview/select/name/fred/join/view1/2/subview2/select/5-20
    } {
	puts stderr "PARSE($x) -> [$test parse $x]"
    }
}
