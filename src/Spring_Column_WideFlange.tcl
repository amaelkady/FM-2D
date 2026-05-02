##################################################################################################################
# Spring_Column_WideFlange.tcl
#                                                                                       
# SubRoutine to construct a rotational spring representing the moment-rotation behaviour of steel wide-flange columns.                                                                 
#  
# The subroutine also considers modeling uncertainty based on the logarithmic standard deviations specified by the user.
#
# Reference: 
#--------------	
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
#  Units				Unsed Units: 1 --> millimeters and MPa     
#								 	 2 --> inches and ksi
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################


proc Spring_Column_WideFlange {SpringID NodeI NodeJ E Fy Ix d htw bftf ry L Ls Lb My PgPye Units} {

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
if {$Lmda  > 3.0} {set Lmda  3.0}

if {$PgPye <= 0.2} {
	set My  [expr 1.15*$My*(1-$PgPye/2)];
} else {
	set My  [expr 1.15*$My*(9/8)*(1-$PgPye)];
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

set MresMy_P [expr 0.5-0.4*$PgPye];
set MresMy_N [expr 0.5-0.4*$PgPye];

set c 1.0;


set My_P     [expr  $MyPMy * $My]; 
set My_N     [expr  $MyNMy * $My];

##################################################################################################################
#Random generation of backbone parameters based on assigned uncertainty 
##################################################################################################################
global Sigma_IMKcol Sigma_IMKbeam; global xRandom;

set SigmaX [lindex $Sigma_IMKcol  0]; Generate_lognrmrand $K $SigmaX; 			set K 			$xRandom;
set SigmaX [lindex $Sigma_IMKcol  1]; Generate_lognrmrand $My_P $SigmaX; 		set My_P 		$xRandom;
																				set My_N 		$xRandom;
set SigmaX [lindex $Sigma_IMKcol  2]; Generate_lognrmrand $McMyP $SigmaX; 		set McMyP 		[expr max(1.01,$xRandom)];
																				set McMyN 		[expr max(1.01,$xRandom)];
set SigmaX [lindex $Sigma_IMKcol  3]; Generate_lognrmrand $MresMy_P $SigmaX; 	set MresMy_P 	$xRandom;
																				set MresMy_N 	$xRandom;
set SigmaX [lindex $Sigma_IMKcol  4]; Generate_lognrmrand $theta_p_P $SigmaX; 	set theta_p_P 	$xRandom;
																				set theta_p_N 	$xRandom;
set SigmaX [lindex $Sigma_IMKcol  5]; Generate_lognrmrand $theta_pc_P $SigmaX; 	set theta_pc_P 	$xRandom;
																				set theta_pc_N 	$xRandom;
set SigmaX [lindex $Sigma_IMKcol  6]; Generate_lognrmrand $theta_u $SigmaX; 	set theta_u 	$xRandom;
set SigmaX [lindex $Sigma_IMKcol  7]; Generate_lognrmrand $Lmda $SigmaX; 		set Lmda 		$xRandom;
#set SigmaX [lindex $Sigma_IMKcol  8]; Generate_lognrmrand $c $SigmaX; 			set c 			$xRandom;

##################################################################################################################
##################################################################################################################
##################################################################################################################


# Cyclic deterioration parameters
set L_S $Lmda; set L_C [expr 0.9*$Lmda]; set L_A $Lmda; set L_K [expr 0.9*$Lmda];

set c_S $c;    set c_C $c; 				 set c_A $c; 	set c_K $c;

# IMKBilin material model (This is the updated version of the older Bilin model)
uniaxialMaterial IMKBilin $SpringID $K $theta_p_P $theta_pc_P $theta_u $My_P $McMyP $MresMy_P $theta_p_N $theta_pc_N $theta_u $My_N $McMyN $MresMy_N $L_S $L_C $L_K $c_S $c_C $c_K $D_P $D_N;

element zeroLength $SpringID $NodeI $NodeJ  -mat 99 99 $SpringID -dir 1 2 6 -doRayleigh 1;


}