
	# -*- tcl -*-
	# Copyright (C) 2006-2007 ActiveState Software Inc.
	# ### ### ### ######### ######### #########

	# @@ Meta Begin
	# Package ::activestate::teapot::link 1.2
	# Meta platform    tcl
	# Meta summary     Linking Tcl shells with local transparent Teapot repositories
	# Meta description Teapot support functionality.
	# Meta description Standard package to register a set of local transparent teapot
	# Meta description repositories with a Tcl shell. The information used by this
	# Meta description package is stored in teapot.txt under 'info library' and
	# Meta description accessible by teacup and other tools.
	# Meta category    Teapot shell linkage
	# Meta subject     teapot shell link
	# Meta require     platform
	# Meta require     {Tcl -require 8.4}
	# @@ Meta End

	# ### ### ### ######### ######### #########
	## Requisites

	package require platform
	namespace eval ::activestate::teapot::link {}

	# ### ### ### ######### ######### #########
	## Implementation

	proc ::activestate::teapot::link::setup {} {
	    # The database "teapot.txt" is a text file, containing one
	    # repository path per line. It is allowed to be absent, if no
	    # repositories are linked to the shell at all.

	    set rl [file join [info library] teapot-link.txt]
	    set fb 0

	    # Fall back to old link data file if the modern one is not present.
	    if {![file exists $rl]} {
		set rl [file join [info library] teapot.txt]
		set fb 1
	    }

	    # Not a failure, quick exit if there are no linked repositories.
	    if {![file exists  $rl]} return

	    # Try to move the shell from old to modern link file. Its ok to
	    # fail, just inconvenient.
	    if {$fb} {
		catch {
		    file copy $rl [file join [info library] teapot-link.txt]
		}
	    }

	    # Want to fail hard on these, indicators of major corruption.
	    #if {![file isfile   $rl]} return
	    #if {![file readable $rl]} return

	    # We trim to remove the trailing newlines which would otherwise
	    # translate into empty list elements = empty repodir paths.
	    set repositories  [split [string trim [read [set chan [open $rl r]]][close $chan] \n] \n]

	    usel $repositories
	}

	proc ::activestate::teapot::link::use {args} {usel $args}
	proc ::activestate::teapot::link::usel {repositories} {

	    # Make all repository subdirectories available which can contain
	    # packages for the architecture currently executing this Tcl
	    # script. This code assumes a directory structure as created by
	    # 'repository::localma', for all specified directories.

	    foreach arch [platform::patterns [platform::identify]] {
		foreach repodir $repositories {
		    set base [file join $repodir package $arch]
		    # Optimize a bit, missing directories are left out
		    # of searches.
		    if {![file exists $base]} continue

		    # The lib subdirectory on the other hand contains regular
		    # packages and can be used by all Tcl shells. There is no
		    # need to catch this.

		    lappend ::auto_path [file join $base lib]

		    # The teapot subdirectory contains Tcl Modules. This is
		    # relevant only to a tcl shell which is able to handle
		    # such. Like ActiveTcl. We catch our action, just in case
		    # a shell is used which is not able to handle Tcl Modules.

		    catch {::tcl::tm::roots [list [file join $base teapot]]}
		}
	    }

	    # Disabled, counterproductive. platform is installed as a TM, be
	    # it in AT, or by injected by 'teacup setup'. And this package is
	    # a TM as well. Which means that regular Pkg Mgmt has nothing
	    # loaded which has to be forgotten or reloaded. Poking it will
	    # cause a crawl which is not needed and just takes time.
	    #catch {package require __teapot__}
	    set ::errorInfo {}
	    return
	}

	# ### ### ### ######### ######### #########
	## Ready

	package provide activestate::teapot::link 1.1
