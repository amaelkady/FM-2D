##################################################################################################################
# Spring_IMK.tcl
#                                                                                       
# SubRoutine to construct a rotational spring representing the moment-rotation behaviour of steel beam-columns  
# and beams that are part of fully-restrained beam-to-column connections.                                                                 
#  
# The subroutine also considers modeling uncertainty based on the logarithmic standard deviations specified by the user.
#
# References: 
#--------------	
# Lignos, D. G. and H. Krawinkler (2011). "Deterioration Modeling of Steel Components in Support of Collapse 
# 	Prediction of Steel Moment Frames under Earthquake Loading." Journal of Structural Engineering 137(11).	
#
# Elkady, A. and D. G. Lignos (2014). "Modeling of the Composite Action in Fully Restrained Beam-to-Column
# 	Connections: ‎Implications in the Seismic Design and Collapse Capacity of Steel Special Moment Frames." 
# 	Earthquake Eng. & Structural Dynamics 43(13).
#
# Lignos, D. G., et al. (2019). "Proposed Updates to the ASCE 41 Nonlinear Modeling Parameters for Wide-Flange
#	 Steel Columns in Support of Performance-based Seismic Engineering." Journal of Structural Engineering 145(9).
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
#  PgPye        		Axial load ratio due to gravity
#  CompositeFlag		FLAG for Composite Action Consideration: 0 --> Ignore   Composite Effect   
# 															 	 1 --> Consider Composite Effect
#  ConnectionType		Type of Connection: 0 --> Reduced     Beam Section  
# 											1 --> Non-Reduced Beam Section    
# 											2 --> Column Section   
#  Units				Unsed Units: 1 --> millimeters and MPa     
#								 	 2 --> inches and ksi
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################


