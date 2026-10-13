source [file join [file dirname [info script]] FM2D_RunProtocol.tcl]
source [file join [file dirname [info script]] Check_SDRlimit.tcl]
# Run each step separately so every committed state is checked for collapse.

# --- FM2D_AnalyzeDynamicChecked ---
# Run accepted transient steps with deadline, time-progress and collapse checks.
# Clip each increment to the remaining record duration and latch any detected collapse.
proc FM2D_AnalyzeDynamicChecked {nSteps stepSize endTime numStories DriftLimit MFFloorNodes EGFFloorNodes HStory TraceGFDrift} {
    global CollapseFlag
    if {$stepSize <= 0 || $nSteps < 0} {error "Invalid dynamic time step or step count."}
    set timeTol [expr max(1.0e-12,1.0e-10*abs($endTime))]
    for {set step 0} {$step < $nSteps} {incr step} {
        if {$CollapseFlag eq "YES"} {return 0}
        set before [getTime]
        set remaining [expr $endTime-$before]
        if {$remaining <= $timeTol} {return 0}
        set h [expr min($stepSize,$remaining)]
        FM2D_CheckDeadline
        set result [analyze 1 $h]
        FM2D_CheckDeadline
        if {$result != 0} {return $result}
        if {[getTime] <= $before} {
            error "Dynamic analysis reported success without advancing time."
        }
        Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift
        if {$CollapseFlag eq "YES"} {return 0}
    }
    return 0
}


# Adaptive transient solver. dt_step is the maximum physical time increment,
# already computed by the model writer as user dtstep * ground-motion dt.
proc Solver_Dynamic {dt dt_step GMtime numStories DriftLimit MFFloorNodes EGFFloorNodes HStory TraceGFDrift} {
    FM2D_BeginStage DYNAMIC
    global CollapseFlag
    if {!($dt_step > 0 && $dt_step < Inf && $GMtime > 0 && $GMtime < Inf)} {
        error "Dynamic time step and target must be finite and positive."
    }
    set CollapseFlag "NO"
    foreach name {CollapseState.txt CollapsedFrame.txt} {
        set f [open [FM2D_CollapseFile $name] w]; puts -nonewline $f 0; close $f
    }
    if {[Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift]} {
        FM2D_FinishStage COLLAPSE [getTime] $GMtime
        return 0
    }

    wipeAnalysis
    constraints Plain
    numberer RCM
    system UmfPack
    test EnergyIncr 1.0e-3 20
    algorithm KrylovNewton
    integrator Newmark 0.50 0.25
    analysis Transient

    set maxStep $dt_step
    set minStep [expr {$maxStep/1000.0}]
    set stepSize $maxStep
    set timeTol [expr {max(1.0e-12,1.0e-10*abs($GMtime))}]
    set accepted 0
    set growAfter 10
    set lastReport 0
    puts "--> Adaptive dynamic analysis: maximum step $maxStep, minimum step $minStep seconds"

    while {1} {
        FM2D_CheckDeadline
        set before [getTime]
        set remaining [expr {$GMtime-$before}]
        if {$remaining < -$timeTol} {error "Dynamic analysis time exceeded its target."}
        if {$remaining <= $timeTol} {break}
        # The last step may be smaller than minStep to land on the end time.
        set h [expr {min($stepSize,$maxStep,$remaining)}]
        set now [clock milliseconds]
        if {$now-$lastReport >= 5000} {
            puts [format "Dynamic progress: time %.6g / %.6g, increment %.6g" $before $GMtime $h]
            set lastReport $now
        }

        test EnergyIncr 1.0e-3 20
        algorithm KrylovNewton
        set ok [FM2D_AnalyzeDynamicChecked 1 $h $GMtime $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift]
        if {$ok != 0 && abs([getTime]-$before)>$timeTol} {
            error "Failed dynamic step changed committed analysis time."
        }

        if {$ok != 0 && $h > $minStep*(1.0+1.0e-12)} {
            set stepSize [expr {max($minStep,$h/2.0)}]
            set accepted 0
            set growAfter 20
            continue
        }
        if {$ok != 0} {
            # At the minimum step, try alternative equilibrium algorithms.
            # Keep the original energy tolerance; allow more iterations.
            foreach recovery {{Newton} {KrylovNewton -initial} {NewtonLineSearch -type Bisection -maxIter 20}} {
                test EnergyIncr 1.0e-3 100
                algorithm {*}$recovery
                set ok [FM2D_AnalyzeDynamicChecked 1 $h $GMtime $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift]
                if {$ok == 0} {break}
                if {abs([getTime]-$before)>$timeTol} {
                    error "Failed dynamic recovery changed committed analysis time."
                }
            }
        }
        if {$ok != 0} {
            error "Dynamic analysis incomplete after adaptive recovery: reached [getTime]; target $GMtime; minimum step $minStep; solver code $ok"
        }
        if {$CollapseFlag eq "YES"} {
            FM2D_FinishStage COLLAPSE [getTime] $GMtime
            return 0
        }
        incr accepted
        if {$accepted >= $growAfter} {
            set stepSize [expr {min($maxStep,2.0*$stepSize)}]
            set accepted 0
        }
    }
    set reached [getTime]
    if {abs($reached-$GMtime)>$timeTol} {
        error "Dynamic analysis incomplete: reached $reached; target $GMtime"
    }
    FM2D_FinishStage COMPLETED $reached $GMtime
    return 0
}
