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
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################


proc Spring_Gusset_FB {SpringID   NodeI   NodeJ    E  fy    tp  Lc   d_brace} {

set PI [expr 2*asin(1.0)];	# define constant pi

set Ww [expr $d_brace+2*$Lc*tan($PI*45)];  # estimate of GP depth (Whitmore width) at brace end assuming 45 cutting angle

set b 0.003; # strain hardening ratio

uniaxialMaterial Steel02 $SpringID $fy $E $b 20 0.925 0.15 0.0005 0.01 0.0005 0.01;

set secTagGP [expr $SpringID*100];

FiberGP $secTagGP $SpringID $secTagGP $E $Ww $tp   8 8;

set nInt 8

#element forceBeamColumn   $SpringID $NodeI $NodeJ  $nInt  $secTagGP  3;

set A  [expr $Ww * $tp]
set Iz [expr $tp * pow($Ww,3) / 12]
element elasticBeamColumn $SpringID $NodeI $NodeJ $A $E $Iz 3

#set integration "Lobatto"
#element dispBeamColumn $SpringID $NodeI $NodeJ $nInt $secTagGP 3;# -integration integration;

}

