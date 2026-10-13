# Check_SDRlimit ########################################################################
#
# Procedure that reads the story drifts, checks if the pre-specified collapse drift limit 
# is reached, set a flag if it does, and writes the collapse state to a txt file
#
#
# Written by: Ahmed Elkady
#
# #######################################################################################

# Each launched process gets its own collapse metadata directory.
# Exported Tcl runs also use an isolated folder rather than shared CWD files.

# --- FM2D_CollapseFile ---
# Resolve a collapse metadata filename in this invocation's isolated folder.
# The MATLAB driver supplies the folder; standalone Tcl allocates a unique fallback.
proc FM2D_CollapseFile {name} {
    global FM2D_CollapseDir
    if {![info exists FM2D_CollapseDir]} {
        set FM2D_CollapseDir [file join [pwd] RunLogs "collapse_[pid]_[clock clicks]"]
    }
    file mkdir $FM2D_CollapseDir
    return [file join $FM2D_CollapseDir $name]
}

# A collapse flag is reset once by Solver_Dynamic, and latched here.
proc Check_SDRlimit {numStories SDRlimit MFFloorNodes EGFFloorNodes HStory TraceGFDrift} {
    global CollapseFlag
    if {![info exists CollapseFlag]} {set CollapseFlag "NO"}
    if {$CollapseFlag eq "YES"} {return 1}
    if {$numStories < 1 || $SDRlimit <= 0 ||
        [llength $HStory] < $numStories ||
        [llength $MFFloorNodes] < $numStories ||
        ($TraceGFDrift && [llength $EGFFloorNodes] < $numStories)} {
        error "Invalid story count, drift limit, or floor/height lists."
    }

    set collapseMF 0
    set collapseEGF 0
    set belowMF 0.0
    set belowEGF 0.0
    for {set i 0} {$i < $numStories} {incr i} {
        set height [lindex $HStory $i]
        if {$height <= 0} {error "Story heights must be positive."}
        set aboveMF [nodeDisp [lindex $MFFloorNodes $i] 1]
        set driftMF [expr abs(($aboveMF-$belowMF)/$height)]
        if {$driftMF >= $SDRlimit} {set collapseMF 1}
        set belowMF $aboveMF

        if {$TraceGFDrift} {
            set aboveEGF [nodeDisp [lindex $EGFFloorNodes $i] 1]
            set driftEGF [expr abs(($aboveEGF-$belowEGF)/$height)]
            if {$driftEGF >= $SDRlimit} {set collapseEGF 1}
            set belowEGF $aboveEGF
        }
    }

    if {!$collapseMF && !$collapseEGF} {return 0}
    set CollapseFlag "YES"
    set f [open [FM2D_CollapseFile CollapseState.txt] w]
    puts -nonewline $f 1
    close $f
    # Bit mask: 1=MF, 2=EGF, 3=both. Preserve all collapsing stories/frames.
    set f [open [FM2D_CollapseFile CollapsedFrame.txt] w]
    puts -nonewline $f [expr $collapseMF+2*$collapseEGF]
    close $f
    return 1
}
