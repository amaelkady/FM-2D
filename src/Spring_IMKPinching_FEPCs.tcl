##################################################################################################################
# Spring_IMKPinching_FEPCs.tcl
#                                                                                       
# SubRoutine to construct a rotational spring with deteriorating pinched response representing the moment-rotation behaviour
# of flush endplate connections that are part of partially-restrained beam-to-column connections.                                                                 
#  
#
# References: 
#--------------	
# 
#     (1) Mak, L., & Elkady, A. (2021). Experimental database for steel flush end-plate connections.
#                  Journal of Structural Engineering, 147(7), 04721006.
#     (2) Elkady, A. (2022). Response characteristics of flush end-plate connections. Engineering Structures, 269, 114856.
# 	  (3) Georgiou, G., & Elkady, A. (2024). ANN-Based Model for Predicting the Nonlinear Response of Flush Endplate Connections.
#                  Journal of Structural Engineering, 150(5), 04024034. 		 
#
##################################################################################################################
#
# Input Arguments:
#------------------
#  SpringID  			Spring ID
#  NodeI				Node i ID
#  NodeJ				Node j ID
#  dt                   distance between the top bolt row and beam flange center in tension
#  g        			Bolt gauge (pitch between bolts in columns)
#  fyP        			Yield stress of endplate
#  fuP         		    Ultimate stress of endplate
#  fub        			Ultimate stress of bolts
#  fy        			Yield stress of column
#  fu         		    Ultimate stress of column
#  tep         			Thickness of endplate
#  tf        			Thickness of column flange
#  d_b        			Diameter of bolts
#  hb        		    Height of the beam
#  hc                   Height of the column
#  tw                  Thickness of column web
#  StiffenerC           Continuity plate (No.) in panel zone: 2 --> Two continuity plates in column web (upper and bottom of the panel zone) 
#                                                             1 --> One or zero continuity plate in column web (upper and bottom of the panel zone)
#  BP                   Backing plate:   1--> Designed backing plate in the connection
#  tbp                  Thickness of backing plate
#  DP                   Doubler plate:   1--> Doubler plate in one side of the panel zone
#                                        2--> Doubler plate in both sides of the panel zone
#  tdp                  Thickness of doubler plate
#
#  CompositeFlag		FLAG for Composite Action Consideration: 0 --> Ignore   Composite Effect   
# 															 	 1 --> Consider Composite Effect
#  ConnectionType		Type of Connection: 2 --> Flush endplate connections   
# 		
#
#
#  Written by:  Aran Naserpour, University of Southampton, UK
#			
##################################################################################################################


