 # run different analyses to find convergence for displacement-driven analysis
 # Set the variaous levels to try for the test tolerance
 set testTolerance     1.0e-6;
 set testMinTolerance1 1.0e-5;    
 set testMinTolerance2 1.0e-4;    
 set testMinTolerance3 1.0e-3;    
 set testMinTolerance4 1.0e-2;    
 set testMinTolerance5 1.0e-1;    
 # Set initialize the maximum tolerance used - for output to know about convergence
 set maxTolUsed $testTolerance;
 # Set the iterations to use for the different types of solution algorithms	
 set testIterations 50;          # This is used, but for -initial, then the ratio for initial is used.
 set ratioForInitialAlgo	200;    # This is the ratio of testIterations that is allowed for -initial test 
 set testInitialIterations 1000;
 set testLowIter 10;              # Used to try each test in the loop
 set testHighIter 1000;          # Used to try to make it converge at the very end

if {$RunTime > $MaxRunTime} {
	set ok 1;
}

 # Analysis loop
 while {$controlDisp < $Dmax && $ok == 0} {
    # Do step with initial tolerance and input algorithm
    set ok [analyze $Nsteps]; # this will return zero if no convergence problems were encountered
    # Keep track of the maximum tolarance used in this step  - for the convPlotFile.  This is later increased it necessary.
    set maxTolUsedInCurrentStep     [expr $testTolerance]
    # Change things for convergence
    # If it's not ok, try to decrease dT, but keep the toelrance the same call another file for this (just to keep this file clean).
    #	The basic approach I am taking here is to try everything to make it converge.  This way the analyst can look at the final 
    # convergence tolerance and be sure that this is acceptable.
    set currentTolerance [expr $testTolerance]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/10];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, try to decrease dT a bit more, but keep the toerance the samecall another file for this (just to keep this file clean)
    set currentTolerance [expr $testTolerance]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/20];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, try to decrease dT a bit more, but keep the toerance the samecall another file for this (just to keep this file clean)
    set currentTolerance [expr $testTolerance]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/40];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, try to decrease dT a bit more, but keep the toerance the samecall another file for this (just to keep this file clean)
    set currentTolerance [expr $testTolerance]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/80];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, try to decrease dT a bit more, but keep the toerance the samecall another file for this (just to keep this file clean)
    set currentTolerance [expr $testTolerance]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/100];
    source SolutionAlgorithmSubFile.tcl
    
    # If it's not ok, go to a more relaxed tolerance1...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance1]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/10]; # This was /10, so maybe change back?
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance1...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance1]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/20];  # This was /20, so maybe change back?
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance1...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance1]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/40];    # This was /20, so maybe change back?
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance1...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance1]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/80];    # This was /20, so maybe change back?
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance1...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance1]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/100];    # This was /20, so maybe change back?
    source SolutionAlgorithmSubFile.tcl
    
    # If it's not ok, go to a more relaxed tolerance2...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance2]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/10];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance2...call another file for this (just to keep this file clean)
    # Decrease dT more
    set currentTolerance [expr $testMinTolerance2]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/20];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance2...call another file for this (just to keep this file clean)
    # Increase the number of iterations
    set currentTolerance [expr $testMinTolerance2]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/40];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance2...call another file for this (just to keep this file clean)
    set currentTolerance  [expr $testMinTolerance2]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/80];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance2...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance2]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/100];
    source SolutionAlgorithmSubFile.tcl
    
    # If it's not ok, go to a more relaxed tolerance3...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance3]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/10];
    source SolutionAlgorithmSubFile.tcl
    
    # If it's not ok, go to a more relaxed tolerance3...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance3]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/20];
    source SolutionAlgorithmSubFile.tcl
            
    # If it's not ok, go to a more relaxed tolerance3...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance3]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/40];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance3...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance3]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/80];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance3...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance3]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/100];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance4...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance4]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/10];
    source SolutionAlgorithmSubFile.tcl
    
    # If it's not ok, go to a more relaxed tolerance4...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance4]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/20];
    source SolutionAlgorithmSubFile.tcl
        
    # If it's not ok, go to a more relaxed tolerance4...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance4]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/40];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance4...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance4]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/80];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance4...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance4]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/100];
    source SolutionAlgorithmSubFile.tcl
        
    # If it's not ok, go to a more relaxed tolerance5...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance5]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/10];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance5...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance5]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/20];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance5...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance5]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/40];
    source SolutionAlgorithmSubFile.tcl
            
    # If it's not ok, go to a more relaxed tolerance5...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance5]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/80];
    source SolutionAlgorithmSubFile.tcl

    # If it's not ok, go to a more relaxed tolerance5...call another file for this (just to keep this file clean)
    set currentTolerance [expr $testMinTolerance5]
    set currentNumIterations [expr $testLowIter]
    set currentDisp [expr $Dincr/100];
    source SolutionAlgorithmSubFile.tcl
    
    set currentTime [getTime]
 }