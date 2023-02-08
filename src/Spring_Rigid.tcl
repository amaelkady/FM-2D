##################################################################################################################
# Spring_Rigid.tcl
#                                                                                       
# SubRoutine to construct a rotational spring with a very large stiffness                                                                 
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


proc Spring_Rigid {SpringID NodeI NodeJ} {

element zeroLength $SpringID  $NodeI $NodeJ -mat 99 99 99 -dir 1 2 6 -doRayleigh 1;;


}