source [file join [file dirname [info script]] FM2D_RunProtocol.tcl]

# Solver_Static ########################################################################
#
# This subroutine initiate static disp-based analysis and modifies solver parameters 
# and equilibrium criteria -if needed- to try and reach convergence
#
# INPUT:
# --------
# CtrlNode      : Control node
# CtrlDOF       : Degree of freedom for disp-control analysis
# d_incr        : Displacement increment
# d_max   	 	: Maximum (target) roof displacement 
# HBuilding    	: Building height
# 
#
# Written by: Prof. Ahmed Elkady, University of Southampton, UK
#
# #######################################################################################

# Continue the final rescue algorithm to the target, not an arbitrary batch cap.

# --- FM2D_AnalyzeStaticToTargetChecked ---
# Fixed-increment recovery helper retained for compatibility.
# Bound the last step by remaining displacement and reject successful steps with no progress.
proc FM2D_AnalyzeStaticToTargetChecked {CtrlNode CtrlDOF stepSize target} {
    if {$stepSize <= 0} {error "Static rescue increment must be positive."}
    set tol [expr {max(1.0e-10,1.0e-8*abs($target))}]
    integrator DisplacementControl $CtrlNode $CtrlDOF $stepSize
    while {1} {
        FM2D_CheckDeadline
        set before [nodeDisp $CtrlNode $CtrlDOF]
        set remaining [expr {$target-$before}]
        if {$remaining <= $tol} {return 0}
        if {$remaining < $stepSize} {
            integrator DisplacementControl $CtrlNode $CtrlDOF $remaining
        }
        set result [FM2D_AnalyzeStaticChecked 1]
        if {$result != 0} {return $result}
        if {[nodeDisp $CtrlNode $CtrlDOF] <= $before} {
            error "Static rescue analysis reported success but control displacement did not advance."
        }
    }
}

# Grow accepted steps conservatively; shrink a failed grown step before
# returning failure at this retry stage's original minimum increment.

# --- FM2D_AnalyzeStaticAdaptive ---
# Advance toward the displacement target with bounded adaptive increments.
# Shrink failed grown steps; grow only after sustained success; stop at the retry floor.
proc FM2D_AnalyzeStaticAdaptive {CtrlNode CtrlDOF minStep maxStep target} {
    if {$minStep <= 0 || $maxStep < $minStep} {error "Invalid adaptive static increments."}
    set tol [expr {max(1.0e-10,1.0e-8*abs($target))}]
    set stepSize $minStep
    set appliedStep -1
    set accepted 0
    set growAfter 10
    while {1} {
        FM2D_CheckDeadline
        set before [nodeDisp $CtrlNode $CtrlDOF]
        set remaining [expr {$target-$before}]
        if {$remaining <= $tol} {return 0}
        set h [expr {min($stepSize,$remaining)}]
        if {$h != $appliedStep} {
            integrator DisplacementControl $CtrlNode $CtrlDOF $h
            set appliedStep $h
        }
        FM2D_ReportStaticProgress $before $target $h
        set result [FM2D_AnalyzeStaticChecked 1]
        if {$result != 0} {
            if {$h > $minStep*(1.0+1.0e-12)} {
                set stepSize [expr {max($minStep,$h/2.0)}]
                set accepted 0
                set growAfter 20
                continue
            }
            return $result
        }
        if {[nodeDisp $CtrlNode $CtrlDOF] <= $before} {
            error "Static analysis reported success but control displacement did not advance."
        }
        incr accepted
        if {$accepted >= $growAfter} {
            set stepSize [expr {min($maxStep,2.0*$stepSize)}]
            set accepted 0
        }
    }
}


# --- FM2D_ReportStaticProgress ---
# Throttle console progress reports to one every five seconds.
proc FM2D_ReportStaticProgress {reached target stepSize} {
    global FM2D_StaticLastReport
    set now [clock milliseconds]
    if {![info exists FM2D_StaticLastReport] || $now-$FM2D_StaticLastReport >= 5000} {
        puts [format "Pushover progress: roof %.6g / %.6g, increment %.6g" $reached $target $stepSize]
        set FM2D_StaticLastReport $now
    }
}

proc Solver_Static {CtrlNode CtrlDOF d_incr d_max  HBuilding} {

FM2D_BeginStage STATIC
set recoveryExhausted 0
    unset -nocomplain ::FM2D_StaticLastReport
global RoofDisp ok;                        # global variable to monitor roof disp

wipeAnalysis

# #######################################################################################
# #######################################################################################
# #######################################################################################

# Set initial parameter values
#-------------------------------

set d_roof    	0;
set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];

# Initial solver parameters
#----------------------------
constraints Plain
numberer    RCM 
system      UmfPack
test        EnergyIncr 1.e-5 10;
algorithm   Newton;
integrator  DisplacementControl $CtrlNode $CtrlDOF $d_incr
analysis    Static

