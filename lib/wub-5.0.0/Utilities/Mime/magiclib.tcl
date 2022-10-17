# usage:

# 1) magic::open - opens file and primes buffer or magic::value - sets buffer
# 2) run the appropriate generated magic over it, viz magic::/magic.mime
# 3) the result call in the generated magic will return the result of scanning
#     to the caller.
# 4) magic::close to release the stuff.

# TODO:

# Required Functionality:

# implement full offset language
# implement pstring (pascal string, blerk)
# implement regex form (blerk!)
# implement string qualifiers

# Optimisations:

# reorder tests according to expected or observed frequency
# this conflicts with reduction in strength optimisations.

# Rewriting within a  level will require pulling apart the
# list of tests at that level and reordering them.
# There is an inconsistency between handling at 0-level and
# deeper level - this has to be removed or justified.

# Hypothetically, every test at the same level should be
# mutually exclusive, but this is not given, and should be
# detected.  If true, this allows reduction in strength to switch
# on Numeric tests

# reduce Numeric tests at the same level to switches
#
# - first pass through clauses at same level to categorise as
#   variant values over same test (type and offset).

# work out some way to cache String comparisons

# Reduce seek/reads for String comparisons at same level:
#
# - first pass through clauses at same level to determine string ranges.
#
# - String tests at same level over overlapping ranges can be
#   written as sub-string comparisons over the maximum range
#   this saves re-reading the same string from file.
#
# - common prefix strings will have to be guarded against, by
#   sorting string values, then sorting the tests in reverse length order.
package require Tcl 8.6
package provide magiclib 1.0

namespace eval ::magic {
    variable debug 0
    variable optimise 1

    # buffer the value given
    proc value {text} {
	variable strbuf [string range $text 0 4096]
	variable result ""
	variable string ""
	variable numeric -9999
    }

    # open the file to be scanned and read in a buffer
    proc open {path} {
	# fill the string cache from file
	# the vast majority of magic strings are in the first 4k of the file.
	set fd [::open $path]
	fconfigure $fd -translation binary -encoding binary
	variable strbuf [::read $fd 4096]
	::close $fd

	variable result ""
	variable string ""
	variable numeric -9999
    }

    # mark the start of a magic file in debugging
    proc file_start {name} {
	variable debug
	if {$debug} {
	    puts stderr "File: $name"
	}
    }

    # return the emitted result
    proc result {{msg ""}} {
	variable result
	if {$msg != ""} {
	    emit $msg
	}
	return -code return $result
    }

    # emit a message
    proc emit {msg} {
	variable string
	variable numeric
	set msg [::string map [list \\b "" %s $string %ld $numeric %d $numeric] $msg]

	variable result
	append result " " $msg
	set result [string trim $result " "]
    }

    # handle complex offsets - TODO
    proc offset {where} {
	variable debug
	if {$debug} {
	    puts stderr "OFFSET: $where"
	}
	return 0
    }

    # fetch and cache a value from the file
    proc fetch {where what scan} {
	variable numeric
	variable strbuf
	set str [string range $strbuf $where $what]
	binary scan $str $scan numeric
	return $numeric
    }

    # maps magic typenames to field characteristics: size, binary scan format
    variable typemap
    array set typemap {
	byte {1 c}
	ubyte {1 c}
	short {2 S}
	ushort {2 S}
	beshort {2 S}
	leshort {2 s}
	ubeshort {2 S}
	uleshort {2 s}
	long {4 I}
	belong {4 I}
	lelong {4 i}
	ubelong {4 I}
	ulelong {4 i}
	date {2 S}
	bedate {2 S}
	ledate {2 s}
	ldate {4 I}
	beldate {4 I}
	leldate {4 i}
    }

    # generate short form names
    foreach {n v} [array get magic::typemap] {
	foreach {len scan} $v {
	    #puts stderr "Adding $scan - [list $len $scan]"
	    set typemap($scan) [list $len $scan]
	    break
	}
    }

    proc Nv {type offset {qual ""}} {
	variable typemap
	variable numeric

	# unpack the type characteristics
	lassign $typemap($type) size scan

	# fetch the numeric field
	set numeric [fetch $offset $size $scan]

	if {$qual != ""} {
	    # there's a mask to be applied
	    set numeric [expr $numeric $qual]
	}

	variable debug
	if {$debug} {
	    puts stderr "NV $type $offset $qual: $numeric"
	}

	return $numeric
    }

    # Numeric - get bytes of $type at $offset and $compare to $val
    # qual might be a mask
    proc N {type offset comp val {qual ""}} {
	variable typemap
	variable numeric

	# unpack the type characteristics
	lassign $typemap($type) size scan
	
	# fetch the numeric field
	set numeric [fetch $offset $size $scan]

	if {$comp == "x"} {
	    # anything matches - don't care
	    return 1
	}

	# get value in binary form, then back to numeric
	# this avoids problems with sign, as both values are
	# [binary scan]-converted identically
	binary scan [binary format $scan $val] $scan val

	if {$qual != ""} {
	    # there's a mask to be applied
	    set numeric [expr $numeric $qual]
	}

	set c [expr $val $comp $numeric]	;# perform comparison

	variable debug
	if {$debug} {
	    puts stderr "numeric $type: $val $comp $numeric / $qual - $c"
	}

	return $c
    }

    proc getString {offset len} {
	# cache the first 1k of the file
	variable string
	set end [expr {$offset + $len - 1}]
	if {$end < 4096} {
	    # in the string cache
	    variable strbuf
	    set string [string range $strbuf $offset $end]
	    return $string
	} else {
	    Debug.mime {outside buffer range $offset,$len}
	    return ""
	}
    }

    proc S {offset comp val {qual ""}} {
	variable fd
	variable string
	variable strbuf

	# convert any backslashes
	set val [subst -nocommands -novariables $val]

	if {$comp eq "x"} {
	    # match anything - don't care, just get the value
	    set string ""
	    
	    incr offset -1
	    while {([::string length $string] < 100)
		   && [::string is print [set c [string index $strbuf $offset 1]]]} {
		if {[string is space $c]} {
		    break
		}
		append string $c
	    }
	    
	    return 1
	}

	# get the string and compare it
	set string [getString $offset [::string length $val]]
	set cmp [::string compare $val $string]
	set c  [expr $cmp $comp 0]

	variable debug
	if {$debug} {
	    puts stderr "String '$val' $comp '$string' - $c"
	    if {$c} {
		puts stderr "offset $offset - $string"
	    }
	}
	
	return $c
    }
}
