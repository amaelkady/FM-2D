# MaxDriftTester ########################################################################
#
# Procedure that checks if the drift is maximum for Collapse
# Calls the floor displacements of the structure and checks if they exceed the drift Collapse limit
#
# Developed by Dimitrios G. Lignos, Ph.D
#
# First Created: 04/20/2010
# Last Modified: 05/06/2010
#
# #######################################################################################

proc MaxDriftTesterOriginal {numStories DriftLimit FloorNodes  h1 htyp} {

global CollapseFlag
global IterationCounter;
global nIterationsFlag; 

set CollapseFlag "NO"
set nIterationsFlag "NO"
 
set IterationCounter [expr $IterationCounter+1];
puts "******* ITERATION NUMBER $IterationCounter *******"
if  {$IterationCounter >= 3000} {
	set nIterationsFlag "YES"
	set CollapseFlag "YES"
}
	
 for {set i 0} { $i<=$numStories-1} {incr i} {
	if { $i==0 } {
	    set Node [lindex $FloorNodes $i]
		set NodeDisplI [nodeDisp $Node 1]

		set SDR [expr $NodeDisplI/$h1]
		lappend Drift [list $SDR]

    } elseif { $i > 0 } {
	    set NodeI [lindex $FloorNodes $i]
		set NodeDisplI [nodeDisp $NodeI 1]
		set NodeJ [lindex $FloorNodes [expr $i-1]]
		set NodeDisplJ [nodeDisp $NodeJ 1]
		
		set SDR [expr ($NodeDisplI - $NodeDisplJ)/$htyp]
		lappend Drift [list  $SDR]

	}
 } 
 set MAXDrift $DriftLimit

	for { set h 0 } { $h <= $numStories-1} {incr h} {
	    set TDrift [ lindex $Drift [expr $h] ]
		set TDrift [expr abs( $TDrift )]
		if { $TDrift > $MAXDrift } {
			set CollapseFlag "YES"
			puts "Collapse"
			# Addition by Ahmed Elkady 25 July 2012 for Tracing of Collapse Point
			set fileID [open CollapseState.txt w];   # Create/Open CollapseState.txt file (writing permission)
            puts -nonewline $fileID 1;               # Write value of 1 in case of collapse in CollapseState.txt file (
			close $fileID;                           # Close CollapseState.txt file
			##################
		}
	}
}