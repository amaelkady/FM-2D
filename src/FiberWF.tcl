##################################################################################################################
# FiberWF.tcl
#
# SubRoutine to construct a fiber section: Wide-Flange or general I-shaped section 
# 
##################################################################################################################
#
# Input Arguments:
#------------------
# secID 	Section ID 
# matID 	Material ID  
# d  		Section depth	
# bf  		Flange width	
# tf  		Flange tickness
# tw  		Web tickness
# nfdw 		Number of fibers along depth
# nftw		Number of fibers along web thickness
# nfbf		Number of fibers along flange width
# nftf		Number of fibers along flange thickness
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################

proc FiberWF {secID matID d bf tf tw nfdw nftw nfbf nftf} {
	set dw [expr $d - 2 * $tf]
	set y1 [expr -$d/2]
	set y2 [expr -$dw/2]
	set y3 [expr  $dw/2]
	set y4 [expr  $d/2]
  
	set z1 [expr -$bf/2]
	set z2 [expr -$tw/2]
	set z3 [expr  $tw/2]
	set z4 [expr  $bf/2]

	section fiberSec  $secID -GJ 1.e10 {
   		#                     nfIJ  nfJK    yI  zI    yJ  zJ    yK  zK    yL  zL
   		patch quadr  $matID  $nfbf $nftf   $y1 $z4   $y1 $z1   $y2 $z1   $y2 $z4
   		patch quadr  $matID  $nftw $nfdw   $y2 $z3   $y2 $z2   $y3 $z2   $y3 $z3
   		patch quadr  $matID  $nfbf $nftf   $y3 $z4   $y3 $z1   $y4 $z1   $y4 $z4
	}
}
