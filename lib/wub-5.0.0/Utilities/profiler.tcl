package provide profiler 1.0
global TimeProfilerMode
if { [info exists TimeProfilerMode] } {
     global ProfilerArray
     array unset ProfilerArray
}

#=================================================================
# TIME PROFILER
# by [Barney Blankenship] (based on work by [George Peter Staplin])
#
# Insert this snippet above the function definitions you want
# to have profiled.
#
# TO INITIALIZE OR CLEAR/RESET THE PROFILER...
# global TimeProfilerMode
# if { [info exists TimeProfilerMode] } {
#      global ProfilerArray
#      array unset ProfilerArray
# }
#
# TO PRODUCE THE OUTPUT (currently hard-coded to "TimingDump.txt"
# file output "append" in the current working directory)...
# global TimeProfilerMode
# if { [info exists TimeProfilerMode] } {
#      TimeProfilerDump description
# }
# (description: text string shown at the top of the output)
#
# PROFILING DATA COLLECTION
# (This describes what is included in the output)
# Provides total elapsed time in milliseconds between reset and dump.
# Provides function call statistics...
# for each function defined after this snippet, provide...
#   Number of times called
#   Average milliseconds per call
#   Maximum milliseconds call time
#   Minimum milliseconds call time
#   Total milliseconds used
#   Ratio of above to total elapsed time (XX.XXX percent)
# In addition, the function call statistics are sorted
# in descending values of Ratio (above).
#
# Note that nested functions and functions that use
# recursion are provided for and timed properly.
#
# TO DISABLE PROFILING WITHOUT REMOVING THE PROFILER
# Comment out the "set TimeProfilerMode 0" below...
#=================================================================
global TimeProfilerMode
set TimeProfilerMode 0

