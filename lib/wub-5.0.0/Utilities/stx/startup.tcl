# startup.tcl
# This is a startup file useful for tclhttpd's custom facility
# it provides a post-processing converter from STX to HTML

# when the containing directory is placed under /usr/lib/tclhttpd/custom/
# this file signals to tclhttpd that the whole directory is a customisation

# load up the actual code package
lappend auto_path [file dirname [info script]]
package require stx2html

# Inform tclhttpd of the STX file format

Mtype_Add stx application/x-structured-text

# Doc_application/x-structured-text --
#
# use stx to format up and return an html document
#
# Arguments:
#	path	The file pathname.
#	suffix	The URL suffix.
#	sock	The socket connection.
#
# Results:
#	None
#
# Side Effects:
#	Sets up the interpreter context and runs doctools over the page
#	if necessary, to generate a cached version which is returned to the client.

proc Doc_application/x-structured-text {path suffix sock} {
    upvar 1 data data

    set fd [open $path r]
    set text [read $fd]
    close $fd

    set result {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
	<html>
	<head>
	<title></title>
	<link rel="stylesheet" type="text/css" href="stx.css" media="screen" title="screen">
	</head>
	<body>}
    append result [stx2html::translate $text]
    append result {
	</body>
	</html>
    }

    Httpd_ReturnData $sock text/html $result
}
