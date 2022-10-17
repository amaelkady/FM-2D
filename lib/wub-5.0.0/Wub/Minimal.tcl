#! /usr/bin/env tclsh

# Single Threaded Minimal File Server Site
lappend auto_path [pwd]	;# path to the Site.tcl file
namespace eval Site {
    variable home [file dirname [file normalize [info script]]]
    variable docroot [file join [file dirname $home] docs]
    variable httpd [list log stderr]
}
package require Site

# Start Site Server(s)
Site start
