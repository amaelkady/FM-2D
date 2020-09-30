########################################################################################################
# ConstructPanel_Rectangle.tcl                                                                         
#
# SubRoutine to construct nodes and rigid elements for the panel zone parallelogram model
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


proc ConstructPanel_Rectangle {Axis Floor X_Axis Y_Floor E A_Panel I_Panel d_Col d_Beam transfTag} {
 
 # Construct Panel Node Notation
 set NodeCL    [expr 400000+$Floor*1000+$Axis*100];  # Grid Line Dummy Node
 set Node_XY01 [expr $NodeCL + 1];
 set Node_XY02 [expr $NodeCL + 2];
 set Node_XY03 [expr $NodeCL + 3];
 set Node_XY04 [expr $NodeCL + 4];
 set Node_XY05 [expr $NodeCL + 5];
 set Node_XY06 [expr $NodeCL + 6];
 set Node_XY07 [expr $NodeCL + 7];
 set Node_XY08 [expr $NodeCL + 8];
 set Node_XY09 [expr $NodeCL + 9];
 set Node_XY10 [expr $NodeCL + 10];
 set Node_XY11 [expr $NodeCL + 88];
 set Node_XY12 [expr $NodeCL + 99];
 
 # Construct Panel Element Notation
 set P_Elm_100XY00 [expr 7000000 + $Floor*1000 + $Axis*100];  # ID for ZeroLength Panel Element
 set P_Elm_100XY01 [expr $P_Elm_100XY00 + 1];
 set P_Elm_100XY02 [expr $P_Elm_100XY00 + 2];
 set P_Elm_100XY03 [expr $P_Elm_100XY00 + 3];
 set P_Elm_100XY04 [expr $P_Elm_100XY00 + 4];
 set P_Elm_100XY05 [expr $P_Elm_100XY00 + 5];
 set P_Elm_100XY06 [expr $P_Elm_100XY00 + 6];
 set P_Elm_100XY07 [expr $P_Elm_100XY00 + 7];
 set P_Elm_100XY08 [expr $P_Elm_100XY00 + 8];
 
 # Construct Panel Node Coordinates
 node $Node_XY01 [expr $X_Axis]            [expr $Y_Floor - $d_Beam/2]; 
 node $Node_XY02 [expr $X_Axis - $d_Col/2] [expr $Y_Floor]; 
 node $Node_XY03 [expr $X_Axis]            [expr $Y_Floor + $d_Beam/2]; 
 node $Node_XY04 [expr $X_Axis + $d_Col/2] [expr $Y_Floor]; 
 node $Node_XY05 [expr $X_Axis - $d_Col/2] [expr $Y_Floor - $d_Beam/2]; 
 node $Node_XY06 [expr $X_Axis - $d_Col/2] [expr $Y_Floor - $d_Beam/2]; 
 node $Node_XY07 [expr $X_Axis - $d_Col/2] [expr $Y_Floor + $d_Beam/2]; 
 node $Node_XY08 [expr $X_Axis - $d_Col/2] [expr $Y_Floor + $d_Beam/2]; 
 node $Node_XY09 [expr $X_Axis + $d_Col/2] [expr $Y_Floor + $d_Beam/2]; 
 node $Node_XY10 [expr $X_Axis + $d_Col/2] [expr $Y_Floor + $d_Beam/2];
 node $Node_XY11 [expr $X_Axis + $d_Col/2] [expr $Y_Floor - $d_Beam/2]; 
 node $Node_XY12 [expr $X_Axis + $d_Col/2] [expr $Y_Floor - $d_Beam/2];
 
 # Construct Panel Element Property
 element elasticBeamColumn    $P_Elm_100XY01    $Node_XY01   $Node_XY05     $A_Panel    $E      $I_Panel   $transfTag;
 element elasticBeamColumn    $P_Elm_100XY02    $Node_XY06   $Node_XY02     $A_Panel    $E      $I_Panel   $transfTag;
 element elasticBeamColumn    $P_Elm_100XY03    $Node_XY02   $Node_XY07     $A_Panel    $E      $I_Panel   $transfTag;
 element elasticBeamColumn    $P_Elm_100XY04    $Node_XY08   $Node_XY03     $A_Panel    $E      $I_Panel   $transfTag;
 element elasticBeamColumn    $P_Elm_100XY05    $Node_XY03   $Node_XY09     $A_Panel    $E      $I_Panel   $transfTag;
 element elasticBeamColumn    $P_Elm_100XY06    $Node_XY10   $Node_XY04     $A_Panel    $E      $I_Panel   $transfTag;
 element elasticBeamColumn    $P_Elm_100XY07    $Node_XY04   $Node_XY11     $A_Panel    $E      $I_Panel   $transfTag;
 element elasticBeamColumn    $P_Elm_100XY08    $Node_XY12   $Node_XY01     $A_Panel    $E      $I_Panel   $transfTag;

 # Restrain DOFs At Panel Corners
 equalDOF    $Node_XY05     $Node_XY06    1     2;
 equalDOF    $Node_XY07     $Node_XY08    1     2;
 equalDOF    $Node_XY09     $Node_XY10    1     2;
 equalDOF    $Node_XY11     $Node_XY12    1     2;
 
}