proc Spring_IMK {SpringID NodeI NodeJ E Fy Ix d htw bftf ry L Ls Lb My PgPye CompositeFlag ConnectionType Units} {

set n 10.0;
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


set K  [expr ($n+1.0) * 6 * $E * $Ix / $L];

#######################################################################################################
#######################################################################################################
#######################################################################################################
#######################################################################################################


if {$ConnectionType == 0} {

	# Rotational capacities calculated using  Lignos and Krawinkler (2009) RBS equations
	set theta_p   [expr 0.19 * pow(($htw),-0.314) * pow(($bftf),-0.100) *  pow(($Lb/$ry),-0.185) * pow(($Ls/$d),0.113) * pow(($c1 * $d/533),-0.760) * pow(($c2 * $Fy* $c4/355),-0.070)];
 	set theta_pc  [expr 9.52 * pow(($htw),-0.513) * pow(($bftf),-0.863) *  pow(($Lb/$ry),-0.108) 													* pow(($c2 * $Fy* $c4/355),-0.360)];
	set Lmda      [expr 585  * pow(($htw),-1.140) * pow(($bftf),-0.632) *  pow(($Lb/$ry),-0.205) 													* pow(($c2 * $Fy* $c4/355),-0.391)];

	# FOR BARE STEEL BEAM
	if {$CompositeFlag == 0} {
		set MyPMy 1.0;
		set MyNMy 1.0;
		set McMyP 1.1;
		set McMyN 1.1;
		
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
		
		set Res_P 0.4;
		set Res_N 0.4;
		
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

	# Rotational capacities calculated using Lignos and Krawinkler (2009) other-than-RBS equations
	if {$d > [expr $c3*21.0]} {
		set theta_p   [expr 0.318 * pow(($htw),-0.550) * pow(($bftf),-0.345) *  pow(($Lb/$ry),-0.023) *  pow(($Ls/$d),0.090) *  pow(($c1 * $d/533),-0.330) * pow(($c2 * $Fy* $c4/355),-0.130)];
		set theta_pc  [expr 7.500 * pow(($htw),-0.610) * pow(($bftf),-0.710) *  pow(($Lb/$ry),-0.110) 					     *  pow(($c1 * $d/533),-0.161) * pow(($c2 * $Fy* $c4/355),-0.320)];
		set Lmda      [expr 536   * pow(($htw),-1.260) * pow(($bftf),-0.525) *  pow(($Lb/$ry),-0.130) 					     *  pow(($c2 * $Fy* $c4/355),-0.291)];
	} else {
		set theta_p   [expr 0.0865 * pow(($htw),-0.360) * pow(($bftf),-0.140) *  pow(($Ls/$d),0.340) *  pow(($c1 * $d/533),-0.721) * pow(($c2 * $Fy* $c4/355),-0.230)];
		set theta_pc  [expr 5.6300 * pow(($htw),-0.565) * pow(($bftf),-0.800) 					   *  pow(($c1 * $d/533),-0.280) * pow(($c2 * $Fy* $c4/355),-0.430)];
		set Lmda      [expr 495    * pow(($htw),-1.340) * pow(($bftf),-0.595) 					   *  pow(($c2 * $Fy* $c4/355),-0.360)];

	}
	
	# FOR BARE STEEL BEAM
	if {$CompositeFlag == 0} {		
		set MyPMy    1.0;
		set MyNMy    1.0;
		set McMyP    1.1;
		set McMyN    1.1;

		# Corrected rotations to account for elastic deformations
		set theta_y  [expr $My/(6 * $E * $Ix / $L)];
		set theta_p_P   $theta_p;
		set theta_p_N   $theta_p;
		set theta_pc_P  $theta_pc;
		set theta_pc_N  $theta_pc;
		set theta_u   		  0.2;
		
		set D_P 1.0;
		set D_N 1.0;
		
		set Res_P 0.4;
		set Res_N 0.4;
		
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
		
		set Res_P 0.3;
		set Res_N 0.2;
		
		set c 1.0;

	}
}


#######################################################################################################
#######################################################################################################
#######################################################################################################
#######################################################################################################

if {$ConnectionType == 2} {
	
	# Rotational capacities calculated using Lignos et al. (2019) column regression equations for monotonic
	set theta_p   [expr 294 * pow(($htw),-1.700) * pow(($Lb/$ry),-0.700) * pow((1-$PgPye),1.600)];
	set theta_pc  [expr 90  * pow(($htw),-0.800) * pow(($Lb/$ry),-0.800) * pow((1-$PgPye),2.500)];
	if {$theta_p  > 0.20} {set theta_p  0.2}
	if {$theta_pc > 0.30} {set theta_pc 0.3}
	if {$PgPye <= 0.35} {
		set Lmda  [expr 25500 * pow(($htw),-2.140) * pow(($Lb/$ry),-0.530) * pow((1-$PgPye),4.920)];
	} else {
		set Lmda  [expr 268000* pow(($htw),-2.300) * pow(($Lb/$ry),-1.300) * pow((1-$PgPye),1.190)];	
	}
	
	if {$PgPye <= 0.2} {
		set My  [expr (1.15/1.1)*$My*(1-$PgPye/2)];
	} else {
		set My  [expr (1.15/1.1)*$My*(9/8)*(1-$PgPye)];
	}
	
	set McMy   [expr 12.5 * pow(($htw),-0.200) * pow(($Lb/$ry),-0.400) * pow((1-$PgPye),0.400)];
	if {$McMy  < 1.0} {set McMy  1.0}
	if {$McMy  > 1.3} {set McMy  1.3}
	
	set MyPMy    1.0;
	set MyNMy    1.0;
	set McMyP    $McMy;
	set McMyN    $McMy;
	
	# Corrected rotations to account for elastic deformations
	set theta_y  [expr $My/(6 * $E * $Ix / $L)];
	set theta_p  [expr $theta_p  - ($McMyP-1.0)*$My/(6 * $E * $Ix / $L)];
	set theta_pc [expr $theta_pc + $theta_y + ($McMyP-1.0)*$My/(6 * $E * $Ix / $L)];
	
	set theta_p_P   $theta_p;
	set theta_p_N   $theta_p;
	set theta_pc_P  $theta_pc;
	set theta_pc_N  $theta_pc;
	set theta_u   	0.15;
	
	set D_P 1.0;
	set D_N 1.0;
	
	set Res_P [expr 0.5-0.4*$PgPye];
	set Res_N [expr 0.5-0.4*$PgPye];
	
	set c 1.0;
	
}

#######################################################################################################
#######################################################################################################
#######################################################################################################
#######################################################################################################

set My_P     [expr  $MyPMy * $My]; 
set My_N     [expr  $MyNMy * $My];


# # Bilin material model
#set My_P     [expr  $MyPMy * $My]; 
#set My_N     [expr -$MyNMy * $My];		
#set as_mem_p [expr  ($McMyP-1.)*$My_P/($theta_p_P * 6.*$E * $Ix/$L)];
#set as_mem_n [expr -($McMyN-1.)*$My_N/($theta_p_N * 6.*$E * $Ix/$L)];
#set SH_mod_P [expr ($as_mem_p)/(1.0+$n*(1.0-$as_mem_p))];
#set SH_mod_N [expr ($as_mem_n)/(1.0+$n*(1.0-$as_mem_n))];
#uniaxialMaterial Bilin    $SpringID $K $SH_mod_P $SH_mod_N $My_P $My_N $L_S $L_C $L_A $L_K $c_S $c_C $c_A $c_K $theta_p_P $theta_p_N $theta_pc_P $theta_pc_N $Res_P $Res_N $theta_u $theta_u $D_P $D_N


##################################################################################################################
#Random generation of backbone parameters based on assigned uncertainty 
##################################################################################################################
global Sigma_IMKcol Sigma_IMKbeam; global xRandom;
if {$ConnectionType == 2} {
	set SigmaX [lindex $Sigma_IMKcol  0]; Generate_lognrmrand $K $SigmaX; 			set K 			$xRandom;
	set SigmaX [lindex $Sigma_IMKcol  1]; Generate_lognrmrand $My_P $SigmaX; 		set My_P 		$xRandom;
																					set My_N 		$xRandom;
	set SigmaX [lindex $Sigma_IMKcol  2]; Generate_lognrmrand $McMyP $SigmaX; 		set McMyP 		[expr max(1.01,$xRandom)];
																					set McMyN 		[expr max(1.01,$xRandom)];
	set SigmaX [lindex $Sigma_IMKcol  3]; Generate_lognrmrand $Res_P $SigmaX; 		set Res_P 		$xRandom;
																					set Res_N 		$xRandom;
	set SigmaX [lindex $Sigma_IMKcol  4]; Generate_lognrmrand $theta_p_P $SigmaX; 	set theta_p_P 	$xRandom;
																					set theta_p_N 	$xRandom;
	set SigmaX [lindex $Sigma_IMKcol  5]; Generate_lognrmrand $theta_pc_P $SigmaX; 	set theta_pc_P 	$xRandom;
																					set theta_pc_N 	$xRandom;
	set SigmaX [lindex $Sigma_IMKcol  6]; Generate_lognrmrand $theta_u $SigmaX; 	set theta_u 	$xRandom;
	set SigmaX [lindex $Sigma_IMKcol  7]; Generate_lognrmrand $Lmda $SigmaX; 		set Lmda 		$xRandom;
	#set SigmaX [lindex $Sigma_IMKcol  8]; Generate_lognrmrand $c $SigmaX; 			set c 			$xRandom;
}
if {$ConnectionType != 2 && $CompositeFlag == 0} {
	set SigmaX [lindex $Sigma_IMKbeam 0]; Generate_lognrmrand $K $SigmaX; 			set K 			$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 1]; Generate_lognrmrand $My_P $SigmaX; 		set My_P 		$xRandom;
																					set My_N 		$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 2]; Generate_lognrmrand $McMyP $SigmaX; 		set McMyP 		[expr max(1.01,$xRandom)];
																					set McMyN 		[expr max(1.01,$xRandom)];
	set SigmaX [lindex $Sigma_IMKbeam 3]; Generate_lognrmrand $Res_P $SigmaX; 		set Res_P 		$xRandom;
																					set Res_N 		$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 4]; Generate_lognrmrand $theta_p_P $SigmaX; 	set theta_p_P 	$xRandom;
																					set theta_p_N 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 5]; Generate_lognrmrand $theta_pc_P $SigmaX; 	set theta_pc_P 	$xRandom;
																					set theta_pc_N 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 6]; Generate_lognrmrand $theta_u $SigmaX; 	set theta_u 	$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 7]; Generate_lognrmrand $Lmda $SigmaX; 		set Lmda 		$xRandom;
	#set SigmaX [lindex $Sigma_IMKbeam 8]; Generate_lognrmrand $c $SigmaX; 			set c 			$xRandom;

} 
if {$ConnectionType != 2 && $CompositeFlag == 1} {
	set SigmaX [lindex $Sigma_IMKbeam 0]; Generate_lognrmrand $K 		  $SigmaX; 	set K 			$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 1]; Generate_lognrmrand $My_P 	  $SigmaX; 	set My_P 		$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 1]; Generate_lognrmrand $My_N 	  $SigmaX; 	set My_N 		$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 2]; Generate_lognrmrand $McMyP 	  $SigmaX; 	set McMyP 		[expr max(1.01,$xRandom)];
	set SigmaX [lindex $Sigma_IMKbeam 2]; Generate_lognrmrand $McMyN 	  $SigmaX; 	set McMyN 		[expr max(1.01,$xRandom)];
	set SigmaX [lindex $Sigma_IMKbeam 3]; Generate_lognrmrand $Res_P 	  $SigmaX; 	set Res_P 		$xRandom;
	set SigmaX [lindex $Sigma_IMKbeam 3]; Generate_lognrmrand $Res_N 	  $SigmaX; 	set Res_N 		$xRandom;
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
if {$ConnectionType == 2} {
	set L_S $Lmda; set L_C [expr 0.9*$Lmda]; set L_A $Lmda; set L_K [expr 0.9*$Lmda];
} else {
	set L_S $Lmda; set L_C 			 $Lmda;  set L_A $Lmda; set L_K 		  $Lmda;
}
	set c_S $c;    set c_C $c; 				 set c_A $c; 	set c_K $c;

# IMKBilin material model (This is the updated version of the Bilin model)
uniaxialMaterial IMKBilin $SpringID $K $theta_p_P $theta_pc_P $theta_u $My_P $McMyP $Res_P $theta_p_N $theta_pc_N $theta_u $My_N $McMyN $Res_N $L_S $L_C $L_K $c_S $c_C $c_K $D_P $D_N;

element zeroLength $SpringID $NodeI $NodeJ  -mat 99 99 $SpringID -dir 1 2 6 -doRayleigh 1;


}