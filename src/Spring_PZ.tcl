##################################################################################################################
# Spring_PZ.tcl
#
# SubRoutine to construct a rotational spring with a trilinear hysteretic response representative of steel 
# panel zone response                                                            
#  
# The subroutine also considers modeling uncertainty based on the logarithmic standard deviations specified by the user.
#      
# References: 
#--------------	
# Elkady, A. and D. G. Lignos (2014). "Modeling of the Composite Action in Fully Restrained Beam-to-Column
# 	Connections: ‎Implications in the Seismic Design and Collapse Capacity of Steel Special Moment Frames." 
# 	Earthquake Eng. & Structural Dynamics 43(13).
#
# Skiadopoulos, A., Elkady, A. and D. G. Lignos (2020). "Proposed Panel Zone Model for Seismic Design of 
#   Steel Moment-Resisting Frames." ASCE Journal of Structural Engineering (under review). 
#
##################################################################################################################
#
# Input Arguments:                                                                               
#------------------
# P_Elm			Element ID
# NodeI			Node i ID
# NodeJ			Node j ID
# E				Young's Modulus
# mu			Poisson's Ratio
# fy			Expected Yield Stress
# tdp			Doubler Plate(s) Thickness
# d_Col			Column Depth
# d_Beam		Beam Depth
# tf_Col		Column Flange Thickness
# bf_Col		Column Flange Width
# tw_Col		Column Web Thickness
# Ic			Column second-moment-of-interia about the strong axis
# trib			Steel deck rib depth
# ts			Concrete slab depth above the rib
# Response_ID	ID for Panel Zone Response: 0 --> Interior Steel Panel Zone with Composite Action
#											1 --> Exterior Steel Panel Zone with Composite Action
#											2 --> Bare Steel Interior/Exterior Steel Panel Zone
# transfTag		Geometric Transformation ID
#                                                                                                      
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
# 
########################################################################################################


