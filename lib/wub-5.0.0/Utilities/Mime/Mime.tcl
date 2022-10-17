# Mime - calculate the mime types of file
package require WubUtils
package require Debug
Debug define mime 10

package require mime-magic
package provide Mime 1.0

set ::API(Utilities/Mime) {
    {
	Mime analysis - like unix [[file]] command

	Identifies file types by inspection, maps .ext to mime type
    }
}

namespace eval ::Mime {
    variable file_attributes 1	;# should we seek file attributes to tell us?
    variable home [file dirname [info script]]
    variable e2m {}

    variable default text/plain	;# default mime type
    variable prime mime.types	;# file to prime map

    # simple minded file extension<->mime-type map

    # add --
    #
    # 	add a MIME type mapping
    #
    # Arguments:
    #	suffix	A file suffix
    #	type	The corresponding MIME Content-Type.
    #
    # Results:
    #       None

    proc add {ext type} {
	variable e2m
	set ext [string tolower [string trimleft $ext .]]
	dict set e2m .$ext $type
	dict lappend e2m $type .$ext
    }

    proc read {file} {
	package require fileutil
	variable e2m

	::fileutil::foreachLine line $file {
	    set line [string trim $line]
	    if {($line eq "") || [string match \#* $line]} {
		continue
	    }
	    regsub {[\t ]+} $line " " line
	    set line [split $line]
	    if {[llength $line] == 1} {
		# record a known type with no extension
		dict set e2m [lindex $line 0] {}
	    } else {
		if {[string match {*/*} [lindex $line 0]]} {
		    foreach ext [lrange $line 1 end] {
			add $ext [lindex $line 0]
		    }
		} else {
		    add [lindex $line 0] [lindex $line 1]
		}
	    }
	}
    }

    # determine type by file extension
    proc MimeOf {ext {def ""}} {
	# try to prime the e2m array
	variable prime
	variable home
	if {$prime ne ""} {
	    if {[file pathtype $prime] eq "relative"} {
		set prime [file join $home $prime]
	    }
	    catch {
		read $prime
	    }
	}

	# set the default mimetype
	variable e2m; variable default
	dict set e2m "" $default

	proc MimeOf [list ext [list default $default]] {
	    variable e2m
	    
	    set ext ".[string trim [string tolower $ext] .]"
	    if {[dict exist $e2m $ext]} {
		return [dict get $e2m $ext]	;# mime type of extension
	    } else {
		return $default	;# default mime type
	    }
	}
	
	return [MimeOf $ext $def]
    }

    # init the thing
    proc init {args} {
	Debug.mime {Mime init $args}
	foreach {n v} $args {
	    variable $n $v
	}
	proc init {args} {}	;# can only be initialized once.
    }

    # call mime magic on a given string or {path $file}
    proc magic {args} {
	if {[llength $args]%2} {
	    # this is a string
	    Debug.mime {typeOf text}
	    magic::value [lindex $args end]
	    set args [lrange $args 0 end-1]
	} else {
	    # this is a file
	    Debug.mime {typeOf file}
	    magic::open [dict get $args path]
	}

	if {[catch {
	    ::magic::/magic.mime
	} result eo]} {
	    Debug.mime {magic error: $result ($eo)}
	    set result ""
	}

	if {$result eq ""
	    && [dict exists $args path]
	} {
	    return [MimeOf [file extension [dict get $args path]]]
	}

	Debug.mime {magic result: $result}
	return [lindex [split $result] 0]
    }

    variable cache; array set cache {}
    # this tries to store mime info in the file's attributes
    proc type {file} {
	Debug.mime {MIME type $file}

	# filesystem may know file's mime type
	variable file_attributes
	if {$file_attributes
	    && ![catch {file attributes $file -mime} type]
	    && $type != ""} {
	    # filesystem maintains -mime type attribute
	    return $type
	}

	# some special file types have special mime types
	set ft [string tolower [file type $file]]
	switch -- $ft {
	    directory {
		return "multipart/x-directory"
	    }
	    
	    characterspecial -
	    blockspecial -
	    fifo -
	    socket {
		return "application/x-$ft"
	    }
	}

	variable cache
	if {[info exists cache($file)]} {
	    return $cache($file)
	}

	# possibly do mime magic
	Debug.mime {MIME magic}
	if {![catch {
	    ::magic::open $file
	    set result [::magic::/magic.mime]
	    Debug.mime {MIME magic: $result}
	} r eo]} {
	    if {$file_attributes} {
		# record the finding for posterity
		catch {file attributes $file -mime $result}
	    }
	    Debug.mime {MIME cache: $result}
	    if {$result ne ""} {
		set cache($file) $result
		return $result
	    }
	} else {
	    Debug.mime {MAGIC error: $r ($eo)}
	}
	
	# fallback to using file extension
	set result [MimeOf [file extension $file]]
	set cache($file) $result
	
	Debug.mime {MIME ext: $result}
	return $result
    }

    namespace import 
    namespace export -clear *
    namespace ensemble create -subcommands {}
}
