
# DynamicAnalysisCollapseSolver #########################################################
#
# This Solver is used for Collapse "hunting"
# Time Controlled Algorithm that keeps original run
#
# Developed by Dimitrios G. Lignos, Ph.D
#
# First Created: 04/20/2010
# Last Modified: 08/23/2011
#
# Uses:
# 1. dt            : Ground Motion step
# 2. dt_anal_Step  : Analysis time step
# 3. GMtime        : Ground Motion Total Time
# 4. numStories    : DriftLimit
# 
# Subroutines called:
# MaxDriftTester: Checks after loss of convergence the drifts 
#                 and garantees convergence for collapse
#
# Integrator Used: Modified Implicit: Hilbert Hughes Taylor with Increment Reduction
# #######################################################################################


proc DynamicAnalysisCollapseSolver {dt dt_anal_Step GMtime numStories DriftLimit FloorNodes h1 htyp} {

global CollapseFlag;                                        # global variable to monitor collapse
source MaxDriftTester.tcl;                                  # For Collapse Studies
set CollapseFlag "NO"
wipeAnalysis
constraints Transformation
numberer RCM
system UmfPack
test EnergyIncr 1.0e-3 100
algorithm KrylovNewton
integrator Newmark 0.50 0.25
analysis Transient
set dt_analysis $dt_anal_Step;    			                # timestep of analysis
set NumSteps [expr round(($GMtime + 0.0)/$dt_analysis)];	# number of steps in analysis
set ok [analyze $NumSteps $dt_analysis];
# Check Max Drifts for Collapse by Monitoring the CollapseFlag Variable
MaxDriftTester $numStories $DriftLimit $FloorNodes $h1 $htyp

if  {$CollapseFlag == "YES"} {
	set ok 0
}

 if {$ok != 0} {
	puts "Analysis did not converge..."
	set TmaxAnalysis $GMtime;
	# The analysis will be time-controlled and is done for the remaining time
	set ok 0;
	set controlTime [getTime];
	
	while {$controlTime < $TmaxAnalysis || $ok !=0 } {
		MaxDriftTester $numStories $DriftLimit $FloorNodes $h1 $htyp
		if  {$CollapseFlag == "YES"} {
			set ok 0; break;
		} else {
			set ok 1
		}		
	    # Get Control Time inside the loop
		set controlTime [getTime]
		
		if {$ok != 0} {
			puts "Run Newton 100 steps with 1/2 of step.."
			test EnergyIncr 1.0e-3 20   0
			set controlTime [getTime]
			set remainTime [expr $TmaxAnalysis - $controlTime]
			set NewRemainSteps [expr round(($remainTime)/($dt_analysis/2.0))]
			#puts $NewRemainSteps
		    #puts $remainTime
			algorithm KrylovNewton
			integrator Newmark 0.50 0.25
			set ok [analyze 10 [expr $dt_analysis/2.0]]
			MaxDriftTester $numStories $DriftLimit $FloorNodes $h1 $htyp
			if  {$CollapseFlag == "YES"} {
				set ok 0
			}
		}
		if {$ok != 0 } {		
			puts "Go Back to KrylovNewton with tangent Tangent and original step.."
			test EnergyIncr 1.0e-2 50   0
			set controlTime [getTime]
			set remainTime [expr $TmaxAnalysis - $controlTime]
			set NewRemainSteps [expr round(($remainTime)/($dt_analysis))]
			
			algorithm KrylovNewton
			integrator Newmark 0.50 0.25
			set ok [analyze $NewRemainSteps [expr $dt_analysis]]
			MaxDriftTester $numStories $DriftLimit $FloorNodes  $h1 $htyp
			if  {$CollapseFlag == "YES"} {
				set ok 0
			}
		}
		if {$ok != 0 } {
			puts "Run 10 steps KrylovNewton with Initial Tangent with 1/2 of original step.."
			test EnergyIncr 1.0e-1 20 0			
			set controlTime [getTime]
			set remainTime [expr $TmaxAnalysis - $controlTime]
			set NewRemainSteps [expr round(($remainTime)/($dt_analysis/2.0))]
			algorithm KrylovNewton -initial
			set ok [analyze 10 [expr $dt_analysis/2.0]]
			MaxDriftTester $numStories $DriftLimit $FloorNodes  $h1 $htyp
			if  {$CollapseFlag == "YES"} {
				set ok 0
			}
		}
		if {$ok != 0 } {			
			puts "Go Back to KrylovNewton with tangent Tangent and original step.."
			test EnergyIncr 1.0e-1 50   0
			set controlTime [getTime]
			set remainTime [expr $TmaxAnalysis - $controlTime]
			set NewRemainSteps [expr round(($remainTime)/($dt_analysis))]
			algorithm KrylovNewton
			integrator Newmark 0.50 0.25
			set ok [analyze $NewRemainSteps [expr $dt_analysis]]
			MaxDriftTester $numStories $DriftLimit $FloorNodes  $h1 $htyp
			if  {$CollapseFlag == "YES"} {
				set ok 0
			}
		}				

		if {$ok != 0 } {			
			puts "Go Back to KrylovNewton with tangent Tangent and 0.001 step.."
			test EnergyIncr 1.0e-1 20   0
			set controlTime [getTime]
			set remainTime [expr $TmaxAnalysis - $controlTime]
			set NewRemainSteps [expr round(($remainTime)/(0.001))]
			algorithm KrylovNewton
			integrator Newmark 0.50 0.25
			set ok [analyze $NewRemainSteps [expr 0.001]]
			MaxDriftTester $numStories $DriftLimit $FloorNodes  $h1 $htyp
			if  {$CollapseFlag == "YES"} {
				set ok 0
			}
		}				
		if {$ok != 0 } {
			puts "KrylovNewton Initial with 1/2 of step and Displacement Control Convergence.."
			test EnergyIncr 1.0e-1 50  0
			algorithm KrylovNewton -initial
			set ok [analyze 10 [expr $dt_analysis/2.0]]
			MaxDriftTester $numStories $DriftLimit $FloorNodes  $h1 $htyp
			if  {$CollapseFlag == "YES"} {
				set ok 0
			}
		}
		if {$ok != 0 } {			
			puts "Go Back to KrylovNewton with tangent Tangent and 0.0001 step.."
			test EnergyIncr 1.0e-1 50   0
			set controlTime [getTime]
			set remainTime [expr $TmaxAnalysis - $controlTime]
			set NewRemainSteps [expr round(($remainTime)/(0.0001))]
			algorithm KrylovNewton
			integrator Newmark 0.50 0.25
			set ok [analyze 5 [expr 0.0001]]
			MaxDriftTester $numStories $DriftLimit $FloorNodes  $h1 $htyp
			if  {$CollapseFlag == "YES"} {
				set ok 0
			}
		}		

		if {$ok != 0 } {			
			puts "Go Back to KrylovNewton with tangent Tangent and original step.."
			test EnergyIncr 1.0e-1 50   0
			set controlTime [getTime]
			set remainTime [expr $TmaxAnalysis - $controlTime]
			set NewRemainSteps [expr round(($remainTime)/($dt_analysis))]
			algorithm KrylovNewton
			integrator Newmark 0.50 0.25
			set ok [analyze $NewRemainSteps [expr $dt_analysis]]
			MaxDriftTester $numStories $DriftLimit $FloorNodes $h1 $htyp
			if  {$CollapseFlag == "YES"} {
				set ok 0
			}
		}		
		if {$ok != 0 } {
			puts "Newton with Fixed Number of Iteratios else continue"
			set controlTime [getTime]
			set remainTime [expr $TmaxAnalysis - $controlTime]
			set NewRemainSteps [expr round(($remainTime)/(0.0001))]
			puts $NewRemainSteps
			test FixedNumIter 50
			integrator NewmarkHSFixedNumIter 0.5 0.25

			algorithm Newton

			set ok [analyze 10 [expr 0.0001]]
			MaxDriftTester $numStories $DriftLimit $FloorNodes $h1 $htyp
			if  {$CollapseFlag == "YES"} {
				set ok 0
			}			
		}
		
		set controlTime [getTime]		
	}
 }
}