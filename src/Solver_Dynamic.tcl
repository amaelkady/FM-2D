
# Solver_Dynamic ########################################################################
#
# This subroutine initiate dynamic (transient) analysis and modifies solver parameters 
# and equilibrium criteria -if needed- to try and reach convergence
#
# INPUT:
# --------
# dt            : Ground Motion step
# dt_step       : Analysis time step
# GMtime        : Ground Motion Total Time
# numStories    : Number of stories
# DriftLimit    : Drift limit for collapse
# MFFloorNodes  : Node IDs for the main frame
# EGFFloorNodes : Node IDs for the equivenlant gravity frame
# HStory        : The story heights
# TraceGFDrift  : Flag for tracing the EGF drift (in case of flexible links))
# 
# Subroutines called:
#   Check_SDRlimit: Checks if collapse is reached based on story drifts
#
# Written by: Prof. Ahmed Elkady, University of Southampton, UK
#
# #######################################################################################

proc Solver_Dynamic {dt dt_step GMtime numStories DriftLimit MFFloorNodes EGFFloorNodes HStory TraceGFDrift} {

global CollapseFlag;                        # global variable to monitor collapse
source Check_SDRlimit.tcl;

wipeAnalysis

# #######################################################################################
# #######################################################################################
# #######################################################################################

# Set initial parameter values
#-------------------------------
set CollapseFlag        "NO"
set CurrentClockTime    [clock seconds];
set TmaxAnalysis        $GMtime;
set dt_analysis         $dt_step;
set currentTime         0;
set remainTime          $GMtime;
 
# Initial solver parameters
#----------------------------
constraints Plain
numberer    RCM
system      UmfPack
test        EnergyIncr 1.0e-3 20
algorithm   KrylovNewton
integrator  Newmark 0.50 0.25
analysis    Transient

#-----------------------------------------------------------------------------------------
#---------------------------------------Run Analysis--------------------------------------
#-----------------------------------------------------------------------------------------

puts "--> Running analysis with default solver parameters and original t_step ..."

set NumSteps    [expr round($GMtime/$dt_analysis)]; 

set ok          [analyze $NumSteps $dt_analysis];

Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift

if  {$CollapseFlag == "YES"} {set ok 0; puts "*** Collapse Occured ***";}

set currentTime     [getTime];

#-----------------------------------------------------------------------------------------
#---------------------------------In Case of No Convergence-------------------------------
#-----------------------------------------------------------------------------------------

while {$ok !=0} {

    if {$ok != 0} {

    	puts "***Analysis did not converge at $currentTime seconds***"
	    puts "   --> Running analysis with KrylovNewton: 10 steps with 1/2 of t_step ..."

	    test EnergyIncr 1.0e-3 20

		set TimeTarget     [expr $currentTime+10*$dt_analysis/2.0];
	    set ok             [analyze 10 [expr $dt_analysis/2.0]];

	    Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift

	    if  {$CollapseFlag == "YES"} {set ok 0; break;}

		set currentTime     [getTime];
        
        if {$currentTime < $TimeTarget} {

	        puts "***Analysis did not converge at $currentTime seconds***"
		    puts "   --> Running analysis with KrylovNewton: 10 steps with 1/2 of t_step and relaxed criteria ..."

		    test EnergyIncr 1.0e-2 50

    		set TimeTarget      [expr $currentTime+10*$dt_analysis/2.0];
	        set ok              [analyze 10 [expr $dt_analysis/2.0]];

		    Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift

	        if  {$CollapseFlag == "YES"} {set ok 0; break;}

		    set currentTime     [getTime];

            if {$currentTime < $TimeTarget} {

	            puts "***Analysis did not converge at $currentTime seconds***"
		        puts "   --> Running analysis with KrylovNewton: 10 steps with 1/4 of t_step and relaxed criteria ..."

		        test EnergyIncr 1.0e-2 50
    
    		    set TimeTarget      [expr $currentTime+10*$dt_analysis/4.0];
	            set ok              [analyze 10 [expr $dt_analysis/4.0]];
    
		        Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift
    
	            if  {$CollapseFlag == "YES"} {set ok 0; break;}
    
		        set currentTime     [getTime];

                if {$currentTime < $TimeTarget} {

                    puts "***Analysis did not converge at $currentTime seconds***"
                    puts "   --> Running analysis with KrylovNewton: 10 steps with 1/10 of t_step and relaxed criteria ..."

                    test  EnergyIncr 1.0e-1 50
        
                    set TimeTarget      [expr $currentTime+10*$dt_analysis/10.0];
                    set ok              [analyze 10 [expr $dt_analysis/10.0]];
        
                    Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift
        
	                if  {$CollapseFlag == "YES"} {set ok 0; break;}

    		        set currentTime     [getTime];

                    if {$currentTime < $TimeTarget} {

                        puts "***Analysis did not converge at $currentTime seconds***"
                        puts "   --> Running analysis with KrylovNewton: 10 steps with 1/100 of t_step and relaxed criteria ..."

                        test  EnergyIncr 1.0e-1 100
            
                        set TimeTarget      [expr $currentTime+10*$dt_analysis/100.0];
                        set ok              [analyze 10 [expr $dt_analysis/100.0]];
            
                        Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift
            
	                    if  {$CollapseFlag == "YES"} {set ok 0; break;}

    		            set currentTime     [getTime];
    
                        if {$currentTime < $TimeTarget} {
    
                            puts "***Analysis did not converge at $currentTime seconds***"
			                puts "   --> Running analysis with Newton: Fixed number of iteratios and t_step = 0.0001 sec ..."
                                    
			                test        FixedNumIter 50
			                integrator  NewmarkHSFixedNumIter 0.5 0.25
			                algorithm   Newton
                
                            set TimeTarget      [expr $currentTime+10*0.0001];
			                set ok              [analyze 10 0.0001]

                            Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift
                
	                        if  {$CollapseFlag == "YES"} {set ok 0; break;}
    
    		                set currentTime     [getTime];
        
                            if {$currentTime < $TimeTarget} {

                                puts "***Analysis did not converge at $currentTime seconds***"
			                    puts "   --> Running analysis with KrylovNewton Initial: 1/2 t_step and displacement control convergence ..."
			                    
                                test        EnergyIncr 1.0e-1 50
                    			integrator  Newmark 0.50 0.25
			                    algorithm   KrylovNewton -initial
                    
                                set TimeTarget      [expr $currentTime+10*$dt_analysis/2.0];
			                    set ok              [analyze 10 [expr $dt_analysis/2.0]]
                            
                                Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift
                
	                            if  {$CollapseFlag == "YES"} {set ok 0; break;}
        
    		                    set currentTime     [getTime];

                                if {$currentTime < $TimeTarget} {
    			                    puts "..................................................................................."
    			                    puts "***All convergence attempts exhausted: Stopping analysis at $currentTime seconds***"
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

	puts "***Analysis converged at $currentTime seconds***"
	puts "   --> Running remaining analysis with default solver parameters and original t_step ..."

    test        EnergyIncr 1.0e-3 20
    algorithm   KrylovNewton
    integrator  Newmark 0.50 0.25

	set remainTime      [expr $GMtime - $currentTime]
	set nStepsRemaining [expr round($remainTime/$dt_analysis)]

    set TimeTarget      [expr $currentTime+$nStepsRemaining*$dt_analysis];
    set ok              [analyze $nStepsRemaining  $dt_analysis]
        
	Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift

	if  {$CollapseFlag == "YES"} {set ok 0; break;}
    
    set currentTime     [getTime];
    
    if  {abs($TmaxAnalysis-$currentTime) < $dt_analysis/2}  {set ok 0; break;}

}

Check_SDRlimit $numStories $DriftLimit $MFFloorNodes $EGFFloorNodes $HStory $TraceGFDrift

if  {$CollapseFlag == "YES"} {set ok 0}

}