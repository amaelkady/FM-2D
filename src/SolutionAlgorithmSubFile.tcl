 # SolutionAlgorithmSubFile
 # Units: kips, in, sec
 # This file developed by: Seong-Hoon Hwang of McGill University
 # Updated: 20 January 2015
 # Date: January 2015
 # Other files used in developing this model:
 # Solution algorithm - this is called repetitively by another solution algorithm file.
 # If the initial step didn't work, then alter the time step and the tolerance, and try different solution algorithms
 
set x [clock seconds];
set RunTime [expr $x - $StartTime];
set RoofDisp [nodeDisp $CtrlNode 1];
set RDR [expr round(($RoofDisp*100/$HBuilding)*10.)/10.];

# set counterItr [expr $counterItr +1];
# puts "Inr #$counterItr";
puts "RDR = $RDR %  and  RunTime = $RunTime sec"

 # I added these solution algorithm (date: 20/Jan/2015)
 if {$ok != 0 && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {
     #puts "That failed - Trying Krylov-Newton Algorithm .."
     test NormDispIncr $currentTolerance $testIterations 0
     # set controlDisp [nodeDisp $CtrlNode $CtrlDOF ]
     # set Dstep       [expr $Dmax-$controlDisp]
     # set NewRemainSteps [expr round(($Dstep)/($currentDisp))]
     algorithm KrylovNewton
     integrator DisplacementControl $CtrlNode $CtrlDOF $currentDisp
     set ok [analyze 1]
     test NormDispIncr $testTolerance $testIterations 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the tolerance output if it got in this loop and if it has gotten to a tolerance larger than it ever did previously
     if {$maxTolUsed < $currentTolerance} {
         set maxTolUsed $currentTolerance 
     }
     # Reset the current tolerance used value if it was just increased
     if {$maxTolUsedInCurrentStep < $currentTolerance} {
         set maxTolUsedInCurrentStep $currentTolerance 
     }   
 }

 if {$ok != 0 && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {
     #puts "That failed - Trying some changes to disp. and the solution algorithm"
     test NormDispIncr $currentTolerance $testIterations 0
     algorithm NewtonLineSearch 0.8;
     integrator DisplacementControl $CtrlNode $CtrlDOF $currentDisp
     set ok [analyze 1]
     test NormDispIncr $testTolerance $testIterations 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the current tolerance used value if it was just increased
     if {$maxTolUsedInCurrentStep < $currentTolerance} {
     set maxTolUsedInCurrentStep $currentTolerance 
     }
 }
 # 
 # I changed this to Line Search with Newton
 if {$ok != 0 && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {
     #puts "That failed - Trying some changes to disp. and the solution algorithm"
     test NormDispIncr $currentTolerance $testIterations 0
     algorithm NewtonLineSearch 0.6;
     integrator DisplacementControl $CtrlNode $CtrlDOF $currentDisp
     set ok [analyze 1]
     test NormDispIncr $testTolerance $testIterations 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the current tolerance used value if it was just increased
     if {$maxTolUsedInCurrentStep < $currentTolerance} {
         set maxTolUsedInCurrentStep $currentTolerance 
     }
 }
 
 # Try other algorithms
 if {$ok != 0 && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {
     #puts "That failed - Trying Newton ..."
     test NormDispIncr $currentTolerance $testIterations 0
     algorithm Newton
     integrator DisplacementControl $CtrlNode $CtrlDOF $currentDisp
     set ok [analyze 1]
     test NormDispIncr $testTolerance $testIterations 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the current tolerance used value if it was just increased
      if {$maxTolUsedInCurrentStep < $currentTolerance} {
          set maxTolUsedInCurrentStep $currentTolerance 
		 } 
 }
    
 if {$ok != 0 && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {
     #puts "That failed - Trying initial stiffness ..."
     test NormDispIncr $currentTolerance $testIterations 0
     algorithm ModifiedNewton -initial
     integrator DisplacementControl $CtrlNode $CtrlDOF $currentDisp
     set ok [analyze 1]
     test NormDispIncr $testTolerance [expr $testIterations*$ratioForInitialAlgo] 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the current tolerance used value if it was just increased
      if {$maxTolUsedInCurrentStep < $currentTolerance} {
          set maxTolUsedInCurrentStep $currentTolerance 
      }
 }
 
 # I added these solution algorithm (date: 21/Jan/2015)
 if {$ok != 0 && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {
     #puts "That failed - Run Newton 100 steps with 1/2 of step.."
     test EnergyIncr $currentTolerance $testIterations 0
     algorithm KrylovNewton
     integrator DisplacementControl $CtrlNode $CtrlDOF [expr $currentDisp/2.0]
     set ok [analyze 1]
      test NormDispIncr $testTolerance $testIterations 0
      algorithm $algorithmTypeStatic
      integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
      # Reset the current tolerance used value if it was just increased
      if {$maxTolUsedInCurrentStep < $currentTolerance} {
          set maxTolUsedInCurrentStep $currentTolerance 
      }
 }
 
 if {$ok != 0  && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {     
      #puts "Go Back to KrylovNewton with tangent Tangent and original step.."
      test EnergyIncr $currentTolerance $testIterations 0
      algorithm KrylovNewton
     integrator DisplacementControl $CtrlNode $CtrlDOF $currentDisp
      set ok [analyze 1]
      test NormDispIncr $testTolerance $testIterations 0
      algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
      # Reset the current tolerance used value if it was just increased
      if {$maxTolUsedInCurrentStep < $currentTolerance} {
          set maxTolUsedInCurrentStep $currentTolerance 
      }
 }
 
 if {$ok != 0  && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {
     #puts "Run 10 steps KrylovNewton with Initial Tangent with 1/2 of original step.."
     test EnergyIncr $currentTolerance $testIterations 0
     algorithm KrylovNewton -initial
     integrator DisplacementControl $CtrlNode $CtrlDOF [expr $currentDisp/2.0]
     set ok [analyze 1]
     test NormDispIncr $testTolerance $testIterations 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the current tolerance used value if it was just increased
     if {$maxTolUsedInCurrentStep < $currentTolerance} {
         set maxTolUsedInCurrentStep $currentTolerance 
      }
 }
 
 if {$ok != 0  && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {     	
     #puts "Go Back to KrylovNewton with tangent Tangent and original step.."
     test EnergyIncr $currentTolerance $testIterations 0
     algorithm KrylovNewton
     integrator DisplacementControl $CtrlNode $CtrlDOF  $currentDisp
     set ok [analyze 1]
     test NormDispIncr $testTolerance $testIterations 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the current tolerance used value if it was just increased
     if {$maxTolUsedInCurrentStep < $currentTolerance} {
         set maxTolUsedInCurrentStep $currentTolerance 
      }
 }
 
 if {$ok != 0  && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {
     #puts "KrylovNewton Initial with 1/2 of step and Displacement Control Convergence.."
     test EnergyIncr $currentTolerance $testIterations 0
     algorithm KrylovNewton -initial
     integrator DisplacementControl $CtrlNode $CtrlDOF  [expr $currentDisp/2.0]
     set ok [analyze 1]
     test NormDispIncr $testTolerance $testIterations 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the current tolerance used value if it was just increased
     if {$maxTolUsedInCurrentStep < $currentTolerance} {
         set maxTolUsedInCurrentStep $currentTolerance 
      }
 }
     
 if {$ok != 0  && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {     	
     #puts "Go Back to KrylovNewton with tangent Tangent and 0.0001 step.."
     test EnergyIncr 1.0e-1 50   0
     integrator DisplacementControl $CtrlNode $CtrlDOF 0.0001
     algorithm KrylovNewton
     set ok [analyze 1]
     test NormDispIncr $testTolerance $testIterations 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the current tolerance used value if it was just increased
     if {$maxTolUsedInCurrentStep < $currentTolerance} {
         set maxTolUsedInCurrentStep $currentTolerance 
      }
 }     

 if {$ok != 0  && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {     	
     #puts "Go Back to KrylovNewton with tangent Tangent and 0.0001 step.."
     test EnergyIncr 1.0e-1 50   0
     integrator DisplacementControl $CtrlNode $CtrlDOF 0.000001
     algorithm KrylovNewton
     set ok [analyze 1]
     test NormDispIncr $testTolerance $testIterations 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the current tolerance used value if it was just increased
     if {$maxTolUsedInCurrentStep < $currentTolerance} {
         set maxTolUsedInCurrentStep $currentTolerance 
      }
 }
 
 if {$ok != 0  && $RunTime < $MaxRunTime & $RoofDisp < $Dmax} {     	
     #puts "Go Back to KrylovNewton with tangent Tangent and original step.."
     test EnergyIncr 1.0e-1 50   0
     algorithm KrylovNewton
     integrator DisplacementControl $CtrlNode $CtrlDOF $currentDisp
     set ok [analyze 1]
     test NormDispIncr $testTolerance $testIterations 0
     algorithm $algorithmTypeStatic
     integrator DisplacementControl $CtrlNode $CtrlDOF $Dincr
     # Reset the current tolerance used value if it was just increased
     if {$maxTolUsedInCurrentStep < $currentTolerance} {
         set maxTolUsedInCurrentStep $currentTolerance 
      }
 }     