proc Spring_IMKPinching_FEPCs {SpringID NodeI NodeJ dt g fyP fuP fub fy fu tep tf d_b hb hc tw StiffenerC BP tbp DP tdp CompositeFlag ConnectionType Units} {



##################################################################################################################
# Convert Unites
##################################################################################################################

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


##################################################################################################################
# Pre-calculations
##################################################################################################################

if {$BP == 1} {

	set tf [expr ($c1*($tbp + $tf))]
}

if {$DP == 1} {

	set tw [expr ($c1*($tw + $tdp))]

} elseif {$DP == 2} {

	set tw [expr ($c1*($tw + (2.*$tdp)))]
}

##################################################################################################################
# Compute backbone parameters
##################################################################################################################
	
if {$ConnectionType == 2} {

	if {$StiffenerC != 2} {
	 
		set Ke     [expr (5.16e-3)  * pow(($c1*$dt),-0.617) * pow(($c1*$g),-0.319) * pow(($c1*$tep),0.634)  * pow($hb,2.274)  * pow($hc,0.236)  * pow($tf,0.108)  * pow($tw,-0.156)            *                            pow($d_b,0.988)]
		set My     [expr (6.20e-7)  * pow(($c1*$dt),-0.680) * pow(($c1*$g),-0.373) * pow(($c1*$tep),0.771)  * pow($hb,1.883)  * pow($tf,0.366)  * pow($d_b,0.628) * pow(($fyP*$c2*$c4),0.880)  *                            pow(($fy*$c2*$c4),0.265)]
		set Mp     [expr (6.87e-6)  * pow(($c1*$dt),-0.327) * pow(($c1*$g),-0.534) * pow(($c1*$tep),0.620)  * pow($hb,1.699)  * pow($tf,0.138)  * pow($d_b,1.187) * pow(($fyP*$c2*$c4),0.629)  *                            pow(($fy*$c2*$c4),0.161)]
		set thetaC [expr (3.5413)   * pow(($c1*$dt),-0.440) * pow(($c1*$g),-0.131) * pow(($c1*$tep),-1.019) * pow($hb,-1.867) * pow($tf,-0.283) * pow($d_b,4.171) * pow(($fyP*$c2*$c4),-0.786) * pow(($fy*$c2*$c4),0.721) * pow(($fub*$c2*$c4),0.036)]

	} else {
		
		set Ke     [expr (0.34)    * pow(($c1*$dt),-0.387) * pow(($c1*$g),-1.457)  * pow(($c1*$tep),0.874)  * pow($hb,2.545)  * pow($hc,0.023)  * pow($tf,-0.564)  * pow($tw,1.168)             *                		         pow($d_b,0.393)]
		set My     [expr (8.71e-7) * pow(($c1*$dt),-0.893) * pow(($c1*$g),-0.135)  * pow(($c1*$tep),0.860)  * pow($hb,1.660)  * pow($tf,0.293)  * pow($d_b,0.886)  * pow(($fyP*$c2*$c4),1.484)  *                  	   	     pow(($fy**$c2*$c4),-0.548)]
		set Mp     [expr (1.97e-5) * pow(($c1*$dt),0.090)  * pow(($c1*$g),-0.299)  * pow(($c1*$tep),0.674)  * pow($hb,1.053)  * pow($tf,0.414)  * pow($d_b,1.223)  * pow(($fyP*$c2*$c4),0.419)  *                   	     pow(($fy**$c2*$c4),0.196)]
		set thetaC [expr (1.38e-6) * pow(($c1*$dt),-0.090) * pow(($c1*$g),0.761)   * pow(($c1*$tep),-0.866) * pow($hb,-0.939) * pow($tf,-0.350) * pow($d_b,2.209)  * pow(($fyP*$c2*$c4),-0.829) * pow(($fy*$c2*$c4),1.102) * pow(($fub*$c2*$c4),1.072)]
	
	}
}
	set Mc         [expr 1.38*$Mp]     
	set McMye	   [expr 1.* $Mc/$Mp]
 
	set theta_e    [expr $Mp/$Ke]
	set theta_p    [expr $thetaC-$theta_e]
	
	set theta_p_P   $theta_p
	set theta_p_N   $theta_p
	set theta_pc_P   0.002
	set theta_pc_N   0.002
	set theta_u   	[expr $thetaC + 0.003]

	set D_P 1.0;
	set D_N 1.0;

	set Res_P 0.05;
	set Res_N 0.05;

	set c 1.0;

# Modification of the Units from the regression equation output units (kN and mm) to model definition Units.

if {$Units==1} {
	set Ke [expr 1000.*$Ke]
	set Mp [expr 1000.*$Mp]
} else {
    set Ke [expr 6.895*$Ke]
	set Mp [expr 6.895*$Mp]
}	


##################################################################################################################
# Pinching parameters
##################################################################################################################

	set kappaF 0.2
	set kappaD 0.2

##################################################################################################################
# Cyclic deterioration parameters
##################################################################################################################


	set Lmda [expr 10.*$Mp*$theta_p]
	set L_S $Lmda
	set L_C $Lmda
	set L_A $Lmda
	set L_K $Lmda

	set c_S $c
	set c_C $c
	set c_A $c
	set c_K $c


uniaxialMaterial IMKPinching $SpringID $Ke $theta_p_P $theta_pc_P $theta_u $Mp $McMye $Res_P $theta_p_N $theta_pc_N $theta_u $Mp $McMye $Res_N $L_S $L_C $L_A $L_K $c_S $c_C $c_A $c_K $D_P $D_N $kappaF $kappaD

element zeroLength $SpringID $NodeI $NodeJ  -mat 99 99 $SpringID -dir 1 2 6;

}