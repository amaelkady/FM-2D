##################################################################################################################
# ConstructPanel_Cross.tcl
#
# SubRoutine to construct nodes and rigid elements for the panel zone cruciform model
#                                                      
##################################################################################################################
#
# Input Arguments:
#------------------
# Axis      	Axis  number ID
# Floor     	Floor number ID
# E         	Young's modulus
# A_Panel   	Area of rigid link that creates the panel zone
# I_Panel   	Moment of inertia of rigid link that creates the panel zone
# d_Col     	Column section depth
# d_Beam    	Beam section depth
# transfTag 	Geometric transformation ID
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################

proc ConstructPanel_Cross {Axis Floor X_Axis Y_Floor E A_Panel I_Panel  d_Col d_Beam transfTag} {
 
	# Construct Panel Node Notation
	set NodeCL    [expr ($Floor*10+$Axis)*10];  # Grid Line Dummy Node
	set NodeID    [expr 400000+$Floor*1000+$Axis*100];  # Grid Line Dummy Node
	set Node_XY01 [expr $NodeID + 1];
	set Node_XY02 [expr $NodeID + 2];
	set Node_XY03 [expr $NodeID + 3];
	set Node_XY04 [expr $NodeID + 4];


	# Construct Panel Element Notation
	set P_Elm_100XY00 [expr 7000000 + $Floor*1000 + $Axis*100];  # ID for ZeroLength Panel Element
	set P_Elm_100XY01 [expr $P_Elm_100XY00 + 1];
	set P_Elm_100XY02 [expr $P_Elm_100XY00 + 2];
	set P_Elm_100XY03 [expr $P_Elm_100XY00 + 3];
	set P_Elm_100XY04 [expr $P_Elm_100XY00 + 4];

	# Construct Panel Node Coordinates
	# node [NodeID]  [XCoordinate]   [YCoordinate]
	node $NodeCL 		  $X_Axis            		$Y_Floor;
	node $Node_XY01 [expr $X_Axis]            [expr $Y_Floor - $d_Beam/2];
	node $Node_XY02 [expr $X_Axis - $d_Col/2] [expr $Y_Floor]; 
	node $Node_XY03 [expr $X_Axis]            [expr $Y_Floor + $d_Beam/2]; 
	node $Node_XY04 [expr $X_Axis + $d_Col/2] [expr $Y_Floor];

	# Construct Panel Element Property
	#                                 tag              ndI          ndJ          A_PZ       E       I_PZ       transfTag
	element elasticBeamColumn    $P_Elm_100XY01    $NodeCL   $Node_XY01     $A_Panel    $E      $I_Panel   $transfTag;
	element elasticBeamColumn    $P_Elm_100XY02    $NodeCL   $Node_XY02     $A_Panel    $E      $I_Panel   $transfTag;
	element elasticBeamColumn    $P_Elm_100XY03    $NodeCL   $Node_XY03     $A_Panel    $E      $I_Panel   $transfTag;
	element elasticBeamColumn    $P_Elm_100XY04    $NodeCL   $Node_XY04     $A_Panel    $E      $I_Panel   $transfTag;

 }