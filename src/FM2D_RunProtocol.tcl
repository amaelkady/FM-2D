# Loaded by the per-run driver before the generated model.

# --- FM2D_WriteStatus ---
# Write the six-line run identity, state, stage, progress and message file.
# Standalone models without a driver skip status-file output.
proc FM2D_WriteStatus {state stage reached target message} {
    global FM2D_RunId FM2D_StatusFile
    # Standalone exported Tcl can run without the MATLAB driver.
    if {![info exists FM2D_RunId] || ![info exists FM2D_StatusFile]} {return}
    set message [string map [list "\n" " " "\r" " "] $message]
    set f [open $FM2D_StatusFile w]
    puts $f $FM2D_RunId
    puts $f $state
    puts $f $stage
    puts $f $reached
    puts $f $target
    puts $f $message
    close $f
}

# --- FM2D_BeginStage ---
# Start a stage, clear any previous outcome and check its runtime deadline.
proc FM2D_BeginStage {stage} {
    global FM2D_Stage FM2D_Outcome
    set FM2D_Stage $stage
    unset -nocomplain FM2D_Outcome
    FM2D_WriteStatus STARTED $stage 0 0 "Analysis in progress"
    FM2D_CheckDeadline
}

# --- FM2D_FinishStage ---
# Record a validated terminal outcome; RunModel publishes it after model cleanup.
proc FM2D_FinishStage {state reached target} {
    global FM2D_Stage FM2D_Outcome
    FM2D_CheckDeadline
    set FM2D_Outcome [list $state $FM2D_Stage $reached $target]
}

# --- FM2D_RunModel ---
# Run the model under Tcl error handling and publish its final outcome.
# Return a process exit code: zero for a validated outcome, one for errors or timeout.
proc FM2D_RunModel {modelFile} {
    global FM2D_Stage FM2D_Outcome
    set FM2D_Stage MODEL
    unset -nocomplain FM2D_Outcome
    FM2D_WriteStatus STARTED MODEL 0 0 "Analysis in progress"
    if {[catch {uplevel #0 [list source $modelFile]; FM2D_CheckDeadline} message options]} {
        set state FAILED
        if {[dict exists $options -errorcode] && [dict get $options -errorcode] eq "FM2D TIMEOUT"} {set state TIMEOUT}
        FM2D_WriteStatus $state $FM2D_Stage 0 0 $message
        puts stderr $message
        return 1
    }
    if {![info exists FM2D_Outcome]} {
        FM2D_WriteStatus FAILED $FM2D_Stage 0 0 "Model ended without a validated analysis outcome"
        return 1
    }
    lassign $FM2D_Outcome state stage reached target
    set message "Analysis terminated with a validated outcome"
    if {$state eq "NONCONVERGED"} {
        set message "Static analysis stopped after convergence recovery was exhausted; results available through $reached; target $target was not reached"
    }
    FM2D_WriteStatus $state $stage $reached $target $message
    return 0
}


# --- FM2D_CheckDeadline ---
# Enforce the driver deadline, or derive one from standalone MaxRunTime in seconds.
# An infinite deadline disables the limit; timeout uses a distinct Tcl error code.
proc FM2D_CheckDeadline {} {
    global FM2D_DeadlineMs MaxRunTime
    if {![info exists FM2D_DeadlineMs]} {
        if {![info exists MaxRunTime] || $MaxRunTime<=0} {return}
        set FM2D_DeadlineMs [expr {[clock milliseconds]+1000.0*$MaxRunTime}]
    }
    if {[clock milliseconds] >= $FM2D_DeadlineMs} {
        return -code error -errorcode {FM2D TIMEOUT} "Analysis runtime limit exceeded"
    }
}

# --- FM2D_AnalyzeStaticChecked ---
# Analyze one static step at a time, checking deadlines before and after each.
# Return the first nonzero solver code instead of continuing an unsuccessful batch.
proc FM2D_AnalyzeStaticChecked {nSteps} {
    for {set step 0} {$step<$nSteps} {incr step} {
        FM2D_CheckDeadline
        set result [analyze 1]
        FM2D_CheckDeadline
        if {$result !=0} {return $result}
    }
    return 0
}
