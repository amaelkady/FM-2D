##################################################################################################################
# ConstructBrace.tcl
#
# SubRoutine to construct a 2D brace element between the 2 given points in a 2D/3D system (Z coordinates set to 0).
#
##################################################################################################################
#
# Input Arguments:
#------------------
# elelID 		Brace element ID
# NodeI 		Brace start node ID
# NodeJ			Brace end node ID
# numSeg		Number of segments along the brace length
# Initial_GI	Initial geometric imperfection ratio at brace mid-length
# nInt 			Number of integration point per segment
# Trans_tag 	Geometric transformation ID
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################

proc ConstructBrace {eleID NodeI NodeJ secID numSeg Initial_GI nInt Trans_tag} {

global Sigma_GI; global xRandom;
if {$Initial_GI != 0} {
	set SigmaX $Sigma_GI; Generate_lognrmrand $Initial_GI 	$SigmaX; 	set Initial_GI 	$xRandom;
}
	
set integration "Lobatto $secID $nInt"
set PI [expr 2*asin(1.0)];	# define constant pi

# Get Coordinates of the Brace End Points
set X1 [nodeCoord $NodeI 1];
set Y1 [nodeCoord $NodeI 2];
set X2 [nodeCoord $NodeJ 1];
set Y2 [nodeCoord $NodeJ 2];

# Set nodeID for the first intermediate node
set nodeID [expr 1000*$NodeI]

# Deduce the Length of the Brace
set L [expr sqrt(pow(($X2-$X1),2)+ pow(($Y2-$Y1),2))];

# Get the SIN and COS of the Brace Inclination Angle
set Cos [expr ($X2-$X1)/$L];
set Sin [expr ($Y2-$Y1)/$L];

for {set i 1} {$i <= [expr $numSeg-1]} {incr i 1} {

	# Deduce the coordinates of each intermediate node in local system
	set nodeid [expr $nodeID+$i];
	set xLocal [expr $L/$numSeg*$i];
	set yLocal [expr sin($PI*$i/$numSeg)*$Initial_GI*$L];
	set zLocal $yLocal;

	# Use transformation matrix to convert the coordinate from local system to global system 
	set xRotZ [expr $xLocal*$Cos-$yLocal*$Sin];
	set yRotZ [expr $xLocal*$Sin+$yLocal*$Cos];
	set zRotZ [expr $zLocal];

	# Deduce the coordinates of each intermediate node in global system
	set xGlobal [expr $X1+$xRotZ];
	set yGlobal [expr $Y1+$yRotZ];
	set zGlobal [expr $zRotZ];
	
	# Define node in 3D system
	# node $nodeid $xGlobal $yGlobal
	node $nodeid $xGlobal $yGlobal $zGlobal;
}

# Define segments
# set initial elementID
set ElementID [expr $eleID+1];
# Define first element
element dispBeamColumn $ElementID $NodeI [expr $nodeID+1] $nInt $secID $Trans_tag -integration $integration;
            
# Define internal elements #
for {set i 1} {$i <[expr $numSeg-1]} {incr i 1} {
	incr ElementID 1;
	set iNode [expr $i +$nodeID];
	set jNode [expr $i +$nodeID+1];
	# Create the Brace Elements
	element dispBeamColumn $ElementID $iNode $jNode $nInt $secID $Trans_tag -integration $integration;
}

# Create the Brace Elements
element dispBeamColumn [expr $ElementID+1] [expr $nodeID+$numSeg-1] $NodeJ $nInt $secID $Trans_tag -integration $integration;

}