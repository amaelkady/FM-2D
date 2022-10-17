#!/bin/sh
# -*- tcl -*- \
exec tclsh "$0" "$@"

# transform.tcl --
#
#	Transform a source document with a XSL stylesheet.
#
# Arguments:
#	source-doc	Source XML document
#	style-doc	XSL Stylesheet
#	result-doc	Result HTML document
#
# Copyright (c) 2008 Explain
# http://www.explain.com.au/
#
# $Id$

package require xml 3.2
package require xslt 3.2

set srcFname {}
set styleFname {}
set resultFname {}

foreach {srcFname styleFname resultFname} $argv break

if {$srcFname == "" || $styleFname == "" || $resultFname == ""} {
    puts stderr "Usage: $argv0 source-doc style-doc result-doc"
    exit 1
}

proc ReadXML fname {
    if {[catch {open $fname} ch]} {
	puts stderr "unable to open \"$fname\" due to \"$ch\""
	exit 2
    }
    set xml [read $ch]
    close $ch

    if {[catch {dom::parse $xml -baseuri file://[file normalize [file join [pwd] $fname]]} doc]} {
	puts stderr "unable to read XML document due to \"$doc\""
	exit 3
    }

    return $doc
}

proc Message args {
    if {[string length [string trim {*}$args]]} {
	puts {*}$args
    }
}

set srcdoc [ReadXML $srcFname]
set styledoc [ReadXML $styleFname]
if {[catch {xslt::compile $styledoc} style]} {
    puts stderr "unable to compile XSL stylesheet due to \"$style\""
    exit 4
}

$style configure -messagecommand Message

if {[catch {$style transform $srcdoc} resultdoc]} {
    puts stderr "error while performing transformation: \"$resultdoc\""
    exit 5
}

if {[catch {open $resultFname w} ch]} {
    puts stderr "unable to open file \"$resultFname\" for writing due to \"$ch\""
    exit 6
}
puts $ch [dom::serialize $resultdoc -method [$style cget -method]]
close $ch

exit 0

