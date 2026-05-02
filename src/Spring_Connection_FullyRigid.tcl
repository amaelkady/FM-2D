##################################################################################################################
# Spring_Connection_FullyRigid.tcl
#                                                                                       
# SubRoutine to construct a rotational spring representing the moment-rotation behaviour of steel beams that are 
# part of fully-restrained beam-to-column connections.                                                                 
#  
# The subroutine also considers modeling uncertainty based on the logarithmic standard deviations specified by the user.
#
# References: 
#--------------	
# Lignos and Krawinkler (2011). "Deterioration Modeling of Steel Components in Support of Collapse 
# 	Prediction of Steel Moment Frames under Earthquake Loading." Journal of Structural Engineering 137(11).	
#
# Elkady and Lignos (2014). "Modeling of the Composite Action in Fully Restrained Beam-to-Column
# 	Connections: ‎Implications in the Seismic Design and Collapse Capacity of Steel Special Moment Frames." 
# 	Earthquake Eng. & Structural Dynamics 43(13).
#
##################################################################################################################
#
# Input Arguments:
#------------------
#  SpringID  			Spring ID
#  NodeI				Node i ID
#  NodeJ				Node j ID
#  E         			Young's modulus
#  Fy        			Yield stress
#  Ix        			Moment of inertia of section
#  d         			Section depth
#  htw        			Web slenderness ratio
#  bftf        			Flange slenderness ratio
#  L         			Member Length
#  Ls         			Shear Span
#  Lb        			Unbraced length
#  My        			Effective Yield Moment
#  CompositeFlag		FLAG for Composite Action Consideration: 0 --> Ignore   Composite Effect   
# 															 	 1 --> Consider Composite Effect
#  ConnectionType		Type of Connection: 0 --> Reduced     Beam Section Connection in fully-rigid beam-to-column joints  
# 											1 --> Non-Reduced Beam Section Connection in fully-rigid beam-to-column joints     
#  Units				Unsed Units: 1 --> millimeters and MPa     
#								 	 2 --> inches and ksi
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################


