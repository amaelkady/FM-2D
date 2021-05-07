############################################################################################
# ConstructFiberBeam.tcl
#
# This procedure will produce a 2D beam element between the 2 given points in a 2D/3D system (Z coordinates were set to 0).
# P-Delta Transformation is used by default
#
# Command Syntax ConstructBrace eleID Node1 Node2 secID numSeg Initial_GI nInt Trans_tag
#
# Command Arguments
# L 			Overall Length of Bracing
# Initial_GI	Required Maximum Initial Imperfection ratio at Middle of Bracing
# numSeg		Number of required Segment along Bracing Length
# nInt 			Number of integration point per segment.
# Node1 		Node ID Brace Element Start Point
# Node2			Node ID Brace Element End Point
# Splice_status 0 --> Column wtih No Splice
#				1 --> Column with Splice (lower part)
#				2 --> Column with Splice (upper part)
############################################################################################

proc ConstructFiberBeam {eleID Node1 Node2 secID numSeg Initial_GI nInt Trans_tag Splice_status} {

set integration "Lobatto $secID $nInt"
set PI [expr 2*asin(1.0)];	# define constant pi

# Get Coordinates of the Column End Points
set X1 [nodeCoord $Node1 1];
set Y1 [nodeCoord $Node1 2];
set X2 [nodeCoord $Node2 1];
set Y2 [nodeCoord $Node2 2];

# Deduce the Length of the Column
set L [expr sqrt(pow(($X2-$X1),2)+ pow(($Y2-$Y1),2))];
	
if {$Splice_status==0} {

	# Set nodeID for the first intermediate node
	set nodeID [expr 100000+$Node1]

	for {set i 1} {$i <= [expr $numSeg-1]} {incr i 1} {
		set nodeid [expr $nodeID+$i]
		# Deduce the coordinates of each intermediate node in global system
		set xGlobal [expr $X1+$L/$numSeg*$i];
		set yGlobal [expr $Y1+sin($PI*$i/$numSeg)*$Initial_GI*$L];		
		node $nodeid $xGlobal $yGlobal
	}

	# Define segments
	# set initial elementID
	set ElementID [expr $eleID]
	#puts "S0 $ElementID"

	if {$numSeg>1} {
		# Define first element
		element dispBeamColumn $ElementID $Node1 [expr $nodeID+1] $nInt $secID $Trans_tag -integration $integration
					
		# Define internal elements
		for {set i 1} {$i <[expr $numSeg-1]} {incr i 1} {
			incr ElementID 1
			set iNode [expr $i +$nodeID]
			set jNode [expr $i +$nodeID+1]
			# Create the Brace Elements
			element dispBeamColumn $ElementID $iNode $jNode $nInt $secID $Trans_tag -integration $integration
		}

		# Define last element
		element dispBeamColumn [expr $ElementID+1] [expr $nodeID+$numSeg-1] $Node2 $nInt $secID $Trans_tag -integration $integration
	} else {
		element dispBeamColumn $ElementID  $Node1 $Node2 $nInt $secID $Trans_tag -integration $integration
	}
}

if {$Splice_status==1} {

	# Set nodeID for the first intermediate node
	set nodeID [expr 100000+$Node1+3]

	for {set i 1} {$i <= [expr $numSeg-1]} {incr i 1} {
		set nodeid [expr $nodeID+$i]
		# Deduce the coordinates of each intermediate node in global system
		set xGlobal [expr $X1+$L/$numSeg*$i];
		set yGlobal [expr $Y1+sin($PI*$i/$numSeg)*$Initial_GI*$L];		
		node $nodeid $xGlobal $yGlobal
	}

	# Define segments
	# set initial elementID
	set ElementID [expr $eleID+3]
	#puts "S1 $ElementID"

	if {$numSeg>1} {
		# Define first element
		element dispBeamColumn $eleID $Node1 [expr $nodeID+1] $nInt $secID $Trans_tag -integration $integration
					
		# Define internal elements
		for {set i 1} {$i <[expr $numSeg-1]} {incr i 1} {
			incr ElementID 1
			set iNode [expr $i +$nodeID]
			set jNode [expr $i +$nodeID+1]
			# Create the Brace Elements
			element dispBeamColumn $ElementID $iNode $jNode $nInt $secID $Trans_tag -integration $integration
		}

		# Define last element
		element dispBeamColumn [expr $ElementID+1] [expr $nodeID+$numSeg-1] $Node2 $nInt $secID $Trans_tag -integration $integration
	} else {
		element dispBeamColumn $eleID  $Node1 $Node2 $nInt $secID $Trans_tag -integration $integration
	}

}

if {$Splice_status==2} {

	# Set nodeID for the first intermediate node
	set nodeID [expr 100000+$Node2+10]

	for {set i 1} {$i <= [expr $numSeg-1]} {incr i 1} {
		set nodeid [expr $nodeID+$i]
		# Deduce the coordinates of each intermediate node in global system
		set xGlobal [expr $X2+sin($PI*$i/$numSeg)*$Initial_GI*$L];
		set yGlobal [expr $Y2-$L/$numSeg*$i];		
		node $nodeid $xGlobal $yGlobal
	}

	# Define segments
	# set initial elementID
	set ElementID [expr $eleID+10]
	#puts "S2 $ElementID"
	if {$numSeg>1} {
		# Define first element
		element dispBeamColumn $eleID $Node1 [expr $nodeID+1] $nInt $secID $Trans_tag -integration $integration
					
		# Define internal elements
		for {set i 1} {$i <[expr $numSeg-1]} {incr i 1} {
			incr ElementID 1
			set iNode [expr $i +$nodeID]
			set jNode [expr $i +$nodeID+1]
			# Create the Brace Elements
			element dispBeamColumn $ElementID $iNode $jNode $nInt $secID $Trans_tag -integration $integration
		}

		# Define last element
		element dispBeamColumn [expr $ElementID+1] [expr $nodeID+$numSeg-1] $Node2 $nInt $secID $Trans_tag -integration $integration
	} else {
		element dispBeamColumn $eleID  $Node1 $Node2 $nInt $secID $Trans_tag -integration $integration
	}

}




}