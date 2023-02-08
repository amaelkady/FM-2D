##################################################################################################################
# Define_Material_RC.tcl
#
# SubRoutine to create an RC uniaxial material using the Concrete04 model
#                                                      
##################################################################################################################
#
# Input Arguments:
#------------------
# matTag      	Material ID
# Ec         	Young's modulus
# fc   			Compressive strength
# type 			Confined or Unconfined
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################

proc Define_Material_RC {matTag Ec fc type} {

	set lambda 0.1;						# ratio between unloading slope at ec and initial slope $Ec
	set beta   0.1;						# parameter to define the residual stress (as a factor of $ft) at ultimate tensile strain

	if {$type == "confined"} {
	# confined concrete
		set Kfc  1.3;					# ratio of confined to unconfined concrete strength
		set Kres 0.2;					# ratio of residual/ultimate to maximum stress
		set fc   [expr -1.*$Kfc*$fc];	# Confined concrete (mander model), maximum stress
		set ec   [expr 2.*$fc/$Ec];		# strain at maximum stress (computed assuming that the secant stiffness $ec is half the initial stiffness $E) 
		set fcu  [expr $Kres*$fc];		# ultimate stress
		set ecu  [expr 20*$ec];			# strain at residual/failure stress 
		set ft 	 [expr -0.14*$fc];		# tensile strength
		set et   [expr  $ft/$Ec];		# strain at ultimate tensile stress
		set ets  [expr  $ft/0.002];		# tension softening stiffness  (absolute value) (slope of the linear tension softening branch) 
	} else {
		# unconfined concrete
		set Kres 0.2;					# ratio of residual/ultimate to maximum stress
		set fc   [expr -1.*$fc];		# Unconfined concrete (todeschini parabolic model), maximum stress
		set ec   -0.003;				# strain at maximum strength of unconfined concrete
		set fcu  [expr $Kres*$fc];		# ultimate stress
		set ecu  -0.01;					# strain at ultimate stress
		set ft 	 [expr -0.14*$fc];		# tensile strength
		set et   [expr  $ft/$Ec];		# strain at ultimate tensile stress
		set ets  [expr  $ft/0.002];		# tension softening stiffness  (absolute value) (slope of the linear tension softening branch) 
	}

	#uniaxialMaterial Concrete02 $matTag  $fc $ec $fcu $ecu $lambda $ft $ets;
	uniaxialMaterial Concrete04 $matTag  $fc $ec $ecu $Ec $ft $et $beta;

}