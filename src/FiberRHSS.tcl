##################################################################################################################
# FiberRHSS.tcl
#
# SubRoutine to construct a fiber section: Rectangular HSS section  
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
# nfdz 		Number of fibers along depth that goes along local z axis
# nftz 		Number of fibers along thickness that goes along local z axis
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################

proc FiberRHSS {secID matID d t nfdy nfty nfdz nftz} {
	set dw [expr $d - 2 * $t]
	set y1 [expr -$d/2]
	set y2 [expr -$dw/2]
	set y3 [expr  $dw/2]
	set y4 [expr  $d/2]
  
	set z1 [expr -$d/2]
	set z2 [expr -$dw/2]
	set z3 [expr  $dw/2]
	set z4 [expr  $d/2]
  
	section fiberSec  $secID  -GJ 1.e10 {
   		#                     nfIJ  nfJK    yI  zI    yJ  zJ    yK  zK    yL  zL
   		patch quadr  $matID  $nftz $nfdy   $y2 $z4   $y2 $z3   $y3 $z3   $y3 $z4
   		patch quadr  $matID  $nftz $nfdy   $y2 $z2   $y2 $z1   $y3 $z1   $y3 $z2
   		patch quadr  $matID  $nfdz $nfty   $y1 $z4   $y1 $z1   $y2 $z1   $y2 $z4
   		patch quadr  $matID  $nfdz $nfty   $y3 $z4   $y3 $z1   $y4 $z1   $y4 $z4
	}
}