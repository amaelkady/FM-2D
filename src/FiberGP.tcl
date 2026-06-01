############################################################################################
# FiberGP.tcl
#
# This routine creates a fiber section and aggregates torsion to it: plate section 
# 
############################################################################################
#
# Input Arguments:
#------------------
# secID = section ID number
# matID = material ID number
# matTorsion = torsion material ID number 
# E     = Young's modulus
# d  	= nominal depth	
# t		= gusset plate tickness
# nfd 	= number of fibers along depth  
# nft 	= number of fibers along thickness 
#
# Original code by: Vesna Terzic
#
############################################################################################


proc FiberGP {secID matID matTorsion E d t nfd nft} {

	set y1 [expr -$d/2]
	set y2 [expr  $d/2]
  
	set z1 [expr -$t/2]
	set z2 [expr  $t/2]

	
	set secTag [expr $secID + 1000]
  
	section fiberSec  $secTag  {
   		#                     nfIJ  nfJK    yI  zI    yJ  zJ    yK  zK    yL  zL
   		patch quadr  $matID   $nft  $nfd   $y1 $z2   $y1 $z1   $y2 $z1   $y2 $z2
	}
	
	# assign torsional Stiffness (for 3D Model)
	set mu 0.3; 	# Poisson ratio for steel
	set G 	[expr $E/2.0/(1+$mu)]; # shear modulus
	set a [expr $d/2.];
	set b [expr $t/2.];
	set J	[expr $b**3*$a*((16./3.)-3.36*$b/$a*(1-($b**4)/(12.*$a**4)))]; 		# torsional constant   
	set GJ 	[expr $G*$J];  			# torsional stiffness   
	
	uniaxialMaterial Elastic $matTorsion $GJ;					# define elastic torsional stiffness
	section Aggregator $secID $matTorsion T -section $secTag;	# combine section properties
}