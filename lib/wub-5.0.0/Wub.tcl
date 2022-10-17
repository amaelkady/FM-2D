#! /usr/bin/env tclsh
package require Site
package provide Wub 5.0

Site init home [file normalize [file dirname [info script]]] config site.config debug 10 {*}$argv

Site start	;# start server(s)

# vim: ts=8:sw=4:noet