#-----------------------------------------------------------------------------------------
#---------------------------------------Run Analysis--------------------------------------
#-----------------------------------------------------------------------------------------

puts "--> Running analysis with default solver parameters and original d_incr ..."

set NumSteps [expr int(floor($d_max/$d_incr))]; 

set ok 0
if {$NumSteps > 0} {set ok [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF $d_incr $d_incr $d_max]}

set d_roof    	[nodeDisp $CtrlNode 1];
set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];

if  {$d_roof >= $d_max} {set ok 0; puts "*** Target Roof Drift Reached ***";}

#-----------------------------------------------------------------------------------------
#---------------------------------In Case of No Convergence-------------------------------
#-----------------------------------------------------------------------------------------

while {$d_roof < $d_max || $ok !=0 } {
    FM2D_CheckDeadline

    if {$ok != 0} {

    	puts "***Analysis did not converge at $RDR% drift***"
	    puts "   --> Running analysis with d_incr and relaxed criteria ..."

	    test EnergyIncr 1.0e-3 20

        set NumSteps    [expr round(($d_max-$d_roof)/($d_incr))]; 

	    set ok          [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF $d_incr $d_incr $d_max];

        set d_roof    	[nodeDisp $CtrlNode 1];
        set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];

	    if  {$d_roof >= $d_max} {set ok 0; break;}
        
        if {$d_roof < $d_max} {

    	    puts "***Analysis did not converge at $RDR% drift***"
	        puts "   --> Running analysis with 1/2 of d_incr and relaxed criteria ..."

		    test EnergyIncr 1.0e-2 50

            set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/2.0))]; 
            
            integrator  DisplacementControl $CtrlNode $CtrlDOF [expr $d_incr/2.0];

	        set ok          [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF [expr {$d_incr/2.0}] $d_incr $d_max];
    
            set d_roof    	[nodeDisp $CtrlNode 1];
            set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
    
	        if  {$d_roof >= $d_max} {set ok 0; break;}

			if {$d_roof < $d_max} {

				puts "***Analysis did not converge at $RDR% drift***"
				puts "   --> Running analysis with 1/4 of d_incr and relaxed criteria ..."

		        test EnergyIncr 1.0e-2 50
    
				set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/4.0))]; 

                integrator  DisplacementControl $CtrlNode $CtrlDOF [expr $d_incr/4.0];

	            set ok          [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF [expr {$d_incr/4.0}] $d_incr $d_max];
    
				set d_roof    	[nodeDisp $CtrlNode 1];
				set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
		
				if  {$d_roof >= $d_max} {set ok 0; break;}
    

				if {$d_roof < $d_max} {

					puts "***Analysis did not converge at $RDR% drift***"
					puts "   --> Running analysis with 1/10 of d_incr and relaxed criteria ..."

                    test  EnergyIncr 1.0e-1 50
        
					set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/10.0))]; 

                    integrator  DisplacementControl $CtrlNode $CtrlDOF [expr $d_incr/10.0];

					set ok          [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF [expr {$d_incr/10.0}] $d_incr $d_max];
        
					set d_roof    	[nodeDisp $CtrlNode 1];
					set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
			
					if  {$d_roof >= $d_max} {set ok 0; break;}

					if {$d_roof < $d_max} {
				
						puts "***Analysis did not converge at $RDR% drift***"
						puts "   --> Running analysis with 1/10 of d_incr, NormDispIncr, and relaxed criteria ..."

						test  NormDispIncr 1.0e-3 50
			
						set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/10.0))]; 
    
                        integrator  DisplacementControl $CtrlNode $CtrlDOF [expr $d_incr/10.0];

						set ok          [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF [expr {$d_incr/10.0}] $d_incr $d_max];
			
						set d_roof    	[nodeDisp $CtrlNode 1];
						set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
				
						if  {$d_roof >= $d_max} {set ok 0; break;}
					
						if {$d_roof < $d_max} {

							puts "***Analysis did not converge at $RDR% drift***"
							puts "   --> Running analysis with 1/10 of d_incr, NormDispIncr, KrylovNewton, and relaxed criteria ..."

							test  		NormDispIncr 1.0e-3 50
							algorithm   KrylovNewton

							set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/10.0))]; 

                            integrator  DisplacementControl $CtrlNode $CtrlDOF [expr $d_incr/10.0];

							set ok          [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF [expr {$d_incr/10.0}] $d_incr $d_max];
				
							set d_roof    	[nodeDisp $CtrlNode 1];
							set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
					
							if  {$d_roof >= $d_max} {set ok 0; break;}    
						
							if {$d_roof < $d_max} {
								
								puts "***Analysis did not converge at $RDR% drift***"
								puts "   --> Running analysis with 1/50 of d_incr, NormDispIncr, and KrylovNewton ..."

								test  		NormDispIncr 1.0e-2 50
								algorithm   KrylovNewton

								set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/50.0))]; 

                                integrator  DisplacementControl $CtrlNode $CtrlDOF [expr $d_incr/50.0];

								set ok          [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF [expr {$d_incr/50.0}] $d_incr $d_max];
					
								set d_roof    	[nodeDisp $CtrlNode 1];
								set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
						
								if  {$d_roof >= $d_max} {set ok 0; break;}  
							
							    if {$d_roof < $d_max} {
								    
								    puts "***Analysis did not converge at $RDR% drift***"
								    puts "   --> Running analysis with 1/100 of d_incr, NormDispIncr, and KrylovNewton ..."
    
								    test  		NormDispIncr 1.0e-1 100
								    algorithm   KrylovNewton
    
								    set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/100.0))]; 

                                    integrator  DisplacementControl $CtrlNode $CtrlDOF [expr $d_incr/100.0];
    
								    set ok          [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF [expr {$d_incr/100.0}] $d_incr $d_max];
					    
								    set d_roof    	[nodeDisp $CtrlNode 1];
								    set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
						    
								    if  {$d_roof >= $d_max} {set ok 0; break;}  
    
								    if {$d_roof < $d_max} {
    
									    puts "***Analysis did not converge at $RDR% drift***"
									    puts "   --> Running analysis with 1/50 of d_incr, NormDispIncr, relaxed criteria, and KrylovNewton - initial ..."
									    
									    test        NormDispIncr 1.0e-1 100
									    algorithm   KrylovNewton -initial
						    
									    # Start below the preceding failed 1/100-increment attempt.
                                    set rescueMin [expr {$d_incr/1000.0}]
                                    puts "   --> Final recovery: KrylovNewton -initial, minimum increment $rescueMin"
                                    set ok [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF $rescueMin $d_incr $d_max]
                                    set remaining [expr {$d_max-[nodeDisp $CtrlNode $CtrlDOF]}]
                                    set rescueTol [expr {max(1.0e-10,1.0e-8*abs($d_max))}]
                                    if {$ok != 0 && $remaining > $rescueTol} {
                                        puts "   --> Additional recovery: NewtonLineSearch, minimum increment $rescueMin"
                                        test NormDispIncr 1.0e-1 100
                                        algorithm NewtonLineSearch -type Bisection -maxIter 20
                                        set ok [FM2D_AnalyzeStaticAdaptive $CtrlNode $CtrlDOF $rescueMin $d_incr $d_max]
                                    }

set d_roof    	[nodeDisp $CtrlNode 1];
									    set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
							    
									    if  {$d_roof >= $d_max} {set ok 0; break;}   
    
									    if {$ok != 0 && $d_roof < $d_max} {
                                        set recoveryExhausted 1
										    puts "..................................................................................."
										    puts "***    All convergence attempts exhausted: Stopping analysis at $RDR% drift     ***"
										    puts "..................................................................................."
										    break;
									    }
								    }
                                }
							}

						}  
					}
                }            
            }
        }

	}

	puts "***Analysis converged at $RDR% drift***"
	puts "   --> Running remaining analysis with default solver parameters and original d_incr ..."

