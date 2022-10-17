package require extend

package provide file 1.0

extend file {
    proc newer {a b} {
	return [expr {[file mtime $a] > [file mtime $b]}]
    }

    proc newerthan {mtime path} {
	return [expr {[file exists $path] && ([file mtime $path] > $mtime)}]
    }

    proc up {root suffix name} {
	#puts stderr "file up $root - $suffix - $name"
	while {$suffix ni {/ . ""}} {
	    set try [file join $root $suffix $name]
	    #puts stderr "file up try $try"
	    if {[file exists $try]} {
		#puts stderr "file up try $try - YES"
		return $try
	    } else {
		set suffix [file dirname $suffix]	;# move up hierarchy
		#puts stderr "file up try $try - NO - $suffix"
	    }
	}

	#puts stderr "file up try [file join $root $name]"
	if {[file exists [file join $root $name]]} {
	    #puts stderr "file up try [file join $root $name] - YES"
	    return [file join $root $name]
	}

	#puts stderr "file up try [file join $root $name] - NO - giving up"
	return ""
    }

    proc upm {root suffix name} {
	memoize
	return [up $root $suffix $name]
    }

    proc read {path} {
	set fd [::open $path]
	set content [::read $fd]
	::close $fd
	return $content
    }

    proc write {path data} {
	set dn [file dirname $path]
	::file mkdir $dn
	set fd [::open $path w]
	::puts -nonewline $fd $data
	::close $fd
    }
}
