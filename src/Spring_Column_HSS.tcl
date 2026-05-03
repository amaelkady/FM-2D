##################################################################################################################
# Spring_Column_HSS.tcl
#                                                                                       
# SubRoutine to construct a rotational spring representing the moment-rotation behaviour of steel HSS columns.                                                                 
#  
# The subroutine also considers modeling uncertainty based on the logarithmic standard deviations specified by the user.
#
# Reference: 
#--------------	
#
# Hartloper et al. (2026). "Component models for steel beam-columns with hollow structural sections to support the practical 
#                           seismic assessment of new and existing buildings." Earthquake Spectra: 42(2).
#
##################################################################################################################
#
# Input Arguments:
#------------------
#  SpringID  			Spring ID
#  NodeI				Node i ID
#  NodeJ				Node j ID
#  E         			Young's modulus
#  fy        			Yield stress (measured)
#  Ix        			Moment of inertia of section
#  bt        			section local slenderness ratio
#  L         			Member Length
#  My        			Effective Yield Moment
#  PgPye        		Axial load ratio due to gravity
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################


proc Spring_Column_HSS {SpringID NodeI NodeJ E fy Ix bt L My PgPye} {


set n 100.0;
set K  [expr ($n+1.0) * 6 * $E * $Ix / $L];


# Rotational capacities calculated using Hartloper et al. (2026)
set theta_p   [expr 0.0010 * pow(($bt),-2.23) * pow(($E/$fy),1.73) * pow((1-$PgPye),0.87)];
set theta_pc  [expr 0.0054 * pow(($bt),-1.22) * pow(($E/$fy),1.25) * pow((1-$PgPye),3.31)];

if {$theta_p  > 0.20} {set theta_p  0.2}
if {$theta_pc > 0.30} {set theta_pc 0.3}

if {$PgPye > 0.5} {
    set theta_p  0.001;
    set theta_pc 0.001;
}

set Lmda_S  [expr 25500 * pow(($bt),-2.00) * pow((1-$PgPye),3.02)];
set Lmda_C  [expr 1761  * pow(($bt),-2.31) * pow((1-$PgPye),4.91)];	

if {$PgPye <= 0.2} {
	set My  [expr 1.2*$My*(1-$PgPye/2)];
} else {
	set My  [expr 1.2*$My*(9/8)*(1-$PgPye)];
}

set McMy  1.2;

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
set theta_u   	0.25;

set D_P 1.0;
set D_N 1.0;

set MresMy_P 0.25;
set MresMy_N 0.25;

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
set SigmaX [lindex $Sigma_IMKcol  7]; Generate_lognrmrand $Lmda_S $SigmaX; 		set Lmda_S 		$xRandom;
set SigmaX [lindex $Sigma_IMKcol  7]; Generate_lognrmrand $Lmda_S $SigmaX; 		set Lmda_S 		$xRandom;
#set SigmaX [lindex $Sigma_IMKcol  8]; Generate_lognrmrand $c $SigmaX; 			set c 			$xRandom;

##################################################################################################################
##################################################################################################################
##################################################################################################################


# Cyclic deterioration parameters
set L_S $Lmda_S; set L_C $Lmda_C; set L_A $Lmda_S; set L_K $Lmda_S;

set c_S $c;    set c_C $c; 				 set c_A $c; 	set c_K $c;

# IMKBilin material model (This is the updated version of the older Bilin model)
uniaxialMaterial IMKBilin $SpringID $K $theta_p_P $theta_pc_P $theta_u $My_P $McMyP MresMy_P $theta_p_N $theta_pc_N $theta_u $My_N $McMyN $MresMy_N $L_S $L_C $L_K $c_S $c_C $c_K $D_P $D_N;

element zeroLength $SpringID $NodeI $NodeJ  -mat 99 99 $SpringID -dir 1 2 6 -doRayleigh 1;


}