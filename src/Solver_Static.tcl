
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

proc Solver_Static {CtrlNode CtrlDOF d_incr d_max  HBuilding} {

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

set NumSteps    [expr round($d_max/$d_incr)]; 

set ok          [analyze $NumSteps $d_incr];

set d_roof    	[nodeDisp $CtrlNode 1];
set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];

if  {$d_roof >= $d_max} {set ok 0; puts "*** Target Roof Drift Reached ***";}

#-----------------------------------------------------------------------------------------
#---------------------------------In Case of No Convergence-------------------------------
#-----------------------------------------------------------------------------------------

while {$d_roof < $d_max || $ok !=0 } {

    if {$ok != 0} {

    	puts "***Analysis did not converge at $RDR% drift***"
	    puts "   --> Running analysis with d_incr and relaxed criteria ..."

	    test EnergyIncr 1.0e-3 20

        set NumSteps    [expr round(($d_max-$d_roof)/($d_incr))]; 

	    set ok          [analyze $NumSteps [expr $d_incr]];

        set d_roof    	[nodeDisp $CtrlNode 1];
        set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];

	    if  {$d_roof >= $d_max} {set ok 0; break;}
        
        if {$d_roof < $d_max} {

    	    puts "***Analysis did not converge at $RDR% drift***"
	        puts "   --> Running analysis with 1/2 of d_incr and relaxed criteria ..."

		    test EnergyIncr 1.0e-2 50

            set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/2.0))]; 
    
	        set ok          [analyze $NumSteps [expr $d_incr/2.0]];
    
            set d_roof    	[nodeDisp $CtrlNode 1];
            set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
    
	        if  {$d_roof >= $d_max} {set ok 0; break;}

			if {$d_roof < $d_max} {

				puts "***Analysis did not converge at $RDR% drift***"
				puts "   --> Running analysis with 1/4 of d_incr and relaxed criteria ..."

		        test EnergyIncr 1.0e-2 50
    
				set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/4.0))]; 
	            set ok          [analyze $NumSteps [expr $d_incr/4.0]];
    
				set d_roof    	[nodeDisp $CtrlNode 1];
				set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
		
				if  {$d_roof >= $d_max} {set ok 0; break;}
    

				if {$d_roof < $d_max} {

					puts "***Analysis did not converge at $RDR% drift***"
					puts "   --> Running analysis with 1/10 of d_incr and relaxed criteria ..."

                    test  EnergyIncr 1.0e-1 50
        
					set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/10.0))]; 
					set ok          [analyze $NumSteps [expr $d_incr/10.0]];
        
					set d_roof    	[nodeDisp $CtrlNode 1];
					set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
			
					if  {$d_roof >= $d_max} {set ok 0; break;}

					if {$d_roof < $d_max} {
				
						puts "***Analysis did not converge at $RDR% drift***"
						puts "   --> Running analysis with 1/10 of d_incr, NormDispIncr, and relaxed criteria ..."

						test  NormDispIncr 1.0e-3 50
			
						set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/10.0))]; 
						set ok          [analyze $NumSteps [expr $d_incr/10.0]];
			
						set d_roof    	[nodeDisp $CtrlNode 1];
						set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
				
						if  {$d_roof >= $d_max} {set ok 0; break;}
					
						if {$d_roof < $d_max} {

							puts "***Analysis did not converge at $RDR% drift***"
							puts "   --> Running analysis with 1/10 of d_incr, NormDispIncr, KrylovNewton, and relaxed criteria ..."

							test  		NormDispIncr 1.0e-3 50
							algorithm   KrylovNewton

							set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/10.0))]; 
							set ok          [analyze $NumSteps [expr $d_incr/10.0]];
				
							set d_roof    	[nodeDisp $CtrlNode 1];
							set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
					
							if  {$d_roof >= $d_max} {set ok 0; break;}    
						
							if {$d_roof < $d_max} {
								
								puts "***Analysis did not converge at $RDR% drift***"
								puts "   --> Running analysis with 1/50 of d_incr, NormDispIncr, and KrylovNewton ..."

								test  		NormDispIncr 1.0e-2 50
								algorithm   KrylovNewton

								set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/50.0))]; 
								set ok          [analyze $NumSteps [expr $d_incr/50.0]];
					
								set d_roof    	[nodeDisp $CtrlNode 1];
								set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
						
								if  {$d_roof >= $d_max} {set ok 0; break;}  
							
							    if {$d_roof < $d_max} {
								    
								    puts "***Analysis did not converge at $RDR% drift***"
								    puts "   --> Running analysis with 1/100 of d_incr, NormDispIncr, and KrylovNewton ..."
    
								    test  		NormDispIncr 1.0e-1 100
								    algorithm   KrylovNewton
    
								    set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/100.0))]; 
								    set ok          [analyze $NumSteps [expr $d_incr/100.0]];
					    
								    set d_roof    	[nodeDisp $CtrlNode 1];
								    set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
						    
								    if  {$d_roof >= $d_max} {set ok 0; break;}  
    
								    if {$d_roof < $d_max} {
    
									    puts "***Analysis did not converge at $RDR% drift***"
									    puts "   --> Running analysis with 1/50 of d_incr, NormDispIncr, relaxed criteria, and KrylovNewton - initial ..."
									    
									    test        NormDispIncr 1.0e-1 100
									    algorithm   KrylovNewton -initial
						    
									    set NumSteps    [expr round(($d_max-$d_roof)/($d_incr/50.0))]; if {$NumSteps > 10000} {set NumSteps 10000;}
									    set ok          [analyze $NumSteps [expr $d_incr/50.0]];
								    
									    set d_roof    	[nodeDisp $CtrlNode 1];
									    set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];
							    
									    if  {$d_roof >= $d_max} {set ok 0; break;}   
    
									    if {$d_roof < $d_max} {
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

    test        EnergyIncr 1.0e-5 10
    algorithm   Newton

	set NumSteps    [expr round(($d_max-$d_roof)/($d_incr))]; 
	set ok          [analyze $NumSteps [expr $d_incr]];
        
	set d_roof    	[nodeDisp $CtrlNode 1];
	set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];

	if  {$d_roof >= $d_max} {set ok 0; break;}   

}

set d_roof    [nodeDisp $CtrlNode 1];
set RDR         [expr round(($d_roof*100/$HBuilding)*10.)/10.];

if  {$d_roof >= $d_max} {set ok 0; puts "*** Target Roof Drift Reached ***";}

}