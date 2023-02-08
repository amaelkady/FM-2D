##################################################################################################################
# Spring_Gusset.tcl
#
# SubRoutine to construct a rotational spring with a bilinear repsonse for the gusset plate.
#
# References: 
#--------------	
# Hsiao, P-C., Lehman, D. E. and Roeder, C. W. (2013). "A Model to Simulate Special Concentrically Braced Frames 
# 	Beyond Brace Fracture." Earthquake Eng. & Structural Dynamics 42(2).
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
# Lb	   	Gusset plate average buckling length
# tp       	Gusset plate thickness
# Lc	   	Brace-to-Gusset connection length
# d_Brace  	Brace Depth/Height/Diameter
# matTag   	Material ID
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################


proc Spring_Gusset {SpringID   NodeI   NodeJ    E  fy   Lb   tp   Lc   d_Brace   matTag} {

set pi [expr 2.0*asin(1.0)];							# Definition of Pi
set Ww [expr $d_Brace + 2. * $Lc];  					# Whitmore Width
set I  [expr $Ww * $tp * $tp * $tp / 12.];  			# Moment of Inertia 
set Z  [expr $Ww * $tp * $tp / 6.]; 					# Plastic Modulus 
set My [expr $Z * $fy];          						# Plastic Moment 
set Krot [expr $E * $I / $Lb]; 							# Flexural Stiffness
set b 0.01;

uniaxialMaterial Steel02 $matTag $My $Krot $b 20 0.925 0.15 0.0005 0.01 0.0005 0.01;

element zeroLength $SpringID $NodeI $NodeJ  -mat 99 99 $matTag -dir 1 2 6 -doRayleigh 1;;

}

