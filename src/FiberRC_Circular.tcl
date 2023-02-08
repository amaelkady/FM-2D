############################################################
# FiberRC_Circular $secTag $D $cover  $nBar $areaBar
############################################################
#
# Build fiber circular RC section with one layer of steel evenly distributed 
# around the perimeter and a confined core.
#
# adapted from Michael H. Scott, 2003
# 
# Input arguments
#    secID 		- section tag
#    D 			- section outer diameter
#    cover 		- distance from section boundary to neutral axis of reinforcement
#    nBar 		- number of reinforcing bars
#    areaBar 	- cross-section area of a single reinforcement bar
#    
# Notes
#    The center of the reinforcing bars are placed at the inner radius
#    The core concrete ends at the inner radius (same as reinforcing bars)
#    The reinforcing bars are all the same size
#    The center of the section is at (0,0) in the local axis system
#    Zero degrees is along section y-axis

proc FiberRC_Circular {secID D cover nBar areaBar} {

	set ri 0.0;			# inner radius of the section, only for hollow sections
	set ro [expr $D/2];	# overall (outer) radius of the section
	set nfCoreR 8;		# number of radial divisions in the core (number of "rings")
	set nfCoreT 8;		# number of theta divisions in the core (number of "wedges")
	set nfCoverR 4;		# number of radial divisions in the cover
	set nfCoverT 8;		# number of theta divisions in the cover

	# Define the fiber section
	section fiberSec $secID  {
		set rc [expr $ro-$cover];								# Core radius
		patch circ 888 $nfCoreT  $nfCoreR  0 0 $ri $rc 0 360;	# Define the core patch
		patch circ 889 $nfCoverT $nfCoverR 0 0 $rc $ro 0 360;	# Define the cover patch
		set theta [expr 360.0/$nBar];							# Determine angle increment between bars
		layer circ 666 $nBar $areaBar 0 0 $rc $theta 360;		# Define the reinforcing layer
	}

}