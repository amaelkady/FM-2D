# main.tcl - the Wub starkit startup
package require starkit
starkit::startup

# start up Wub
package require Site

if {![dict exists $argv application]} {
    # Initialize Site
    Site init ini site.ini home [pwd]	;# this is the dir from which the user ran the kit

    # Start Site Server(s)
    Site start
}