proc Spring_Connection_FullyRigid {SpringID NodeI NodeJ E Fy Ix d htw bftf ry L Ls Lb My CompositeFlag ConnectionType Units} {

if {$Units == 1} {
	set c1 1.0;
	set c2 1.0;	
	set c3 25.4;
	set c4 1000.0;
} else {
	set c1 25.4;
	set c2 6.895;
	set c3 1.0;
	set c4 1.0;
}


set n 100.0;
set K  [expr ($n+1.0) * 6 * $E * $Ix / $L];

#######################################################################################################
#######################################################################################################
#######################################################################################################
#######################################################################################################


if {$ConnectionType == 0} {

	set My [expr 1.06 * $My];

	# Rotational capacities calculated using  Lignos and Krawinkler (2009) RBS equations
	set theta_p   [expr 0.19 * pow(($htw),-0.314) * pow(($bftf),-0.100) *  pow(($Lb/$ry),-0.185) * pow(($Ls/$d),0.113) * pow(($c1 * $d/533),-0.760) * pow(($c2 * $Fy* $c4/355),-0.070)];
 	set theta_pc  [expr 9.52 * pow(($htw),-0.513) * pow(($bftf),-0.863) *  pow(($Lb/$ry),-0.108) 													* pow(($c2 * $Fy* $c4/355),-0.360)];
	set Lmda      [expr 585  * pow(($htw),-1.140) * pow(($bftf),-0.632) *  pow(($Lb/$ry),-0.205) 													* pow(($c2 * $Fy* $c4/355),-0.391)];

	# FOR BARE STEEL BEAM
	if {$CompositeFlag == 0} {
		set MyPMy 1.00;
		set MyNMy 1.00;
		set McMyP 1.09;
		set McMyN 1.09;
		
		# Corrected rotations to account for elastic deformations
		set theta_y  [expr $My/(6 * $E * $Ix / $L)];
		set theta_p  [expr $theta_p  - ($McMyP-1.0)*$My/(6 * $E * $Ix / $L)];
		set theta_pc [expr $theta_pc + $theta_y + ($McMyP-1.0)*$My/(6 * $E * $Ix / $L)];
	
		set theta_p_P   $theta_p;
		set theta_p_N   $theta_p;
		set theta_pc_P  $theta_pc;	
		set theta_pc_N  $theta_pc;
		set theta_u   		  0.2;

		set D_P 1.0;
		set D_N 1.0;
		
		set MresMy_P 0.4;
		set MresMy_N 0.4;
		
		set c 1.0;

	}

	# FOR COMPOSITE BEAM
	if {$CompositeFlag != 0} {
		set MyPMy 1.35;
		set MyNMy 1.25;
		set McMyP 1.30;
		set McMyN 1.05;

		# Corrected rotations to account for elastic deformations
		set theta_y    [expr $My/(6 * $E * $Ix / $L)];
		set theta_p_p  [expr $theta_p  - ($McMyP-1.0)*$My/(6 * $E * $Ix / $L)];
		set theta_p_n  [expr $theta_p  - ($McMyN-1.0)*$My/(6 * $E * $Ix / $L)];
		set theta_pc_p [expr $theta_pc + $theta_y + ($McMyP-1.0)*$My/(6 * $E * $Ix / $L)];
		set theta_pc_n [expr $theta_pc + $theta_y + ($McMyN-1.0)*$My/(6 * $E * $Ix / $L)];
		
		set theta_p_P   [expr 1.80*$theta_p_p];
		set theta_p_N   [expr 0.95*$theta_p_n];
		set theta_pc_P  [expr 1.35*$theta_pc_p];
		set theta_pc_N  [expr 0.95*$theta_pc_n];
		set theta_u   		  0.2;

		set D_P 1.15;
		set D_N 1.0;

		set Res_P 0.3;
		set Res_N 0.2;
		
		set c 1.0;

	}
	
}

#######################################################################################################
#######################################################################################################
#######################################################################################################
#######################################################################################################

if {$ConnectionType == 1} {

	set My [expr 1.17 * $My];

	# Rotational capacities calculated using Lignos and Krawinkler (2009) other-than-RBS equations
	if {$d > [expr $c3*21.0]} {
		set theta_p   [expr 0.318 * pow(($htw),-0.550) * pow(($bftf),-0.345) *  pow(($Lb/$ry),-0.023) *  pow(($Ls/$d),0.090) *  pow(($c1 * $d/533),-0.330) * pow(($c2 * $Fy* $c4/355),-0.130)];
		set theta_pc  [expr 7.500 * pow(($htw),-0.610) * pow(($bftf),-0.710) *  pow(($Lb/$ry),-0.110) 					     *  pow(($c1 * $d/533),-0.161) * pow(($c2 * $Fy* $c4/355),-0.320)];
		set Lmda      [expr 536   * pow(($htw),-1.260) * pow(($bftf),-0.525) *  pow(($Lb/$ry),-0.130) 					     							   * pow(($c2 * $Fy* $c4/355),-0.291)];
	} else {
		set theta_p   [expr 0.0865 * pow(($htw),-0.360) * pow(($bftf),-0.140) 					 	  *  pow(($Ls/$d),0.340) *  pow(($c1 * $d/533),-0.721) * pow(($c2 * $Fy* $c4/355),-0.230)];
		set theta_pc  [expr 5.6300 * pow(($htw),-0.565) * pow(($bftf),-0.800) 					   	 						 *  pow(($c1 * $d/533),-0.280) * pow(($c2 * $Fy* $c4/355),-0.430)];
		set Lmda      [expr 495    * pow(($htw),-1.340) * pow(($bftf),-0.595) 					   								   						   * pow(($c2 * $Fy* $c4/355),-0.360)];

	}
	
	# FOR BARE STEEL BEAM
	if {$CompositeFlag == 0} {		
		set MyPMy    1.00;
		set MyNMy    1.00;
		set McMyP    1.11;
		set McMyN    1.11;

		# Corrected rotations to account for elastic deformations
		set theta_y  [expr $My/(6 * $E * $Ix / $L)];
		set theta_p_P   $theta_p;
		set theta_p_N   $theta_p;
		set theta_pc_P  $theta_pc;
		set theta_pc_N  $theta_pc;
		set theta_u   		  0.2;
		
		set D_P 1.0;
		set D_N 1.0;
		
		set MresMy_P 0.4;
		set MresMy_N 0.4;
		
		set c 1.0;

	}

	# FOR COMPOSITE BEAM
	if {$CompositeFlag != 0} {
		set MyPMy 1.35;
		set MyNMy 1.25;
		set McMyP 1.30;
		set McMyN 1.05;

		# Corrected rotations to account for elastic deformations
		set theta_y    [expr $My/(6 * $E * $Ix / $L)];
		set theta_p_p  [expr $theta_p  - ($McMyP-1.0)*$My/(6 * $E * $Ix / $L)];
		set theta_p_n  [expr $theta_p  - ($McMyN-1.0)*$My/(6 * $E * $Ix / $L)];
		set theta_pc_p [expr $theta_pc + $theta_y + ($McMyP-1.0)*$My/(6 * $E * $Ix / $L)];
		set theta_pc_n [expr $theta_pc + $theta_y + ($McMyN-1.0)*$My/(6 * $E * $Ix / $L)];
		
		set theta_p_P   [expr 1.80*$theta_p_p];
		set theta_p_N   [expr 0.95*$theta_p_n];
		set theta_pc_P  [expr 1.35*$theta_pc_p];
		set theta_pc_N  [expr 0.95*$theta_pc_n];
		set theta_u   		  0.2;

		set D_P 1.15;
		set D_N 1.00;
		
		set MresMy_P 0.3;
		set MresMy_N 0.2;
		
		set c 1.0;

	}
}

#######################################################################################################
#######################################################################################################
#######################################################################################################
#######################################################################################################


set My_P     [expr  $MyPMy * $My]; 
set My_N     [expr  $MyNMy * $My];

##################################################################################################################
#Random generation of backbone parameters based on assigned uncertainty 
##################################################################################################################
global Sigma_IMKcol Sigma_IMKbeam; global xRandom;

if {$CompositeFlag == 0} {
	set SigmaX [lindex $Sigma_IMKbeam 0]; Generate_lognrmrand $K $SigmaX; 			set K 			$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 1]; Generate_lognrmrand $My_P $SigmaX; 		set My_P 		$xRandom;
																					set My_N 		$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 2]; Generate_lognrmrand $McMyP $SigmaX; 		set McMyP 		[expr max(1.01,$xRandom)];
																					set McMyN 		[expr max(1.01,$xRandom)];
	set SigmaX [lindex $Sigma_IMKbeam 3]; Generate_lognrmrand $MresMy_P $SigmaX; 	set MresMy_P 	$xRandom;
																					set MresMy_N 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 4]; Generate_lognrmrand $theta_p_P $SigmaX; 	set theta_p_P 	$xRandom;
																					set theta_p_N 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 5]; Generate_lognrmrand $theta_pc_P $SigmaX; 	set theta_pc_P 	$xRandom;
																					set theta_pc_N 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 6]; Generate_lognrmrand $theta_u $SigmaX; 	set theta_u 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 7]; Generate_lognrmrand $Lmda $SigmaX; 		set Lmda 		$xRandom;
	#set SigmaX [lindex $Sigma_IMKbeam 8]; Generate_lognrmrand $c $SigmaX; 			set c 			$xRandom;

} 
if {$CompositeFlag == 1} {
	set SigmaX [lindex $Sigma_IMKbeam 0]; Generate_lognrmrand $K 		  $SigmaX; 	set K 			$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 1]; Generate_lognrmrand $My_P 	  $SigmaX; 	set My_P 		$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 1]; Generate_lognrmrand $My_N 	  $SigmaX; 	set My_N 		$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 2]; Generate_lognrmrand $McMyP 	  $SigmaX; 	set McMyP 		[expr max(1.01,$xRandom)];
	set SigmaX [lindex $Sigma_IMKbeam 2]; Generate_lognrmrand $McMyN 	  $SigmaX; 	set McMyN 		[expr max(1.01,$xRandom)];
	set SigmaX [lindex $Sigma_IMKbeam 3]; Generate_lognrmrand $MresMy_P   $SigmaX; 	set MresMy_P 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 3]; Generate_lognrmrand $MresMy_N   $SigmaX; 	set MresMy_N 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 4]; Generate_lognrmrand $theta_p_P  $SigmaX; 	set theta_p_P 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 4]; Generate_lognrmrand $theta_p_N  $SigmaX; 	set theta_p_N 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 5]; Generate_lognrmrand $theta_pc_P $SigmaX; 	set theta_pc_P 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 5]; Generate_lognrmrand $theta_pc_N $SigmaX; 	set theta_pc_N 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 6]; Generate_lognrmrand $theta_u 	  $SigmaX; 	set theta_u 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 7]; Generate_lognrmrand $Lmda 	  $SigmaX; 	set Lmda 		$xRandom;
	#set SigmaX [lindex $Sigma_IMKbeam 8]; Generate_lognrmrand $c 		  $SigmaX; 	set c 			$xRandom;
}
##################################################################################################################
##################################################################################################################
##################################################################################################################



# Cyclic deterioration parameters
set L_S $Lmda; set L_C 			 $Lmda;  set L_A $Lmda; set L_K 		  $Lmda;

set c_S $c;    set c_C $c; 				 set c_A $c; 	set c_K $c;

# IMKBilin material model (This is the updated version of the Bilin model)
uniaxialMaterial IMKBilin $SpringID $K $theta_p_P $theta_pc_P $theta_u $My_P $McMyP $MresMy_P $theta_p_N $theta_pc_N $theta_u $My_N $McMyN $MresMy_N $L_S $L_C $L_K $c_S $c_C $c_K $D_P $D_N;

element zeroLength $SpringID $NodeI $NodeJ  -mat 99 99 $SpringID -dir 1 2 6 -doRayleigh 1;


}