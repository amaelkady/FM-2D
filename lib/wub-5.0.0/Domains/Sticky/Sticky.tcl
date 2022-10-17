# Sticky - add jQuery StickyNotes to any page.
package require OO
package require Query
package require Url
package require Debug
Debug define sticky 10

package provide Sticky 1.0

set ::API(Domains/Sticky) {
    {
	A domain which adds a sticky note to any page using jQ
    }
}

class create ::Sticky {
    # add a loader to the page
    method loader {r args} {
	if {!$running} {
	    return $r
	}
	set p [dict merge $params $args]

	dict with p {
	    if {[info exists hotzone]} {
		set HZ $hotzone; unset hotzone
	    }

	    if {[info exists key]} {
		# these are the keys we want to load
		# default uses referer
		set K $key; unset key
	    }
	}
	set pp {}
	dict for {n v} $p {
	    lappend pp $n '$v'
	}
	if {[info exists HZ]} {
	    # we want to allow creation of new sticky notes
	    Debug.sticky {hotzone $HZ $p}
	    set r [jQ stickynote $r $HZ {*}$pp]
	} else {
	    error "Must specify a hotzone"
	}

	if {[info exists K]} {
	    # load up the jQ libs
	    foreach k $K {
		Debug.sticky {loader for $k}
		set url "[file join $mount load]?key=%k"
		set r [jQ postscript $r [string map [list %LOAD% $url] {
		    $.getScript('%LOAD%', function(data, status) {
			/*alert("data:"+data+" status:"+status);*/
		    });
		}]]
	    }
	} else {
	    # just load the defaults
	    Debug.sticky {loader for default}
	    set url [file join $mount load]
	    set r [jQ postscript $r [string map [list %LOAD% $url] {
		$.getScript('%LOAD%', function(data, status){
		    /*alert("data:"+data+" status:"+status);*/
		});
	    }]]
	}

	return $r
    }

    method /save {r {content ""} args} {
	Debug.sticky {/save $args}
	if {![dict exists $args key]} {
	    set referer [Url parse [dict get $r referer] 1]
	    set key [dict get $referer -path]
	}
	set id [::tcl::clock::microseconds]
	$db allrows "INSERT INTO $table (id, key, content) VALUES (:id, :key, :content);"
    }

    method /delete {r {id ""} args} {
	Debug.sticky {/delete id:$id $args}
	if {[string match ST* $id]} {
	    set id [string trimleft $id ST]
	    $db allrows "DELETE FROM $table where id = :id;"
	}
    }

    method /load {r {key ""} {content ""}} {
	# if no key, use referer
	if {$key eq ""} {
	    set referer [Url parse [dict get? $r referer] 1]
	    set key [dict get? $referer -path]
	}

	Debug.sticky {/load $key}

	# combine all our parameters
	set p ""
	foreach {n v} $params {
	    append p $n:'$v', \n
	}

	# create template with parameters pre-substituted
	set template [string map [list %PARAMS% $p %SAVE% [file join $mount save]] {
	    $.fn.stickyNotes.createNote({
		id: 'ST%ID%',
		text: '%TEXT%',
		%PARAMS%
	    });
	}]

	# find stuff matching key, substitute content into template
	set results {}
	$db foreach -as dicts -- record "SELECT * FROM $table WHERE key LIKE :key" {
	    set map [list %ID% [dict get $record id] %TEXT% [string map {\n \\n} [dict get $record content]]]
	    lappend results [string map $map $template]
	}

	# return the whole mess as javascript
	return [Http Ok $r [join $results \n] text/javascript]
    }

    method / {r} {
	return [Http $r NotFound]
    }

    method db_load {} {
	# load the tdbc drivers
	if {[catch {
	    package require $tdbc
	    package require tdbc::$tdbc
	}]} {
	    # we can't load the nominated driver
	    set running 0
	    return
	} else {
	    set running 1
	}
	
	if {$db eq ""} {
	    # create a local db
	    set local 1
	    if {$file eq ""} {
		error "Sql must specify an open db or a file argument"
	    }
	    set db [self]_db
	    tdbc::${tdbc}::connection create $db $file
	    if {![llength [$db tables sticky]]} {
		# we don't have a stick table - make one
		$db allrows [string map [list %TABLE% $table] {
		    CREATE TABLE %TABLE% (
					 id INT NOT NULL,
					 key TEXT NOT NULL,
					 content TEXT NOT NULL
					 );
		}]
	    }

	    if {0} {
		# prepare some sql statements
		foreach {name sql} {
		    with_key {SELECT * FROM @table@ WHERE key LIKE :key%}
		} {
		    set stmt($name) [$db prepare [string map [list @table@ $table] $sql]]
		}
	    }
	} else {
	    # use a supplied db
	    set local 0
	}

	Debug.sticky {Database $db: tables:([$db tables])}
    }
    variable mount postprocess params db tdbc file table stmt running

    mixin Direct	;# use Direct to map urls to /methods
    constructor {args} {
	set params {size large}
	set tdbc sqlite3	;# TDBC backend
	set db ""		;# already open file
	set file ""		;# db file
	set table sticky	;# sticky table
	set args [dict merge [Site var? File] $args]	;# allow .ini file to modify defaults
	dict for {n v} $args {
	    if {$n in {size text containment event color ontop}} {
		dict set params $n v
	    } elseif {$n in {stmt}} {
	    } else {
		set $n $v
	    }
	}
	my db_load
    }
}