# Replace the default-resumption block from `test EnergyIncr ...`
# through its final target-displacement check inside the while loop.
test EnergyIncr 1.0e-5 10
algorithm Newton

set dispTol [expr max(1.0e-10, 1.0e-8*abs($d_max))]
set remaining [expr $d_max-$d_roof]
if {$remaining <= $dispTol} {
    set ok 0
    break
}

# One accepted step, bounded by the remaining distance to the target.
set stepDisp [expr min($d_incr,$remaining)]
set previousDisp $d_roof
integrator DisplacementControl $CtrlNode $CtrlDOF $stepDisp
set ok [FM2D_AnalyzeStaticChecked 1]
set d_roof [nodeDisp $CtrlNode $CtrlDOF]
set RDR [expr round(($d_roof*100/$HBuilding)*10.)/10.]

if {$d_roof >= $d_max-$dispTol} {
    set ok 0
    break
}
if {$ok == 0 && $d_roof <= $previousDisp+$dispTol} {
    error "Static analysis reported success but control displacement did not advance."
}
# If ok != 0, the next iteration enters the existing convergence-retry block.
   

}

set d_roof    [nodeDisp $CtrlNode 1];
set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];

if  {$d_roof >= $d_max} {set ok 0; puts "*** Target Roof Drift Reached ***";}

set reached [nodeDisp $CtrlNode $CtrlDOF]
set dispTol [expr max(1.0e-10,1.0e-8*abs($d_max))]
if {$ok != 0 || $reached < $d_max-$dispTol} {
    if {$recoveryExhausted && $ok < 0 && $reached > 0 && $reached < $d_max-$dispTol} {
        puts "*** Pushover stopped due to nonconvergence; results available through $reached mm ($RDR% drift). Target was $d_max mm. ***"
        FM2D_FinishStage NONCONVERGED $reached $d_max
        return
    }
    error "Static analysis incomplete: reached $reached; target $d_max; solver code $ok"
}
FM2D_FinishStage COMPLETED $reached $d_max

}
