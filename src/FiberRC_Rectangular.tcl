######################################################################################################################
# FiberRC_Rectangular $secTag $H $B $coverH $coverB $nBarTop $areaBarTop $nBarBot $areaBarBot $nBarIntTot $areaBarInt
######################################################################################################################
#
# Build fiber rectangular RC section, 1 steel layer top, 1 bot, 1 skin, confined core
# Define a procedure which generates a rectangular reinforced concrete section
# with one layer of steel at the top & bottom, skin reinforcement and a 
# confined core.
#		by: Silvia Mazzoni, 2006
#			adapted from Michael H. Scott, 2003
# 
# Input arguments
#    secID 		- section tag
#    H 			- section depth along local-y axis
#    B 			- section width along local-z axis
#    coverH 	- distance from section boundary to neutral axis of reinforcement
#    coverB 	- distance from section boundary to side of reinforcement
#    nBarTop 	- number of reinforcing bars in the top layer
#    nBarBot 	- number of reinforcing bars in the bottom layer
#    nBarIntTot - TOTAL number of reinforcing bars on the intermediate layers, symmetric about z axis and 2 bars per layer-- needs to be an even integer
#    areaBarTop - cross-sectional area of each reinforcing bar in top layer
#    areaBarBot - cross-sectional area of each reinforcing bar in bottom layer
#    areaBarInt - cross-sectional area of each reinforcing bar in intermediate layer 
#    
# Notes
#    The core concrete ends at the NA of the reinforcement
#    The center of the section is at (0,0) in the local axis system
#
#                       y
#                       ^
#                       |     
#             --------------------  ---
#             |  o      o     o  |   | -- coverH
#             |                  |   |
#             |  o            o  |   |
#      z <--- |         +        |   H
#             |  o            o  |   |
#             |                  |   |
#             |  o o o o  o o o  |   | -- coverH
#             --------------------  ---
#             |<--------B------->|
#             |--|            |--|
#            coverB          coverB
#                       y
#                       ^
#                       |    
#             -------------------- ---
#             |\      cover     /|  |
#             | \------Top-----/ |  |
#             |c|              |c|  |
#             |o|              |o|  |
#      z <--- |v|     core     |v|  H
#             |e|              |e|  |
#             |r|              |r|  |
#             | /------Bot-----\ |  |
#             |/      cover     \|  |
#             -------------------- ---
#             |<--------B------->|
#    


proc FiberRC_Rectangular {secID H B coverH coverB nBarTop areaBarTop nBarBot areaBarBot nBarIntTot areaBarInt} {
	
	set    nfCoreY 	20; # number of fibers in the core patch in the y direction
	set    nfCoreZ 	20; # number of fibers in the core patch in the z direction
	set    nfCoverY 20; # number of fibers in the cover patches with long sides in the y direction
	set    nfCoverZ 20; # number of fibers in the cover patches with long sides in the z direction

	# Define the section geometry
	set coverY  [expr $H/2.0];			# The distance from the section z-axis to the edge of the cover concrete -- outer edge of cover concrete
	set coverZ  [expr $B/2.0];			# The distance from the section y-axis to the edge of the cover concrete -- outer edge of cover concrete
	set coreY   [expr $coverY-$coverH];	# The distance from the section z-axis to the edge of the core concrete --  edge of the core concrete/inner edge of cover concrete
	set coreZ   [expr $coverZ-$coverB];	# The distance from the section y-axis to the edge of the core concrete --  edge of the core concrete/inner edge of cover concrete
	set nBarInt [expr $nBarIntTot/2];	# number of intermediate bars per side

	# Define the fiber section
	section fiberSec $secID {
		# Define the core patch
		patch quadr 888 $nfCoreZ $nfCoreY -$coreY $coreZ -$coreY -$coreZ $coreY -$coreZ $coreY $coreZ
	   
		# Define the four cover patches
		patch quadr 889 2 			$nfCoverY 	-$coverY 	$coverZ 	-$coreY 	 $coreZ 	$coreY 		 $coreZ 	 $coverY 	 $coverZ
		patch quadr 889 2 			$nfCoverY 	-$coreY    -$coreZ 		-$coverY 	-$coverZ 	$coverY 	-$coverZ 	 $coreY 	-$coreZ
		patch quadr 889 $nfCoverZ 	2 			-$coverY 	$coverZ 	-$coverY 	-$coverZ   -$coreY 		-$coreZ 	-$coreY 	 $coreZ
		patch quadr 889 $nfCoverZ 	2  			 $coreY  	$coreZ 		 $coreY 	-$coreZ 	$coverY 	-$coverZ 	 $coverY 	 $coverZ	

		# define reinforcing layers
		layer straight 666 $nBarInt $areaBarInt  -$coreY  $coreZ  $coreY  $coreZ;	# intermediate skin reinf. +z
		layer straight 666 $nBarInt $areaBarInt  -$coreY -$coreZ  $coreY -$coreZ;	# intermediate skin reinf. -z
		layer straight 666 $nBarTop $areaBarTop   $coreY  $coreZ  $coreY -$coreZ;	# top layer reinfocement
		layer straight 666 $nBarBot $areaBarBot  -$coreY  $coreZ -$coreY -$coreZ;	# bottom layer reinforcement

	};
	
};

