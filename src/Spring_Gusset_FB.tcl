##################################################################################################################
# Spring_Gusset_FB.tcl
#
# SubRoutine to construct a force-based beam-column element for the gusset plate (Uriz & Mahin, 2008).
#
# References: 
#--------------	
# Uriz, P. and Mahin, S. A. (2008), “Toward Earthquake- Resistant Design of Concentrically Braced Steel-Frame Structures”,
# 		PEER report 2008/08
#
##################################################################################################################
#
# Input Arguments:
#------------------
# SpringID  Spring ID
# NodeI    	Node i ID 
# NodeJ    	Node j ID 
# E        	Young's modulus
# fy       	Expected yield strength
# tp       	Gusset plate thickness
# Lc	   	Brace-to-Gusset connection length
# d_brace  	Brace Depth/Height/Diameter
# matTag   	Material ID
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################


proc Spring_Gusset_FB {SpringID   NodeI   NodeJ    E  fy    tp  Lc   d_brace  matTag} {

set PI [expr 2*asin(1.0)];	# define constant pi

set dp [expr $d_brace+2*$Lc*tan($PI*45)];  # estimate of GP depth at brace end assuming 45 cutting angle

set b 0.003; # strain hardening ratio

uniaxialMaterial Steel02 $matTag $fy $E $b 20 0.925 0.15 0.0005 0.01 0.0005 0.01;

set secTagGP [expr $matTag*100];

FiberGP $secTagGP $matTag $secTagGP $E $dp $tp   8 8;

element forceBeamColumn   $SpringID $NodeI $NodeJ  3  $secTagGP  3;

}

