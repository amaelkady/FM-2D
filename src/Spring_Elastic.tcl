##################################################################################################################
# Spring_Elastic.tcl
#                                                                                       
# SubRoutine to construct a rotational spring with an elastic response                                                             
#
##################################################################################################################
#
# Input Arguments:
#------------------
# SpringID  		Spring ID
# NodeI				Node i ID
# NodeJ				Node j ID
# E         		Young's modulus
# Ix        		Moment of inertia of section
# L         		Member Length
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################


proc Spring_Elastic {SpringID Node_i Node_j E Ix L} {

set n 10.0;
set K  [expr ($n+1.0) * 6 * $E * $Ix / $L];

uniaxialMaterial Elastic $SpringID $K
element zeroLength $SpringID $NodeI $NodeJ  -mat 99 99 $SpringID -dir 1 2 6;


}