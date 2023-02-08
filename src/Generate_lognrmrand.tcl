##################################################################################################################
# Generate_lognrmrand.tcl
#
# SubRoutine to generate a log-normally distributed random variable for a specified mean and standard deviation.
#
##################################################################################################################
#
# Input Arguments:
#------------------
# meanX 		Mean value of the variable X
# stdlnX 		Standard deviation of the logarithmic values of the variable X 
# xRandom		The subroutine output --> random variable
#
# Written by: Dr. Ahmed Elkady, University of Southampton, UK
#
##################################################################################################################

proc Generate_lognrmrand {meanX stdlnX} {

	package require math::statistics
	global xRandom
		
	set meanlnX  [expr log($meanX)];
	set number 1;
	
	set y [::math::statistics::random-normal $meanlnX $stdlnX $number];
	
	set xRandom [expr exp($y)];

}