if { [info exists TimeProfilerMode] } {
    proc TimeProfiler {args} {
 	global ProfilerArray

 	# Intialize the elapsed time counters if needed...
 	if { ![info exists ProfilerArray(ElapsedClicks)] } {
 	    set ProfilerArray(ElapsedClicks) [expr {double([clock clicks])}]
 	    set ProfilerArray(Elapsedms) [expr {double([clock clicks -milliseconds])}]
 	}

 	set fun [lindex [lindex $args 0] 0]

 	if { [lindex $args end] == "enter" } {
 	    # Initalize the count of functions if needed...
 	    if { ![info exists ProfilerArray(funcount)] } {
 		set ProfilerArray(funcount) 0
 	    }

 	    # See if this function is here for the first time...
 	    for { set fi 0 } { $fi < $ProfilerArray(funcount) } { incr fi } {
 		if { [string equal $ProfilerArray($fi) $fun] } {
 		    break
 		}
 	    }
 	    if { $fi == $ProfilerArray(funcount) } {
 		# Yes, function first time visit, add...
 		set ProfilerArray($fi) $fun
 		set ProfilerArray(funcount) [expr {$fi + 1}]
 	    }

 	    # Intialize the "EnterStack" if needed...
 	    if { ![info exists ProfilerArray(ES0)] } {
 		set esi 1
 	    } else {
 		set esi [expr {$ProfilerArray(ES0) + 1}]
 	    }
 	    # Append a "enter clicks" and "enter function name index" to the EnterStack...
 	    set ProfilerArray(ES0) $esi
 	    set ProfilerArray(ES$esi) [clock clicks]
 	    # Note: the above is last thing done so timing start is closest to
 	    # function operation start as possible.
 	} else {
 	    # Right away stop timing...
 	    set deltaclicks [clock clicks]

 	    # Do not bother if TimeProfilerDump wiped the ProfilerArray
 	    # just prior to this "leave"...
 	    if { [info exists ProfilerArray(ES0)] } {
 		# Pull an "enter clicks" off the EnterStack...
 		set esi $ProfilerArray(ES0)
 		set deltaclicks [expr {$deltaclicks - $ProfilerArray(ES$esi)}]
 		incr esi -1
 		set ProfilerArray(ES0) $esi

 		# Correct for recursion and nesting...
 		if { $esi } {
 		    # Add our elapsed clicks to the previous stacked values to compensate...
 		    for { set fix $esi } { $fix > 0 } { incr fix -1 } {
 			set ProfilerArray(ES$fix) [expr {$ProfilerArray(ES$fix) + $deltaclicks}]
 		    }
 		}

 		# Intialize the delta clicks array if needed...
 		if { ![info exists ProfilerArray($fun,0)] } {
 		    set cai 1
 		} else {
 		    set cai [expr {$ProfilerArray($fun,0) + 1}]
 		}

 		# Add another "delta clicks" reading...
 		set ProfilerArray($fun,0) $cai
 		set ProfilerArray($fun,$cai) $deltaclicks
 	    }
 	}
    }

    proc TimeProfilerDump {description} {
 	global ProfilerArray

 	# Stop timing elapsed time and calculate conversion factor for clicks to ms...
 	set EndClicks [expr {double([clock clicks]) - $ProfilerArray(ElapsedClicks)}]
 	set Endms [expr {double([clock clicks -milliseconds]) - $ProfilerArray(Elapsedms)}]
 	set msPerClick [expr {$Endms / $EndClicks}]

 	# Visit each function and generate the statistics for it...
 	for { set fi 0 ; set PerfList "" } { $fi < $ProfilerArray(funcount) } { incr fi } {
 	    set fun $ProfilerArray($fi)
 	    if { ![info exists ProfilerArray($fun,0)] } {
 		continue
 	    }
 	    for { set max -1.0 ; set min -1.0 ; set ctotal 0.0 ; set cai 1 } { $cai <= $ProfilerArray($fun,0) } { incr cai } {
 		set clicks $ProfilerArray($fun,$cai)
 		set ctotal [expr {$ctotal + double($clicks)}]
 		if { $max < 0 || $max < $clicks } {
 		    set max $clicks
 		}
 		if { $min < 0 || $clicks < $min } {
 		    set min $clicks
 		}
 	    }
 	    set cavg [expr {$ctotal / double($ProfilerArray($fun,0))}]
 	    set ProfilerArray($fun,avgms) [expr {$cavg * $msPerClick}]
 	    set ProfilerArray($fun,totalms) [expr {$ctotal * $msPerClick}]
 	    set ProfilerArray($fun,ratio) [expr {double($ctotal / $EndClicks) * 100.0}]
 	    set ProfilerArray($fun,max) [expr {$max * $msPerClick}]
 	    set ProfilerArray($fun,min) [expr {$min * $msPerClick}]

 	    # Append to the sorting list the pairs of ratio values and function indexes...
 	    lappend PerfList [list $ProfilerArray($fun,ratio) $fi]
 	}
 	# Sort the profile data by Ratio...
 	set PerfList [lsort -real -decreasing -index 0 $PerfList]

 	# Finally, generate the results...
 	set fd [open "TimingDump.txt" a]
 	puts $fd "\n===================================================================="
 	puts $fd [format "     T I M I N G  D U M P  <%s>" $description]
 	puts $fd [format "\n      Elapsed time: %.0f ms" $Endms]
 	puts $fd [format "\n      %s" [clock format [clock seconds]]]
 	puts $fd "===================================================================="
 	for { set li 0 } { $li < [llength $PerfList] } { incr li } {
 	    set fun $ProfilerArray([lindex [lindex $PerfList $li] 1])
 	    puts $fd [format ">>>>> FUNCTION: %s" $fun]
 	    puts $fd [format "       CALLS: %d" $ProfilerArray($fun,0)]
 	    puts $fd [format "    AVG TIME: %.3f ms" $ProfilerArray($fun,avgms)]
 	    puts $fd [format "    MAX TIME: %.3f ms" $ProfilerArray($fun,max)]
 	    puts $fd [format "    MIN TIME: %.3f ms" $ProfilerArray($fun,min)]
 	    puts $fd [format "  TOTAL TIME: %.3f ms" $ProfilerArray($fun,totalms)]
 	    puts $fd [format "       RATIO: %.3f%c\n" $ProfilerArray($fun,ratio) 37]
 	}
 	close $fd

 	# Reset the world...
 	array unset ProfilerArray
    }

    #=================================================================
    # Overload "proc" so that functions defined after
    # this point have added trace handlers for entry and exit.
    # [George Peter Staplin]
    #=================================================================
    rename proc _proc

    _proc proc {name arglist body} {
 				    #===================================
 				    # Allow multiple namespace use [JMN]
 				    if { ![string match ::* $name] } {
 					# Not already an 'absolute' namespace path,
 					# qualify it so that traces can find it...
 					set name [uplevel 1 namespace current]::[set name]
 				    }
 				    #===================================

 				    _proc $name $arglist $body
 				    trace add execution $name enter TimeProfiler
 				    trace add execution $name leave TimeProfiler
 				}
}