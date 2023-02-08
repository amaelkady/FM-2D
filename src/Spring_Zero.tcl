##################################################################################################################
# Spring_Zero.tcl
#                                                                                       
# SubRoutine to construct a rotational spring with a very low stiffness                                                                 
#
##################################################################################################################
#
# Input Arguments:
#------------------
#  SpringID  			Spring ID
#  NodeI				Node i ID
#  NodeJ				Node j ID
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################

proc Spring_Zero {SpringID NodeI NodeJ} {

element zeroLength $SpringID  $NodeI $NodeJ -mat 99 99 9 -dir 1 2 6;

}