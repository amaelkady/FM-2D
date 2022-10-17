package require TclOO
package require Debug
Debug define wubwidgets 10
Debug define wubwinterp 10
Debug define wubwstyle 10

package provide WubWidgets 1.0

namespace eval ::WubWidgets {
    oo::class create widget {
	# tracker - return js to track state change
	method tracker {} {
	    return ""
	}

	# cget - get a variable's value
	method cget {n} {
	    set n [string trim $n -]
	    variable $n
	    return [set $n]
	}
	method cget? {n} {
	    set n [string trim $n -]
	    variable $n
	    if {[info exists $n]} {
		return [set $n]
	    } else {
		return ""
	    }
	}
	method cexists {n} {
	    set n [string trim $n -]
	    variable $n
	    return [info exists $n]
	}

	# access interp variables
	method iset {n v} {
	    variable interp
	    Debug.wubwinterp {iset '$n' <- '$v' traces:([{*}$interp [list trace info variable $n]]) ([lrange [info level -1] 0 1])}
	    return [{*}$interp [list set $n $v]]
	}

	method iget {n} {
	    variable interp
	    try { 
		set result [{*}$interp [list set $n]]
	    } on error {e eo} {
		set result ""
	    }

	    Debug.wubwinterp {iget '$n' -> '$result' ([lrange [info level -1] 0 1])}
	    return $result
	}

	method iexists {n} {
	    variable interp
	    set result [{*}$interp [list info exists $n]]
	    Debug.wubwinterp {iexists '$n' -> $result}
	    return $result
	}

	method itrace {what args} {
	    variable interp
	    variable trace
	    if {[llength $args]} {
		# add a trace
		dict set trace $what $args
		{*}$interp [list trace add variable $what write $args]
		Debug.wubwinterp {itrace add $what $args: ([{*}$interp [list trace info variable $what]])}
	    } elseif {[dict exists $trace $what]} {
		{*}$interp [list trace remove variable $what write [dict get $trace $what]]
		Debug.wubwinterp {itrace removed $what $args ([dict get $trace $what]) leaving ([{*}$interp [list trace info variable $what]])}
		dict unset trace $what
	    }
	}

	method reset {} {
	    variable change 0
	    my connection reset [self]
	}

	method changed? {} {
	    variable change
	    return $change
	}

	method setparent {parent} {
	    variable _parent $parent
	    oo::objdefine [self] forward parent $parent
 	}

	method prod {what} {
	    variable _parent
	    if {$_parent ne ""} {
		Debug.wubwidgets {prod '$_parent' with $what}
		my parent prod [self] ;# prod connection to push out changes
	    }
	}

	method change {{to ""}} {
	    variable change
	    if {$to eq ""} {
		incr change
		my prod [self]
	    } else {
		set change $to
	    }
	}

	# variable tracking
	method changevar {args} {
	    try {
		Debug.wubwinterp {[namespace tail [self]] changevar $args}
		my change	;# signal that a variable has changed value
	    } on error {e eo} {
		puts stderr "'$e' ($eo)"
		Debug.wubtkerror {[self] changevar $args - '$e' ($eo)}
	    }
	}

	# copy from text to textvariable
	method copytext {varname op args} {
	    try {
		variable textvariable
		variable igtext
		if {$igtext} {
		    Debug.wubwinterp {[namespace tail [self]] IGNORE copytext $textvariable}
		} else {
		    Debug.wubwinterp {[namespace tail [self]] copytexting $textvariable}
		    incr igtext
		    set value [my iget $varname]
		    set oldval [my iget $textvariable]
		    if {$value ne $oldval} {
			my iset $textvariable $value
			my change
		    }
		    incr igtext -1
		    Debug.wubwinterp {[namespace tail [self]] copytext $textvariable <- '$value'}
		}
	    } on error {e eo} {
		puts stderr "'$e' ($eo)"
		Debug.wubtkerror {[self] copytext $varname $op $args - '$e' ($eo)}
	    }
	}

	# copy from textvariable to text
	method copytextvar {varname op args} {
	    try {
		variable textvariable
		variable igtext
		if {$igtext} {
		    Debug.wubwinterp {[namespace tail [self]] IGNORE copytextvar text from '$textvariable'}
		} else {
		    Debug.wubwinterp {[namespace tail [self]] copytextvaring $textvariable}
		    incr igtext
		    variable text

		    set newval [my iget $textvariable]
		    if {![info exists text]
			|| $text ne $newval
		    } {
			set text $newval
			my change
		    }
		    incr igtext -1
		    Debug.wubwinterp {[namespace tail [self]] copytextvar text <- '$text' from '$textvariable'}
		}
	    } on error {e eo} {
		puts stderr "'$e' ($eo)"
		Debug.wubtkerror {[self] copytextvar $varname $op $args - '$e' ($eo)}
	    }
	}

	# configure - set variables to their values
	method configure {args} {
	    if {$args eq {}} {
		Debug.wubwidgets {[info coroutine] fetching configuration [self]}
		set result {}
		foreach var [info object vars [self]] {
		    if {![string match _* $var]} {
			variable $var
			lappend result $var [set $var]
		    }
		}
		return $result
	    }

	    Debug.wubwidgets {[info coroutine] configure [self] ($args)}
	    variable _parent ""

	    # install varable values
	    set tvchange 0
	    set vchange 0
	    set vars {}
	    dict for {n v} $args {
		set n [string trim $n -]
		my change

		variable $n
		switch -- $n {
		    textvariable {
			variable text	;# ensure there's a text variable
			# remove any old traces
			if {[info exists textvariable]} {
			    my itrace [set $n]
			    trace remove variable text write [list [self] copytext]
			}

			if {$v ne ""} {
			    # indicate new traces must be set
			    set textvariable $v
			    dict set vars textvariable $v
			    set tvchange 1
			} else {
			    # we've deleted the textvariable
			    unset textvariable
			}
		    }

		    text {
			# we have to record this, to allow textvar to settle
			set newtext $v
			dict set vars text $v
		    }

		    variable {
			if {[info exists variable]} {
			    # remove old traces
			    my itrace [set $n]
			}

			if {$v ne ""} {
			    # indicate new traces must be set
			    set variable $v
			    dict set vars variable $v
			    set vchange 1
			} else {
			    # we've deleted the -variable
			    unset variable
			}

			# add new trace after we've processed all args
		    }

		    value {
			# we have to record this, to allow variable to settle
			set newvalue $v
			dict set vars value $v
		    }

		    default {
			set $n $v
			dict set vars $n $v
		    }
		}
	    }

	    # result:
	    #
	    #	tvchange means new textvariable
	    #	newtext means new text value
	    #
	    #	vchange means new variable
	    #	newvalue means new value

	    ##################################################
	    # Handle -textvariable and -text
	    ##################################################
	    if {[info exists newtext]} {
		# we have new text value
		Debug.wubwidgets {new -text value '$newtext'}
		set text $newtext

		variable textvariable
		if {[info exists textvariable]} {
		    # set the textvar to new text value
		    Debug.wubwidgets {tracking -text changes with '$textvariable'}
		    my iset $textvariable $text
		}
	    }

	    # re-establish textvariable trace
	    if {$tvchange} {
		Debug.wubwidgets {tracking -textvariable '$textvariable' changes to -text}
		# copy from -text to textvariable
		variable text
		trace add variable text write [list [self] copytext]

		# copy changes from textvariable to text
		my itrace $textvariable ::.[my widget] copytextvar
	    }

	    # if we don't have a textvariable, and we don't have text
	    # then set text
	    variable text
	    variable textvariable
	    if {![info exists text] && ![info exists textvariable]} {
		set text ""
	    }

	    ##################################################
	    # Handle -variable and -value
	    ##################################################
	    if {[info exists newvalue]} {
		# we have new -value
		Debug.wubwidgets {new -value '$newvalue'}
		set value $newvalue
	    }

	    # re-establish -variable trace
	    if {$vchange} {
		Debug.wubwidgets {tracking -variable '$variable' changes}
		my itrace $variable ::.[my widget] changevar
	    }

	    Debug.wubwidgets {configured: $vars}
	    if {[info exists grid]} {
		# the widget needs to be gridded
		set rs 1; set cs 1; set r 0; set c 0
		Debug.wubwidgets {config gridding: '$grid'}
		set pargs [lsearch -glob $grid -*]
		if {$pargs > -1} {
		    # we've got extra args
		    set gargs [lrange $grid $pargs end]
		    set grid [lrange $grid 0 $pargs-1]
		} else {
		    set gargs {}
		}
		lassign $grid r c rs cs
		set ga {}
		foreach {v1 v2} {r row c column rs rowspan cs columnspan} {
		    if {[info exists $v1] && [set $v1] ne ""} {
			if {$v1 in {rs cs}} {
			    if {[set $v1] <= 0} {
				set $v1 1
			    }
			} else {
			    if {[set $v1] < 0} {
				set $v1 0
			    }
			}
			lappend ga -$v2 [set $v1]
		    }
		}
		Debug.wubwidgets {option -grid: 'grid configure .[my widget] $ga $gargs'}
		uplevel 3 [list grid configure .[my widget] {*}$ga {*}$gargs]
	    }
	}

	method interp {{i ""}} {
	    variable interp
	    if {$i eq ""} {
		return $interp
	    } else {
		set interp $i
	    }
	}

	method compound {text} {
	    set image [my cget? -image]
	    if {$image ne ""} {
		set image [uplevel 2 [list $image render]]
	    }

	    set text [armour $text]
	    switch -- [my cget? compound] {
		left {
		    return $image$text
		}
		right {
		    return $text$image
		}
		center -
		top {
		    return "$image[my connection <br>]$text"
		}
		bottom {
		    return "$text[my connection <br>]$image"
		}
		none -
		default {
		    # image instead of text
		    if {$image ne ""} {
			return "$image"
		    } else {
			return "$text"
		    }
		}
	    }
	}

	method type {} {
	    set class [string range [namespace tail [info object class [self]]] 0 end-1]
	}

	# record widget id
	method rc {args} {
	    variable row; variable col
	    if {[llength $args]} {
		lassign $args row col
	    }
	    return [list $row $col]
	}

	method wid {} {
	    return [string map {. _} [string trim [namespace tail [self]] .]]
	}
	method widget {} {
	    return [string trim [namespace tail [self]] .]
	}

	# calculate name relative to widget's parent
	method relative {} {
	    return [lindex [split [namespace tail [self]] .] end]
	}
	method gridname {} {
	    return [join [lrange [split [namespace tail [self]] .] 0 end-1] .]
	}

	method js {r} {
	    #Debug.wubwidgets {[namespace tail [self]] js requested by [info level -1]}
	    if {[set js [my cget? -js]] ne ""} {
		set js "<!-- widget js -->\n$js"
		set r [Html postscript $r $js]
	    }
	    return $r
	}

	# process the command associated with a browser click
	method command {args} {
	    set cmd [my cget? command]
	    if {$cmd eq "" && [my cexists postcommand]} {
		set cmd [my cget postcommand]
	    }

	    if {$cmd ne ""} {
		set cmd [string map [list %W .[my widget]] $cmd]
		Debug.wubwidgets {[namespace tail [self]] calling command ($cmd $args)}
		variable interp
		return [{*}$interp $cmd {*}$args]
	    }
	    return ""
	}

	# process the textvariable assignment associated with
	# a browser widget state change
	method var {value} {
	    variable igtext
	    if {[my cexists textvariable]} {
		set var [my cget textvariable]
		Debug.wubwidgets {[self] var: textvariable $var <- '$value'}
		incr igtext
		my iset $var $value
		incr igtext -1
	    }
	    if {[my cexists text]} {
		variable text
		Debug.wubwidgets {[self] var: text <- '$value'}
		incr igtext
		set text $value
		incr igtext -1
	    }
	}

	method getvalue {} {
	    variable text
	    variable textvariable
	    if {[info exists textvariable]} {
		Debug.wubwidgets {[self] getvalue from textvariable:'[my cget -textvariable]' value:'[my iget [my cget -textvariable]]'}
		set val [my iget [my cget -textvariable]]
		set result $val
	    } elseif {[info exists text]} {
		Debug.wubwidgets {[self] getvalue from text '$text'}
		set result $text
	    } else {
		Debug.wubwidgets {[self] getvalue default to ""}
		setresult ""
	    }
	    return $result
	}

	method slider {value} {
	    set var [my cget variable]
	    Debug.wubwidgets {[self] scale $var <- '$value'}
	    set oldv [my iget $var]
	    if {$oldv ne $value} {
		my iset $var $value
		my command
	    }
	}

	method cbutton {value} {
	    variable variable
	    Debug.wubwidgets {[self] cbutton: setting '$variable' to '$value'}
	    if {$value} {
		my iset $variable 1
	    } else {
		my iset $variable 0
	    }
	    my command
	}

	method rbutton {value {widget ""}} {
	    variable variable
	    Debug.wubwidgets {[self] rbutton: setting '$variable' to '$value' from widget '$widget'}
	    my iset $variable $value
	    if {$widget ne ""} {
		uplevel 1 [list .$widget command]
	    }
	}

	# style - construct an HTML style form
	method style {gridding} {
	    set attrs {}
	    foreach {css tk} {
		background-color background
		color foreground
		text-align justify
		vertical-align valign
		border borderwidth
		border-color bordercolor
		width width
	    } {
		variable $tk
		if {[info exists $tk] && [set $tk] ne ""} {
		    if {$tk eq "background"} {
			lappend attrs background "none [set $tk] !important"
			if {![info exists bordercolor]} {
			    dict set attrs border-color [set $tk]
			}
			# TODO: background images, URLs
		    } else {
			dict set attrs $css [set $tk]
		    }
		}
	    }

	    if {[my cexists -style]} {
		set attrs [dict merge $attrs [my cget -style]]
	    }

	    if {0} {
		# process -sticky gridding
		set sticky [dict gridding.sticky?]
		if {$sticky ne ""} {
		    # we have to use float and width CSS to emulate sticky
		    set sticky [string trim [string tolower $sticky]]
		    set sticky [string map {n "" s ""} $sticky];# forget NS
		    if {[string first e $sticky] > -1} {
			dict set attrs float "left"
		    } elseif {[string first w $sticky] > -1} {
			dict set attrs float "right"
		    }
		    
		    if {$sticky in {"ew" "we"}} {
			# this is the usual case 'stretch me'
			dict set attrs width "100%"
		    }
		}
	    }

	    # todo - padding
	    set result ""
	    dict for {n v} $attrs {
		append result "$n: $v;"
	    }
	    append result [dict gridding.style?]

	    if {$result ne ""} {
		set result [list style $result]
	    }

	    Debug.wubwstyle {style attrs:($attrs), style:($result)}

	    variable class
	    if {[info exists class]} {
		lappend result class $class
	    }

	    variable state
	    if {[info exists state] && $state ne "normal"} {
		lappend result disabled 1
	    }

	    variable title
	    if {[info exists title] && $title ne ""} {
		lappend result title $title
	    }

	    return $result
	}

	method update {args} {
	    return [my render {*}$args]
	}

	constructor {args} {
	    Debug.wubwidgets {Widget construction: self-[self] ns-[namespace current] path:([namespace path])}
	    oo::objdefine [self] forward connection [namespace qualifiers [self]]::connection
	    variable igtext 0

	    # ensure -interp is set, install alias for this object
	    variable interp [dict get $args -interp]
	    [lindex $interp 0] alias [namespace tail [self]] [self]
	    dict unset args -interp

	    variable _refresh ""
	    my configure {*}$args
	}
    }

