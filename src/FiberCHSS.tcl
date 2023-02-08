##################################################################################################################
# FiberCHSS.tcl
#
# SubRoutine to construct a fiber section: Circular HSS section  
# 
##################################################################################################################
#
# Input Arguments:
#------------------
# secID 	Section ID 
# matID 	Material ID  
# d  		Section depth	
# t  		Tube tickness
# nfdy 		Number of fibers along depth that goes along local y axis 
# nfty 		Number of fibers along thickness that goes along local y axis
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################

proc FiberCHSS {secID matID d t nfdy nfty} {
set intRad   [expr $d/2-$t]
set extRad   [expr $d/2]

section fiberSec   $secID -GJ 1.e10 {
   		#                     numSubdivCirc  numSubdivRad   yCenter  zCenter    intRad  extRad
   		patch circ   $matID  $nfdy $nfty     0.0      0.0   $extRad  $intRad     360.0     0.0
	}
}