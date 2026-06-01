##################################################################################################################
# Spring_Splice.tcl
#                                                                                       
# SubRoutine to construct a rotational spring with a rigid-perfectly-plastic material (moment splice springs)                                                                
#
##################################################################################################################
#
# Input Arguments:
#------------------
#  SpringID  			Spring ID
#  MatID  			    Material ID
#  NodeI				Node i ID
#  NodeJ				Node j ID
#  Mp				    Plastic moment
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################


proc Spring_Splice {SpringID MatID NodeI NodeJ Mp} {

uniaxialMaterial Steel01 $MatID $Mp 1.e10 0.0;

element zeroLength $SpringID  $NodeI $NodeJ -mat 99 99 $MatID -dir 1 2 6 -doRayleigh 1;


}