    oo::class create buttonC {
	method tracker {} {
	    return [my connection buttonJS #[my wid]]
	}

	method render {args} {
	    set id [my wid]
	    set command [my cget? command]

	    if {$command ne ""} {
		set class {class button}
	    } else {
		set class {}
	    }

	    my reset
	    return [my connection <button> [my widget] id $id {*}$class {*}[my style $args] [my compound [my cget -text]]]
	    
	    #<button class="ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only" role="button" aria-disabled="false"><span class="ui-button-text">A button element</span></button>
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge {
		justify left
	    } $args]

	    if {[set var [my cget? variable]] ne ""} {
		if {![my iexists $var]} {
		    my iset $var ""
		}
	    }
	}
    }

    oo::class create selectC {
	method render {args} {
	    set id [my wid]
	 
	    set var [my cget textvariable]
	    if {[my iexists $var]} {
		set val [my iget $var]
	    }

	    set values [my cget -values]
	    Debug.wubwidgets {val=$val values=$values}
	    foreach opt $values {
		lappend opts [my connection <option> value [tclarmour $opt]]
	    }
	    set opts [join $opts \n]

	    #set command [my cget command]
	    my reset

	    set class {variable ui-widget ui-state-default ui-corner-all}
	    if {[my cexists combobox]
		&& [my cget combobox]
	    } {
		lappend class combobox
	    }
	    set result [my connection <select> [my widget] id $id class [join $class] {*}[my style $args] $opts]

	    Debug.wubwidgets {select render: '$result'}
	    return $result
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge [list -textvariable [my widget]] {
		justify left 
	    } $args]
	}
    }

    oo::class create comboboxC {
	method js {r} {
	    Debug.wubwidgets {combobox js}
	    set r [jQ combobox $r "#[my wid]"]
	    set r [next js $r]
	    return $r
	}
	
	superclass ::WubWidgets::selectC
	constructor {args} {
	    next {*}$args -combobox 1
	    my connection addprep combobox .combobox
	}
    }

    oo::class create checkbuttonC {
	method tracker {} {
	    return [my connection cbuttonJS #[my wid]]
	}

	method render {args} {
	    set id [my wid]

	    set label [my getvalue]

	    Debug.wubwidgets {checkbutton render: getting '[my cget variable]' == [my iget [my cget variable]]}
	    set val [my iget [my cget variable]]
	    if {$val ne "" && $val} {
		set checked 1
	    } else {
		set checked 0
	    }

	    Debug.wubwidgets {[self] checkbox render: checked:$checked}
	    my reset
	    set button [my connection <checkbox> [my widget] id ${id}_button {*}[my style $args] checked $checked [tclarmour [my compound $label]]]

	    # may have to filter stuff for [my style] here ... unsure
	    return [my connection <div> id $id {*}[my style $args] class cbutton $button]
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge [list -variable [my widget]] {
		justify left
	    } $args]
	}
    }

    # rbC - pseudo-widget which handles change events for a set of
    # radiobuttons sharing the same variable.
    oo::class create rbC {
	method render {args} {
	    error "Can't render an rbC"
	}
	method changed? {} {return 0}
	
	superclass ::WubWidgets::widget
 	constructor {args} {
	    next {*}$args	;# set up traces etc
	}
    }

    oo::class create radiobuttonC {
	method tracker {} {
	    return [my connection rbuttonJS #[my wid]]
	}

	method update {args} {
	    set id [my wid]
	    Debug.wubwidgets {radiobutton render: getting '[my cget variable]' == [my iget [my cget variable]]}

	    set checked 0
	    set var [my cget variable]
	    if {[my iexists $var]} {
		set val [my iget $var]
		if {$val eq [my cget value]} {
		    set checked 1
		}
	    }

	    Debug.wubwidgets {[self] radiobox render: checked:$checked}
	    my reset

	    set result [my connection <radio> [[my connection rbvar $var] widget] id $id class rbutton {*}[my style $args] checked $checked value [my cget value] data-widget \"[my widget]\" [dict args.label?]]
	    Debug.wubwidgets {RADIO html: $result}
	    return $result
	}

	method render {args} {
	    set id [my wid]

	    set label [tclarmour [my compound [my getvalue]]]
	    return [my update {*}$args label $label]
	}
	
	superclass ::WubWidgets::widget
 	constructor {args} {
	    next {*}[dict merge [list -variable [my widget]] {
		justify left
	    } $args]

	    # construct a grid var to give us a name
	    set var [my cget variable]
	    set rbvar [my connection rbvar $var]	;# construct a pseudo-widget to handle all rbs
	    Debug.wubwidgets {radiobutton construction: setting $var} 
	    #$rbvar iset $var [my cget value]
	}
    }

    oo::class create labelC {
	method render {args} {
	    set id [my wid]
	    set val [my getvalue]

	    my reset
	    return [my connection <div> id $id class label {*}[my style $args] [my compound $val]]
	}
	
	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge {
		justify "left"
	    } $args]
	}
    }
    
    oo::class create scaleC {
	method render {args} {
	    set id [my wid]
	    Debug.wubwidgets {scale $id render $args}

	    my reset

	    set result ""
	    if {[my cget label] ne ""} {
		set result [my connection <label> [my cget label]]
	    }

	    append result [my connection <div> id $id data-widget \"[my widget]\" class slider {*}[my style $args] {}]
	    Debug.wubwidgets {scale $id rendered '$result'}

	    return $result
	}

	method js {r} {
	    # need to generate the slider interaction
	    foreach {n v} [list orientation '[my cget orient]' min [my cget from] max [my cget to]] {
		lappend args $n $v
	    }

	    set r [jQ slider $r #[my wid] {*}$args value [my iget [my cget -variable]] change {
		function (event,ui) {
		    sliderJS(event, $(this).metadata().widget, ui);
		}
	    }]

	    set r [next $r]	;# include widget -js
	    return $r
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge [list -variable [my widget]] {
		justify left state active
		label "" command "" -length 100 -width 10 -showvalue 0
		-from 0 -to 100 -tickinterval 0
		-orient horizontal
	    } $args]
	}
    }
    
    oo::class create entryC {
	method tracker {} {
	    return [my connection variableJS #[my wid]]
	}
	method render {args} {
	    Debug.wubwidgets {[info coroutine] rendering Entry [self]}
	    set id [my wid]

	    my reset

	    set tag <text>
	    set extra {}
	    if {[my cexists type]} {
		switch -- [my cget type] {
		    password {
			set tag <password>
		    }
		    date -
		    default {
		    }
		}
	    }

	    set class {class variable}
	    set result [my connection $tag [my widget] id $id {*}$class {*}[my style $args] size [my cget -width] [tclarmour [my getvalue]]]
	    Debug.wubwidgets {Entry [my widget] - 'my connection $tag [my widget] id $id {*}$class {*}[my style $args] size [my cget -width] [tclarmour [my getvalue]]' -> '$result'}
	    return $result
	}

	method js {r} {
	    if {[my cexists type]} {
		switch -- [my cget type] {
		    date {
			set r [jQ datepicker $r #[my wid]]
		    }
		}
	    } elseif {[my cexists complete]} {
		set h {}
		foreach el [my cget complete] {
		    lappend h '[string map {' \'} $el]'
		}
		set h \[[join $h ,]\]
		set delay 0
	    } elseif {[my cexists command]} {
		set h \"[my widget]\"
		set delay 300
	    }

	    if {[info exists h]} {
		set r [jQ autocomplete $r #[my wid] source $h change {
		    function (event,ui) {
			autocompleteJS(event, $(this), ui.item);
		    }
		} delay $delay]
	    }

	    return [next $r]	;# include widget -js
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge {
		justify left
		state normal width 16
	    } $args]
	    if {[my cexists -show] && ![my cexists -type]} {
		my configure -type password
	    }
	}
    }

    # Html widget
    oo::class create htmlC {
	# render widget
	method render {args} {
	    set style [my cget style]
	    if {$style ne ""} {
		set content [<style> $style]\n
	    }
	    append content [my getvalue]
	    return $content
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge {} $args]
	}
    }

    # cookie widget - manipulate a cookie
    # can set/get/clear cookie
    # options -path -domain -expires, etc.
    oo::class create cookieC {
	# render widget
	method render {args} {
	    error "Can't render cookie widgets"
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    if {[string match *.* [namespace tail [self]]]} {
		error "cookie names must be plain identifiers"
	    }
	    next {*}[dict merge {} $args]

	    my connection cookie construct [self]

	    oo::objdefine [self] forward get my connection cookie get [self]
	    oo::objdefine [self] forward clear my connection cookie clear [self]
	    oo::objdefine [self] forward set my connection cookie set [self]
	}
    }

    # widget template - this is here to be copy/pasted
    # to make new widgets
    oo::class create junkC {
	# render widget - this is called to generate the HTML
	# which represents a widget.
	method render {args} {
	    # you have access, here, to whatever widget options
	    # which can be interpreted to generate
	    # HTML to represent the widget, which must be returned
	    return [<p> "This is a junk template"]
	}

	# optional - this is called to generate any js
	# which gives a widget special powers
	# leaving this out will also work
	method js {r} {
	    set r [next $r]	;# include widget -js
	    # generate whatever js inclusions, using
	    return $r	;# return the modified request
	}

	# changed? tells the enclosing grid whether or not
	# the HTML representation of the widget has changed.
	# generally this should be left to fall through
	# method changed? {} {return 0}

	superclass ::WubWidgets::widget	;# you may override its methods
	constructor {args} {
	    set defaults {}	;# here you specify default options
	    next {*}[dict merge $defaults $args]
	}
    }

    oo::class create textC {
	method tracker {} {
	    return [my connection variableJS #[my wid]]
	}
	method get {{start 1.0} {end end}} {
	    set text [my cget text]

	    if {$start == "1.0" && $end == "end"} {
		return $text
	    }

	    #separate indices into line and char counts
	    foreach {sline schar} [split $start .] {}
	    foreach {eline echar} [split $end .] {}

	    set text [my cget text]
	    set linecount [regexp -all \n $text]

	    #convert end indicies into numerical indicies
	    if {$schar == "end"} {incr sline; set schar 0}
	    if {$eline == "end"} {set eline $linecount; set echar 0; incr linecount}

	    #compute deletion start and ending points
	    set nlpos 0
	    set startpos 0
	    set endpos 0

	    for {set linepos 1} {$linepos <= $linecount} {incr linepos}    {

		if {$linepos == $sline} {
		    set startpos $nlpos
		    incr startpos $schar
		    #now we got the start position
		}

		if {$linepos == $eline} {
		    set endpos $nlpos
		    incr endpos $echar
		    #now we got the end point, lets blow this clam bake
		    break
		}

		incr nlpos
		set nlpos [string first \n $text $nlpos]
	    }

	    set text [string range $text $startpos+1 $endpos]
	    return $text
	}

	method delete {{start 1.0} {end end}} {
	    if {$start == "1.0" && $end == "end"} {
		set text ""
	    } else {
		#separate indices into line and char counts
		foreach {sline schar} [split $start .] {}
		foreach {eline echar} [split $end .] {}

		set text [my cget text]
		set linecount [regexp -all \n $text]

		#convert end indicies into numerical indicies
		if {$schar == "end"} {incr sline; set schar 0}
		if {$eline == "end"} {set eline $linecount; set echar 0; incr linecount}

		#compute deletion start and ending points
		set nlpos 0
		set startpos 0
		set endpos 0
		for {set linepos 1} {$linepos <= $linecount} {incr linepos}    {
		    Debug.wubwidgets {*** $linepos $nlpos}
		    if {$linepos == $sline} {
			set startpos $nlpos
			incr startpos $schar
			#now we got the start position
		    }

		    if {$linepos == $eline} {
			set endpos $nlpos
			incr endpos $echar
			#now we got the end point, so finish
			break
		    }

		    incr nlpos
		    set nlpos [string first \n $text $nlpos]
		}

		set text [string range $text 0 $startpos][string range $text $endpos+1 end]
	    }

	    my configure text $text
	    return $text
	}

	method insert {{start end} newtext} {
	    set text [my cget text]

	    if {$start == "end"} {
		#just tack the new text on the end
		append text $newtext
	    }    else {
		#we got work to do
		foreach {sline schar} [split $start .] {}
		set linecount [regexp -all \n $text]

		#compute insertion point
		set nlpos 0
		set startpos 0
		set endpos 0
		for {set linepos 1} {$linepos <= $linecount} {incr linepos}    {

		    if {$linepos == $sline} {
			set startpos $nlpos
			incr startpos $schar
			#now we got the start position
			break
		    }

		    incr nlpos
		    set nlpos [string first \n $text $nlpos]
		}

		#insett newtext at the char pos calculated in insertpos
		set text [string range $text 0 $startpos]${newtext}[string range $text ${startpos}+1 end]
	    }

	    my configure text $text
	    return $text
	}

	method render {args} {
	    set id [my wid]
	    set class {class variable}
	    
	    my reset
	    return [my connection <textarea> [my widget] id $id {*}$class {*}[my style $args] rows [my cget -height] cols [my cget -width] [armour [my getvalue]]]
	}
	
	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge {
		justify left
		state normal height 10 width 40
	    } $args]
	}
    }

    oo::class create wmC {
	foreach n {title header css background} {
	    method $n {widget args} [string map [list %N% $n] {
		if {$widget eq "."} {
		    variable %N%
		    if {[llength $args]} {
			set %N% [lindex $args 0]
		    }
		    if {[info exists %N%]} {
			return $%N%
		    } else {
			return ""
		    }
		} elseif {[llength $args]} {
		    return [$widget configure %N% [lindex $args 0]]
		} else {
		    return [$widget cget? %N%]
		}
	    }]
	}

	foreach n {stylesheet} {
	    method $n {widget args} [string map [list %N% $n] {
		if {$widget eq "."} {
		    variable %N%
		    if {[llength $args]} {
			set %N% $args
		    }
		    if {[info exists %N%]} {
			return $%N%
		    } else {
			return ""
		    }
		} elseif {[llength $args]} {
		    return [$widget configure %N% $args]
		} else {
		    return [$widget cget? %N%]
		}
	    }]
	}

	method script {args} {
	    return [my connection script]
	}

	constructor {args} {
	    variable title "WubTk"
	    variable header ""
	    variable {*}$args
	    oo::objdefine [self] forward connection [namespace qualifiers [self]]::connection
	    oo::objdefine [self] forward site my connection site
	    oo::objdefine [self] forward redirect my connection redirect
	}
    }

    oo::class create imageC {
	#method changed? {} {return 0}

	# record widget id
	method style {gridding} {
	    set result {}
	    foreach a {alt longdesc height width usemap ismap} {
		if {[my cexists $a]} {
		    lappend result $a [my cget $a]
		}
	    }
	    lappend result {*}[next $gridding]
	    return $result
	}
	
	method fetch {r} {
	    if {[my cexists -data]} {
		return [Http Ok $r [my cget -data] [my cget -format]]
	    } else {
		return [Http File $r [my cget -file] [my cget -format]]
	    }
	}

	method render {args} {
	    set url [my cget? url]
	    if {$url eq ""} {
		set url [my widget]
		set file [my cget? file]
		if {[my cexists -data]} {
		    append url ?md5=[::md5::md5 [my cget -data]]
		} elseif {$file ne ""} {
		    append url ?mtime=[file mtime $file]
		}
	    }
	    set up [Url parse $url]
	    if {0 && [string match *.svg [dict up.-path]]} {
		# intended to wrap svg in <object> so FF can render it
		# but it's impossible to get the dimensions right
		# without editing the svg source.
		set opts {width 32px height 32px}
		if {[my cexists width]} {
		    dict set opts width [my cget $width]
		}
		if {[my cexists height]} {
		    dict set opts height [my cget $height]
		}
		return [my connection <object> {*}$opts data $url ""]
	    } else {
		return [my connection <img> id [my wid] {*}[my style $args] src $url?fred=[clock seconds]]
	    }
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge [list id [my wid]] $args]

	    # TODO - add a -url option to deliver content
	    set fmt [my cget? -format]
	    switch -glob -nocase -- $fmt {
		gif* {
		    set fmt image/gif
		}
		png {
		    set fmt image/png
		}
		jpeg -
		jpg {
		    # no format specified
		    set fmt image/jpeg
		}
		default {
		    set fmt ""
		}
	    }

	    if {[my cexists -data]} {
		if {$fmt eq ""} {
		    set fmt image/jpeg
		}
	    } elseif {[my cexists -file]} {
		set fmt [Mime MimeOf [file extension [my cget -file]] $fmt]
	    } elseif {![my cexists url]} {
		error "Must specify either -data or -file"
	    }

	    my configure -format $fmt
	}
    }

    proc image {op args} {
	switch -- $op {
	    create {
		# create an image widget
		set ns [uplevel 1 {namespace current}]
		Debug.wubwidgets {image creation: $args ns: $ns}
		set args [lassign $args type]
		if {[llength $args]%2} {
		    set args [lassign $args name]
		    set result [imageC create ${ns}::$name type $type {*}$args]
		} else {
		    set result [uplevel 1 [list imageC new type $type {*}$args]]
		}
		Debug.wubwidgets {image created: $result}
		return $result
	    }
	}
    }

    # grid store grid info in an x/y array gridLayout(column.row)
    oo::class create gridC {
	# traverse grid looking for changes.
	method changes {r} {
	    if {[dict exists $r -repaint]} {
		# repaint short-circuits change search
		#Debug.wubwidgets {Grid '[namespace tail [self]]' repainting}
		return [list $r {}]
	    }

	    variable grid;variable oldgrid
	    #Debug.wubwidgets {Grid detecting changes: '[namespace tail [self]]'}

	    # look for modified grid entries, these will cause a repaint
	    dict for {row rval} $grid {
		dict for {col val} $rval {
		    if {$val ne [dict oldgrid.$row.$col?]} {
			# grid has changed ... force reload
			Debug.wubwidgets {[namespace tail [self]] repainting}
			dict set r -repaint 1
			return [list $r {}]	;# return the dict of changes by id
		    }
		}
	    }

	    if {[dict size [dict ni $oldgrid [dict keys $grid]]]} {
		# a grid element has been deleted
		Debug.wubwidgets {Grid repainting: '[namespace tail [self]]'}
		dict set r -repaint 1
		return [list $r {}]	;# return the dict of changes by id
	    }

	    set changes {}
	    dict for {row rval} $grid {
		dict for {col val} $rval {
		    dict with val {
			set type [uplevel 1 [list $widget type]]
			set changed {}
			switch -- $type {
			    accordion -
			    notebook -
			    frame {
				# propagate change request to geometry managing widgets
				#Debug.wubwidgets {Grid changing $type '$widget' at ($row,$col)}
				set changed [lassign [uplevel 1 [list $widget changes $r]] r]
				if {[dict exists $r -repaint]} {
				    Debug.wubwidgets {Grid '[namespace tail [self]]' subgrid repaint $type '$widget'}
				    return [list $r {}]	;# repaint
				} else {
				    #Debug.wubwidgets {Grid '[namespace tail [self]]' subgrid [string totitle $type] '$widget' at ($row,$col) ($val) -> ($changed)}
				}
			    }

			    default {
				if {[uplevel 1 [list $widget changed?]]} {
				    Debug.wubwidgets {[namespace tail [self]] changing: ($row,$col) $widget [uplevel 1 [list $widget type]] reports it's changed}
				    
				    set changed $widget
				    lappend changed [uplevel 1 [list $widget wid]]
				    lappend changed [uplevel 1 [list $widget update]]
				    lappend changed [uplevel 1 [list $widget type]]

				    Debug.wubwidgets {Grid '[namespace tail [self]]' accumulate changes to [string totitle $type] '$widget' at ($row,$col) ($val) -> ($changed)}
				}
			    }
			}

			lappend changes {*}$changed
			set r [uplevel 1 [list $widget js $r]]
		    }
		}
	    }

	    return [list $r {*}$changes]	;# return the dict of changes by id
	}

	method changed? {} {return 1}

	method tid {args} {
	    variable name
	    return [join [list grid {*}[string map {. _} $name] {*}$args] _]
	}

	# style - construct an HTML style form
	method style {gridding} {
	    set attrs {}
	    foreach {css tk} {
		background-color background
		color foreground
		text-align justify
		vertical-align valign
		border borderwidth
		border-color bordercolor
		width width
	    } {
		variable $tk
		if {[info exists $tk] && [set $tk] ne ""} {
		    if {$tk eq "background"} {
			lappend attrs background "none [set $tk] !important"
			if {![info exists bordercolor]} {
			    dict set attrs border-color [set $tk]
			}
			# TODO: background images, URLs
		    } else {
			dict set attrs $css [set $tk]
		    }
		}
	    }

	    if {0} {
		# process -sticky gridding
		set sticky [dict gridding.sticky?]
		if {$sticky ne ""} {
		    # we have to use float and width CSS to emulate sticky
		    set sticky [string trim [string tolower $sticky]]
		    set sticky [string map {n "" s ""} $sticky];# forget NS
		    if {[string first e $sticky] > -1} {
			dict set attrs float "left"
		    } elseif {[string first w $sticky] > -1} {
			dict set attrs float "right"
		    }
		    
		    if {$sticky in {"ew" "we"}} {
			# this is the usual case 'stretch me'
			dict set attrs width "100%"
		    }
		}
	    }

	    # todo - padding
	    set result ""
	    dict for {n v} $attrs {
		append result "$n: $v;"
	    }
	    append result [dict gridding.style?]

	    if {$result ne ""} {
		set result [list style $result]
	    }

	    Debug.wubwidgets {style attrs:($attrs), style:($result)}

	    variable class
	    if {[info exists class]} {
		lappend result class $class
	    }

	    variable state
	    if {[info exists state] && $state ne "normal"} {
		lappend result disabled 1
	    }

	    return $result
	}

	method render {args} {
	    variable name
	    variable parent	;# grid's parent is its frame or toplevel widget
	    variable maxrows; variable maxcols; variable grid
	    Debug.wubwidgets {'[namespace tail [self]]' whole grid render rows:$maxrows cols:$maxcols ($grid)}
	    set rows {}
	    set interaction {};
	    for {set row 0} {$row < $maxrows} {incr row} {
		set cols {}
		for {set col 0} {$col < $maxcols} {} {
		    set columnspan 1
		    if {[dict exists $grid $row $col]} {
			set el [dict get $grid $row $col]
			dict with el {
			    set id [my tid $row $col]
			    Debug.wubwidgets {'[namespace tail [self]]' grid rendering $widget/$id with ($el)}
			    uplevel 1 [list $widget rc $row $col]		;# set widget's id
			    uplevel 1 [list $widget setparent $parent] ;# record widget parent
			    set rendered [uplevel 1 [list $widget render style $style sticky $sticky]]

			    set wid .[string map {" " .} [lrange [split $id _] 1 end-2]]
			    for {set rt $row} {$rt < $rowspan} {incr rt} {
				set rspan($wid,[expr {$row + $rt}].$col) 1
				for {set ct $col} {$ct < $columnspan} {incr ct} {
				    set rspan($wid,$rt.[expr {$col + $ct}]) 1
				}
			    }

			    if {$rowspan != 1} {
				set rowspan [list rowspan $rowspan]
			    } else {
				set rowspan {}
			    }
			    lappend cols [my connection <td> id [my tid $row $col] colspan $columnspan {*}$rowspan $rendered]
			}
			incr col $columnspan
		    } else {
			if {[info exists wid] && ![info exists rspan($wid,$row.$col)]} {
			    lappend cols [my connection <td> id [my tid $row $col] "&nbsp;"]
			}
			incr col $columnspan
		    }
		}

		# now we have a complete row - accumulate it
		# align and valign not allowed here
		lappend rows [my connection <tr> id [my tid $row] style width:100% [join $cols \n]]
	    }

	    variable oldgrid $grid	;# record the old grid
	    set content [my connection <tbody> [join $rows \n]]
	    dict set args width 100%
	    variable border
	    if {$border} {
		set b [list border 1px]
	    } else {
		set b {}
	    }

	    set content [my connection <table> class grid {*}$b {*}[my style $args] $content]
	    Debug.wubwidgets {Grid '[namespace tail [self]]' rendered ($content)}
	    return $content
	}

	method js {r {w ""}} {
	    variable grid
	    if {$w ne ""} {
		return [uplevel 1 [list $w js $r]]
	    }

	    dict for {rc row} $grid {
		dict for {cc col} $row {
		    set r [uplevel 1 [list [dict get $col widget] js $r]]
		}
	    }
	    return $r
	}

	method configure {widget args} {
	    variable name
	    if {[string match .* $widget]} {
		set frame [lrange [split $widget .] 1 end]
		set widget $name$widget
	    } else {
		set frame [split $widget .]
		set widget $name.$widget
	    }
	    
	    if {[llength $frame] > 1} {
		Debug.wubwidgets {SubGrid '[namespace tail [self]]'/$frame gridding .[join $frame .]: '$name.[lindex $frame 0] grid configure [join [lrange $frame 1 end] .] $args'}
		uplevel 1 [list $name.[lindex $frame 0] grid configure [join [lrange $frame 1 end] .] {*}$args]
		return $widget
	    } else {
		Debug.wubwidgets {'[namespace tail [self]]' grid configure ($frame) $widget $args}
	    }

	    # set defaults
	    set column 0
	    set row 0
	    set columnspan 1
	    set rowspan 1
	    set sticky ""
	    set in ""
	    set style ""

	    foreach {var val} $args {
		set [string trim $var -] $val
	    }
	    
	    variable maxcols
	    set width [expr {$column + $columnspan}]
	    if {$width > $maxcols} {
		set maxcols $width
	    }
	    
	    variable maxrows
	    set height [expr {$row + $rowspan}]
	    if {$height > $maxrows} {
		set maxrows $height
	    }
	    
	    variable grid
	    dict set grid $row $column [list widget $widget columnspan $columnspan rowspan $rowspan sticky $sticky in $in style $style]

	    variable name
	    variable parent
	    Debug.wubwidgets {[namespace tail [self]] configure gridding $widget in [uplevel 1 {namespace current}]}
	    uplevel 1 [list $widget setparent $parent]	;# record widget's parent

	    #set id [my tid $row $column]
	    #uplevel 1 [list $widget id $id]	;# inform widget of its id

	    return $widget
	}

	constructor {args} {
	    Debug.wubwidgets {[self] GRID constructed ($args)}
	    variable maxcols 0
	    variable maxrows 0
	    variable border 0
	    variable name ""
	    variable parent [namespace qualifiers [self]]::connection	;# the . parent
	    variable {*}$args

	    variable grid {}
	    variable interest 0

	    oo::objdefine [self] forward connection [namespace qualifiers [self]]::connection
	}
    }

    # toolbar widget
    oo::class create toolbarC {
	method grid {cmd widget args} {
	    if {$cmd ne "configure"} return
	    Debug.wubwidgets {Toolbar [namespace tail [self]] gridding: $widget $args}
	    variable subw
	    dict set subw [dict get $args -row] $widget
	}

	# render widget
	method render {args} {
	    set id [my wid]
	    variable subw
	    set li {}
	    foreach n [lsort -integer [dict keys $subw]] {
		set w .[my widget].[dict get $subw $n]
		set sid ${id}_$n
		lappend li [my connection <li> [uplevel 1 [list $w render]]]
	    }
	    return [my connection <ul> id $id class {toolbar ui-widget ui-state-default ui-corner-all} {*}[my style $args] [join $li \n]]
	}

	method changed? {} {
	    return 0
	}
	
	method changes {r} {
	    variable subw
	    set changes {}
	    dict for {n tab} $subw {
		set changed [lassign [uplevel 1 [list $tab changes $r]] r]
		lappend changes {*}$changed
	    }
	    return [list $r {*}$changes]
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}$args
	}
    }

    # frame widget
    oo::class create frameC {
	method grid {args} {
	    variable fgrid
	    Debug.wubwidgets {Frame [namespace tail [self]] gridding: $fgrid $args}
	    uplevel 1 [list $fgrid {*}$args]
	}

	# render widget
	method render {args} {
	    variable fgrid
	    Debug.wubwidgets {Frame [namespace tail [self]] render gridded by $fgrid}
	    set id [my wid]

	    if {[my cexists -div] || [my cget? -text] eq ""} {
		append content \n [uplevel 1 [list $fgrid render]]
		return [my connection <div> id $id class frame {*}[my style $args] $content]
	    } else {
		set label [my cget? -text]
		if {$label ne ""} {
		    set content [my connection <legend> [tclarmour $label]]
		}
		variable fgrid
		append content \n [uplevel 1 [list $fgrid render]]
		return [my connection <fieldset> [my widget] class frame {*}[my style $args] -raw 1 $content]
	    }
	}

	method changed? {} {return 1}

	method changes {r} {
	    variable fgrid
	    #Debug.wubwidgets {Frame sub-grid changes '[namespace tail [self]]'}
	    set changes [lassign [uplevel 1 [list $fgrid changes $r]] r]
	    #Debug.wubwidgets {Frame sub-grid changed: '[namespace tail [self]]' ($changes)}
	    return [list $r {*}$changes]
	}

	method js {r} {
	    variable fgrid
	    set r [uplevel 1 [list $fgrid js $r]]
	    set r [next $r]	;# include widget -js
	    return $r
	}

	destructor {
	    # TODO destroy all child widgets

	    variable fgrid
	    catch {$fgrid destroy}
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    set args [dict merge {} $args] 
	    if {[dict exists $args -width]} {
		variable width [dict get $args -width]
		set w [list width $width]
		dict unset args -width
	    } else {
		set w {}
	    }
	    next {*}$args

	    # create a grid for this frame
	    set name [self]..grid

	    variable fgrid [WubWidgets gridC create $name {*}$w name .[my widget] -interp [my cget interp]] parent [self]
	    Debug.wubwidgets {created Frame [self] gridded by $fgrid}
	}
    }

    # toplevel widget
    oo::class create toplevelC {
	method grid {args} {
	    variable tgrid
	    Debug.wubwidgets {Toplevel [namespace tail [self]] gridding: $tgrid $args}
	    uplevel 1 [list $tgrid {*}$args]
	}

	method prod {what} {
	    my connection prod [self]	;# toplevels pass prod to connection
	}

	# render widget
	method fetch {r} {
	    variable tgrid
	    Debug.wubwidgets {[namespace tail [self]] toplevel render gridded by $tgrid}
	    set r [my connection prep $r]

	    set title [my cget? -title]
	    if {$title eq ""} {
		set title [my widget]
	    }
	    dict set r -title $title

	    set header [my cget? -header]
	    if {$header ne ""} {
		dict lappend r -headers $header
	    }

	    # cascade in style
	    set css [my cget? css]
	    if {$css ne ""} {
		set content [<style> $css]
	    } else {
		set content [<style> [uplevel 1 [list wm css .]]]
	    }

	    # cascade in stylesheet
	    set style [my cget? stylesheet]
	    if {$style ne ""} {
		set r [Html postscript $r [<stylesheet> {*}$style]]
	    } else {
		set style [uplevel 1 [list wm stylesheet .]]
		if {$style ne ""} {
		    set r [Html postscript $r [<stylesheet> {*}$style]]
		}
	    }

	    variable tgrid
	    append content \n [<form> form_[my wid] onsubmit "return false;" [uplevel 1 [list $tgrid render]]]
	    return [Http Ok $r $content x-text/html-fragment]
	}

	method changed? {} {return 1}

	method changes {r} {
	    variable tgrid
	    #Debug.wubwidgets {Toplevel sub-grid changes: '[namespace tail [self]]'}
	    set changes [lassign [uplevel 1 [list $tgrid changes $r]] r]
	    #Debug.wubwidgets {Toplevel sub-grid changed: '[namespace tail [self]]' ($changes)}
	    return [list $r {*}$changes]
	}

	method js {r} {
	    variable tgrid
	    set r [uplevel 1 [list $tgrid js $r]]
	    set r [next $r]	;# include widget -js
	    return $r
	}

	destructor {
	    # TODO destroy all child widgets

	    variable tgrid; catch {$tgrid destroy}
	    catch {my connection tl delete [self]}
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge {titlebar 1 menubar 1 toolbar 1 location 1 scrollbars 1 status 1 resizable 1} $args]

	    # create a grid for this toplevel
	    set name [self]..grid
	    variable tgrid [WubWidgets gridC create $name name .[my widget] -interp [my cget interp]] parent [self]
	    Debug.wubwidgets {created Toplevel [self] gridded by $tgrid - alerting}
	    my connection tl add [self] $args
	}
    }

    # upload widget
    oo::class create uploadC {
	# render widget
	method render {args} {
	    set id [my wid]
	    set content [my connection layout form_$id action . enctype multipart/form-data class upload_form {*}[my style $args] [subst {
		file file_$id id file_$id upload
		submit submit_$id id submit_$id class ubutton Upload
		hidden id [my widget]
		hidden _op_ upload
	    }]]
	    return $content
	}

	method js {r} {
	    set r [Html postscript $r "\$('#[my wid]').button();"]
	    set r [next $r]	;# include widget -js
	    return $r
	}

	method changed? {args} {return 0}
	method upload {args} {
	    return [my command {*}$args]
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge {} $args]
	}
    }

    # notebook widget
    oo::class create notebookC {

	method grid {cmd w args} {
	    if {$cmd eq "configure"} {
		set w [lassign [split $w .] frame]
		Debug.wubwidgets {notebook grid: '.[my widget].$frame grid $cmd [join $w .] $args'}
		return [uplevel 1 [list .[my widget].$frame grid $cmd [join $w .] {*}$args]]
	    }
	}
	
	# render widget
	method render {args} {
	    set id [my wid]
	    variable tabs
	    set body {}; set js {}; set cnt 0
	    set li {}
	    foreach tab $tabs {
		set tid ${id}_$cnt
		lappend body [uplevel 1 [list $tab render]]
		set cnf [uplevel 1 [list $tab configure]]
		lappend li [my connection <li> [my connection <a> href "#$tid" [dict cnf.text]]]
		incr cnt
	    }
	    set content [my connection <ul> [join $li \n]]
	    append content [join $body \n]
	    
	    return [my connection <div> id $id class notebook {*}[my style $args] $content]
	}

	method changed? {} {return 1}
	
	method changes {r} {
	    variable tabs
	    set changes {}
	    foreach tab $tabs {
		set changed [lassign [uplevel 1 [list $tab changes $r]] r]
		#Debug.wubwidgets {Notebook '[namespace tail [self]]' tab [string totitle [uplevel 1 [list $tab type]]] '$tab' changes: ($changed)}
		lappend changes {*}$changed
	    }
	    return [list $r {*}$changes]
	}

	# optional - add per-widget js
	method js {r} {
	    set id [my wid]
	    variable tabs
	    variable set
	    set cnt 0
	    foreach tab $tabs {
		set r [uplevel 1 [list $tab js $r]]
		if {!$set} {
		    set cnf [uplevel 1 [list $tab configure]]
		    switch -- [dict cnf.state] {
			normal {
			    set r [Html postscript $r "\$('#$id').tabs('enable',$cnt)"]
			}
			disabled {
			    set r [Html postscript $r "\$('#$id').tabs('disable',$cnt)"]
			}
		    }
		    incr cnt
		}
	    }

	    if {!$set} {
		incr set
		set r [jQ tabs $r "#[my wid]"]
		set r [next $r]	;# include widget -js
	    }
	    return $r
	}

	method add {w args} {
	    set type [uplevel 1 [list $w type]]
	    if {$type ne "frame"} {
		error "Can only add Frames to Notebooks.  $w is a $type"
	    }
	    variable tabs
	    set text [uplevel 1 [list $w cget? -text]]
	    if {$text eq ""} {
		set text "Tab[llength $tabs]"
	    }
	    uplevel 1 [list $w configure {*}[dict merge [list -state normal -text $text] $args {-div 1}]]
	    lappend tabs $w
	}

	method insert {index w args} {
	    set type [uplevel 1 [list $w type]]
	    if {$type ne "frame"} {
		error "Can only add Frames to Notebooks.  $w is a $type"
	    }
	    variable tabs
	    set text [uplevel 1 [list $w cget? -text]]
	    if {$text eq ""} {
		set text "Tab$index"
	    }
	    uplevel 1 [list $w configure {*}[dict merge [list -state normal -text $text] $args] {-div 1}]
	    set tabs [linsert $tabs $index $w]
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}$args
	    variable tabs {}
	    variable set 0
	    my connection addprep tabs .notebook
	}
    }

    oo::class create accordionC {
	method grid {cmd w args} {
	    if {$cmd eq "configure"} {
		set w [lassign [split $w .] frame]
		return [uplevel 1 [list .[my widget].$frame grid $cmd [join $w .] {*}$args]]
	    }
	}

	# render widget
	method render {args} {
	    set id [my wid]
	    variable panes
	    set body {}; set cnt 0
	    foreach pane $panes {
		set tid ${id}_$cnt
		set cnf [uplevel 1 [list $pane configure]]
		lappend body [my connection <h3> [my connection <a> href # [dict cnf.text]]]
		lappend body [uplevel 1 [list $pane render]]
		incr cnt
	    }
	    set content [join $body \n]
	    
	    return [my connection <div> id $id class accordion {*}[my style $args] $content]
	}

	method changed? {} {return 1}

	method changes {r} {
	    variable panes
	    set changes {}
	    foreach pane $panes {
		set changed [lassign [uplevel 1 [list $pane changes $r]] r]
		lappend changes {*}$changed
	    }
	    return [list $r {*}$changes]
	}

	# optional - add per-widget js
	method js {r} {
	    set id [my wid]
	    variable panes
	    set cnt 0
	    foreach pane $panes {
		set r [uplevel 1 [list $pane js $r]]
	    }

	    variable set
	    if {!$set} {
		incr set
		set r [jQ accordion $r #[my wid]]
		set r [next $r]	;# include widget -js
	    }
	    return $r
	}

	method add {args} {
	    set ws {}
	    set options {}
	    set wmode 1
	    foreach n $args {
		if {$wmode && [string match .* $n]} {
		    lappend ws $n
		} else {
		    set wmode 0
		    lappend options $n
		}
	    }

	    variable panes
	    foreach w $ws {
		set type [uplevel 1 [list $w type]]
		if {$type ne "frame"} {
		    error "Can only add Frames to Accordions.  $w is a $type"
		}

		set text [uplevel 1 [list $w cget? -text]]
		if {$text eq ""} {
		    set text "Tab[llength $panes]"
		}

		uplevel 1 [list $w configure {*}[dict merge [list -state normal -text $text] $options {-div 1}]]
		lappend panes $w
	    }
	}

	superclass ::WubWidgets::widget
	constructor {args} {
	    next {*}[dict merge {} $args]
	    variable panes {}
	    variable set 0
	    my connection addprep accordion .accordion
	}
    }

    # make shims for each kind of widget
    variable tks {button label entry text checkbutton scale frame notebook accordion html toplevel upload cookie radiobutton select combobox toolbar}

    proc add {args} {
	variable tks
	lappend tks {*}$args
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}
