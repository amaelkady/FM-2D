##################################################################################################################
# FatigueMat.tcl
#
# SubRoutine to construct a Steel02 material masked with a Fatigue material to simulate ductile fracture in steel braces.
#
# References: 
#--------------	
# Karamanchi, E. and Lignos, D. G. (2014). "Computational Approach for Collapse Assessment of Concentrically Braced 
#	Frames in Seismic Regions." ASCE Journal of Structural Engineering: 140.
#
##################################################################################################################
#
# Input Arguments:
#------------------
# matID      	Material ID
# SecType     	The brace cross-section type
# 				1 --> Rectangular HSS section
#				2 --> Circular HSS section
#				3 --> Wide-flange section
# fy       		Expected yield strength
# E         	Young's modulus
# L 		  	Brace length
# ry     		Cross-section weak-axis radius of gyration
# wt    		Cross-section width-to-thickness ratio
# ht 			Cross-section height
# bt 			Cross-section width
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################

proc FatigueMat {matID SecType fy E L ry wt ht bt} {

set matFatigue [expr  $matID+1];

# Rectangular HSS Section
if {$SecType == 1} {
	set b  0.001;                               # Strain Hardening Ratio
	set R0 22.;                                 # Control the Transition from Elastic to Plastic Branches
	set cR1  0.925;                             # Recommended Values: R0=10~20, cR1=0.925, cR2=0.15
	set cR2  0.25;
	# Isotropic Hardening Parameters
	set a1 0.03;                                # a1: Increasing of compression yield envelope as proportion of yield strength after a plastic strain of $a2*($fy/E)
	set a2 1.;                                  # a2: See explanation under $a1
	set a3 0.02;                                # a3: Increasing of tension yield envelope as proportion of yield strength after a plastic strain of $a3*($fy/E)
	set a4 1.;                                  # a4: See explanation under $a4
	set m -0.300;                               # Slope of Coffin-Manson curve in log-log space
	set E0 [expr 0.291 * pow(($L/$ry),-0.484) * pow($wt,-0.613) * pow(($E/$fy),0.303)];
} 

# Round HSS Section
if {$SecType == 2} {
	set b  0.005;                               # Strain Hardening Ratio
	set R0 24.;                                 # Control the Transition from Elastic to Plastic Branches
	set cR1  0.925;                             # Recommended Values: R0=10~20, cR1=0.925, cR2=0.15
	set cR2  0.25;
	# Isotropic Hardening Parameters
	set a1 0.02;                                # a1: Increasing of compression yield envelope as proportion of yield strength after a plastic strain of $a2*($fy/E)
	set a2 1.;                                  # a2: See explanation under $a1
	set a3 0.02;                                # a3: Increasing of tension yield envelope as proportion of yield strength after a plastic strain of $a3*($fy/E)
	set a4 1.;                                  # a4: See explanation under $a4
	set m -0.300;                               # Slope of Coffin-Manson curve in log-log space
	set E0 [expr 0.748 * pow(($L/$ry),-0.399) * pow($wt,-0.628) * pow(($E/$fy),0.201)];
}

# Wide-Flange Section
if {$SecType == 3} {
	set b  0.001;                               # Strain Hardening Ratio
	set R0 20.;                                 # Control the Transition from Elastic to Plastic Branches
	set cR1  0.925;                             # Recommended Values: R0=10~20, cR1=0.925, cR2=0.15
	set cR2  0.25;
	# Isotropic Hardening Parameters
	set a1 0.02;                                # a1: Increasing of compression yield envelope as proportion of yield strength after a plastic strain of $a2*($fy/E)
	set a2 1.;                                  # a2: See explanation under $a1
	set a3 0.02;                                # a3: Increasing of tension yield envelope as proportion of yield strength after a plastic strain of $a3*($fy/E)
	set a4 1.;                                  # a4: See explanation under $a4
	set m -0.300;                               # Slope of Coffin-Manson curve in log-log space
	set E0 [expr 0.0391 * pow(($L/$ry),-0.234) * pow($bt,-0.169) * pow($ht,-0.065) * pow(($E/$fy),0.351)];
}


# Code added on April 2019 to amplify the strain value at which fatigue failure occurs IF AN ELASTIC MODEL IS BEING BUILT
if {$fy > 3000} {
	set E0 100.0;
}

uniaxialMaterial Steel02 $matID  $fy $E $b $R0 $cR1 $cR2 $a1 $a2 $a3 $a4;
uniaxialMaterial Fatigue $matFatigue $matID   -E0 $E0 -m $m; 

}