proc Spring_PZ {P_Elm NodeI NodeJ E mu fy  tw_Col tdp d_Col d_Beam tf_Col bf_Col Ix_Col trib ts Response_ID transfTag} {
 
 set tpz [expr $tw_Col + $tdp]; # total PZ thickness
 
 set G [expr $E/(2.0 * (1.0 + $mu))];     # Shear Modulus

 # Beam's effective depth
 if {$Response_ID==2} {
 	set d_BeamP $d_Beam;
} else {
 	set d_BeamP [expr $d_Beam + $trib + 0.5 * $ts]; # Effective Depth in Positive Moment
 }
 set d_BeamN $d_Beam; 							 # Effective Depth in Negative Moment
 
 # Stiffness Calculation
 set Ks [expr $tpz * ($d_Col - $tf_Col) * $G];   														# PZ Stiffness: Shear Contribution
 set Kb [expr 12 * $E * ($Ix_Col + $tdp * pow(($d_Col - 2*$tf_Col),3)/12.) /pow($d_Beam,3) * $d_Beam];  # PZ Stiffness: Bending Contribution
 set Ke [expr ($Ks * $Kb) / ($Ks + $Kb)];   															# PZ Stiffness: Total
 
 set Ksf [expr 2 * ($bf_Col * $tf_Col) * $G];   										# Flange Stiffness: Shear Contribution
 set Kbf [expr 2 * 12 * $E * $bf_Col * pow($tf_Col,3)/12. /pow($d_Beam,3) * $d_Beam];   # Flange Stiffness: Bending Contribution
 set Kef [expr ($Ksf * $Kbf) / ($Ksf + $Kbf)];   										# Flange Stiffness: Total

 set ay [expr (0.58 * $Kef / $Ke  + 0.88) / (1 - $Kef / $Ke)];

 set aw_eff_4gamma 1.10;
 set aw_eff_6gamma 1.15;

 set af_eff_4gamma [expr 0.93 * $Kef / $Ke  + 0.015];
 set af_eff_6gamma [expr 1.05 * $Kef / $Ke  + 0.020];
 
 set Vy 		[expr 0.577 * $fy *  $ay			* ($d_Col - $tf_Col) * $tpz];  													   # Yield Shear Force
 set Vp_4gamma 	[expr 0.577 * $fy * ($aw_eff_4gamma * ($d_Col - $tf_Col) * $tpz + $af_eff_4gamma * ($bf_Col - $tw_Col) * 2*$tf_Col)];  # Plastic Shear Force @ 4 gammaY
 set Vp_6gamma 	[expr 0.577 * $fy * ($aw_eff_6gamma * ($d_Col - $tf_Col) * $tpz + $af_eff_6gamma * ($bf_Col - $tw_Col) * 2*$tf_Col)];  # Plastic Shear Force @ 6 gammaY

##################################################################################################################
# Random generation of backbone parameters based on assigned uncertainty 
##################################################################################################################
global Sigma_PZ; global xRandom;
set SigmaX [lindex $Sigma_PZ 0]; Generate_lognrmrand $Ke 		$SigmaX; 	set Ke 			$xRandom;
set SigmaX [lindex $Sigma_PZ 1]; Generate_lognrmrand $Vy 		$SigmaX; 	set Vy 			$xRandom;
set SigmaX [lindex $Sigma_PZ 2]; Generate_lognrmrand $Vp_4gamma $SigmaX; 	set Vp_4gamma 	[expr max(1.01*$Vy,$xRandom)];
set SigmaX [lindex $Sigma_PZ 3]; Generate_lognrmrand $Vp_6gamma $SigmaX; 	set Vp_6gamma 	[expr max(1.01*$Vp_4gamma,$xRandom)];
##################################################################################################################
##################################################################################################################

 set gamma_y  [expr $Vy/$Ke]; 
 set gamma4_y [expr 4.0 * $gamma_y];  
 set gamma6_y [expr 6.0 * $gamma_y];

 set My_P 		 [expr $Vy 	   	  * $d_BeamP];
 set Mp_4gamma_P [expr $Vp_4gamma * $d_BeamP];
 set Mp_6gamma_P [expr $Vp_6gamma * $d_BeamP];

 set My_N 		 [expr $Vy 	   	  * $d_BeamN];
 set Mp_4gamma_N [expr $Vp_4gamma * $d_BeamN];
 set Mp_6gamma_N [expr $Vp_6gamma * $d_BeamN];
 
 set Slope_4to6gamma_y_P [expr ($Mp_6gamma_P - $Mp_4gamma_P) / (2 * $gamma_y) ];
 set Slope_4to6gamma_y_N [expr ($Mp_6gamma_N - $Mp_4gamma_N) / (2 * $gamma_y) ];

 # Defining the 3 Points used to construct the trilinear backbone curve
 set gamma1 $gamma_y; 
 set gamma2 $gamma4_y;  
 set gamma3 [expr 100 * $gamma_y];
 
 set M1_P [expr $My_P];
 set M2_P [expr $Mp_4gamma_P];
 set M3_P [expr $Mp_4gamma_P + $Slope_4to6gamma_y_P * (100 * $gamma_y - $gamma4_y)];
 
 set M1_N [expr $My_N];
 set M2_N [expr $Mp_4gamma_N];
 set M3_N [expr $Mp_4gamma_N + $Slope_4to6gamma_y_N * (100 * $gamma_y - $gamma4_y)];
 
 set gammaU_P   0.3;
 set gammaU_N  -0.3;

 set Dummy_ID [expr   12 * $P_Elm]; 
 
 # Hysteretic Material without pinching and damage
 # uniaxialMaterial Hysteretic $matTag $s1p $e1p $s2p $e2p <$s3p $e3p> $s1n $e1n $s2n $e2n <$s3n $e3n> $pinchX $pinchY $damage1 $damage2

 # Composite Interior Steel Panel Zone
 if { $Response_ID == 0.0 } {
	 uniaxialMaterial Hysteretic $Dummy_ID  $M1_P $gamma1  $M2_P $gamma2 $M3_P $gamma3 [expr -$M1_P] [expr -$gamma1] [expr -$M2_P] [expr -$gamma2] [expr -$M3_P] [expr -$gamma3] 0.25 0.75 0. 0. 0.;
	 uniaxialMaterial MinMax 	 $P_Elm $Dummy_ID -min $gammaU_N -max $gammaU_P;
 }
 
 # Composite Exterior Steel Panel Zone
 if { $Response_ID == 1.0 } {
	 uniaxialMaterial Hysteretic $Dummy_ID  $M1_P $gamma1  $M2_P $gamma2 $M3_P $gamma3 [expr -$M1_N] [expr -$gamma1] [expr -$M2_N] [expr -$gamma2] [expr -$M3_N] [expr -$gamma3] 0.25 0.75 0. 0. 0.;
	 uniaxialMaterial MinMax 	 $P_Elm $Dummy_ID -min $gammaU_N -max $gammaU_P;
 }
 
 # Bare Steel Interior/Exterior Steel Panel Zone
 if { $Response_ID == 2.0 } {
	 uniaxialMaterial Hysteretic $Dummy_ID  $M1_N $gamma1  $M2_N $gamma2 $M3_N $gamma3 [expr -$M1_N] [expr -$gamma1] [expr -$M2_N] [expr -$gamma2] [expr -$M3_N] [expr -$gamma3] 0.25 0.75 0. 0. 0.;
	 uniaxialMaterial MinMax 	 $P_Elm $Dummy_ID -min $gammaU_N -max $gammaU_P;
 } 
 
 element zeroLength $P_Elm $NodeI $NodeJ -mat $P_Elm -dir 6;
 
}