##################################################################################################################
# Spring_IMK+RC.tcl
#                                                                                       
# SubRoutine to construct a rotational spring representing the moment-rotation behaviour of an RC beam-column                                                                   
#
# References: 
#--------------	
# Panagiotakos, T. B. and Fardis, M. N. (2001). “Deformations of Reinforced Concrete at Yielding and
#		Ultimate,” ACI Structural Journal, Vol. 98, No. 2, March-April 2001, pp. 135-147.
#
# Haselton, C.B., A.B. Liel, S. T. Lange, and G.G. Deierlein (2008).  "Beam-Column Element Model Calibrated for 
#		Predicting Flexural Response Leading to Global Collapse of RC Frame Buildings", PEER Report 2007/03, 
#		Pacific Engineering Research Center, University of California, Berkeley, California.
#
##################################################################################################################
#
# Input Arguments:
#------------------
# SpringID  Spring ID
# NodeI		Node i ID
# NodeJ		Node j ID
# Ec        Young's modulus of concrete
# fc 		Concrete compressive strength - cylinder
# Ec        Young's modulus of steel rebar
# fy        Yield stress
# b         Section width
# h         Section depth
# d1        Section cover (extreme fiber to reinforcement center)
# s 		Stirrup spacing.
# rho_T 	Area ratio of longitudinal bottom reinforcement (tension)
# rho_C 	Area ratio of longitudinal top reinforcement (compression)
# rho_I 	Area ratio of longitudinal middle reinforcement
# rho_sh 	Area ratio of transverse reinforcement in the plastic hinge region spacing
# a_sl 		Bond-slip indicator at the end of your element (= 1 where bond-slip is possible; typical case  and = 0 if bond-slip is not possible).  Note that bond-slip is important and accounts for 35% of the plastic rotation capacity.
# PPc 		Axial load ratio
# Units		Units: 1 --> mm and MPa     
#				   2 --> inches and ksi
#
# lambda    Normalized energy dissipation capacity; it is important to note that this is a normalized value
#			defined by the total energy dissipation capacity of Et = λMyθy. When creating an element
#			model, the input value must be adjusted if an initial stiffness other then EIy/EIg is used.
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################


proc Spring_IMK_RC {SpringID NodeI NodeJ fc Ec fy Es b h d1 s rho_C rho_T rho_I rho_SH a_sl PPc Units} {

###################################################################
# Pre-calculation parameters
###################################################################

set n 10.0;

if {$Units == 1} {
	set c_unit 1.0;
} else {
	set c_unit 6.895;
}

set d 		[expr $h-$d1];
set delta1  [expr $d1/$d];
set P       [expr $PPc*$b*$d*$fc];
set n       [expr $Es/$Ec];
set esy     [expr $fy/$Es];
set ecu     0.003;
set area_T  [expr $rho_T*$b*$d];
set area_C  [expr $rho_C*$b*$d];

###################################################################
# Compute My as per Panagiotakos and Fardis (2001) 
###################################################################

if {$fc < [expr  7.6 / $c_unit]} {
    set beta1 0.85;
} elseif {$fc > [expr 55.17 / $c_unit]} {
    set beta1 0.65;
} else {
    set beta1 [expr 1.05-0.05*($fc/$c_unit/6.9)];
}

set c  [expr ($area_T*$fy - $area_C*$fy + $P)/(0.85*$fc*$beta1*$b)];
set cb [expr ($ecu*$d)/($ecu+$esy)]; # depth of compression block at balanced

if {$c<$cb} {
    set A		[expr $rho_T + $rho_C 		    +     $rho_I + ($P/$b/$d/$fy)];
    set B		[expr $rho_T + $rho_C * $delta1 + 0.5*$rho_I*(1 + $delta1) +($P/$b/$d/$fy)];
    set ky      [expr pow(($n*$n*$A*$A+2*$n*$B),0.5) - $n*$A];
    set curv_y  [expr $fy/$Es/(1 - $ky)/$d];
} else {
	set A		[expr $rho_T + $rho_C+$rho_I - ($P/1.8/$n/$b/$d/$fc)];
	set B		[expr $rho_T + $rho_C*$delta1 + 0.5*$rho_I*(1 + $delta1)];
    set ky      [expr pow(($n*$n*$A*$A+2*$n*$B),0.5) - $n*$A];
    set curv_y  [expr 1.8 * $fc/($Ec*$d*$ky)];
}

set term1	[expr $Ec*pow($ky,2)/2*(0.5*(1 + $delta1) - $ky/3)];
set term2	[expr $Es/2*((1 - $ky)*$rho_T+($ky-$delta1)*$rho_C+$rho_I/6*(1 - $delta1))*(1 - $delta1)];

set My		[expr  $b * pow($d,3)*$curv_y*($term1+$term2)];

###################################################################
# Compute backbone parameters as per Haselton et al (2008)
###################################################################

set theta_p  	[expr 0.13 * (1. + 0.55*$a_sl)  * pow(0.130, $PPc) * pow((0.02 + 40*$rho_SH),0.65) * pow(0.57,(0.01*$c_unit*$fc))];
set theta_pc 	[expr 0.76 			    		* pow(0.031, $PPc) * pow((0.02 + 40*$rho_SH),1.02)]; if {$theta_pc  > 0.10} {set theta_pc  0.1};
set theta_p_tot [expr 0.14 * (1. + 0.40*$a_sl) 	* pow(0.190, $PPc) * pow((0.02 + 40*$rho_SH),0.54) * pow(0.62,(0.01*$c_unit*$fc))];
set theta_y  	[expr $theta_p_tot - $theta_p];
set theta_u  	[expr $theta_p_tot + $theta_pc];
set McMy     	[expr 1.25 	 				* pow(0.890,$PPc) 								* pow(0.91,(0.01*$c_unit*$fc))];
set lambda   	[expr 170.7	 				* pow(0.270,$PPc) * pow(0.10,$s/$d)];
set Et   	 	[expr $lambda * $My * $theta_y];
set Ke   	 	[expr ($n+1.0) * $My / $theta_y];
#set lambda   [expr 127.2	 			* pow(0.190,$PPc) * pow(0.24,$s/$d) * pow(0.595,$VpVn) * pow(4.25,$rho_sh_eff)];
set MresMy      	0.01;

uniaxialMaterial IMKPeakOriented $SpringID $Ke $theta_p $theta_pc $theta_u $My $McMy $MresMy $theta_p $theta_pc $theta_u $My $McMy $MresMy $lambda $lambda $lambda $lambda 1 1 1 1 1 1;
element zeroLength $SpringID $NodeI $NodeJ  -mat 99 99 $SpringID -dir 1 2 6;

}