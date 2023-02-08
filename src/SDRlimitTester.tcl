# SDRlimitTester ########################################################################
#
# Procedure that checks if the Pre-Specified Collapse Drift Limit is reached and Generate 
# a Flag
#
# Developed by Dimitrios G. Lignos, Ph.D
# Modified  by Ahmed Elkady, Ph.D
#
# First Created: 04/20/2010
# Last Modified: 05/05/2020
#
# #######################################################################################

proc SDRlimitTester {numStories SDRlimit MFFloorNodes EGFFloorNodes h1 htyp TraceGFDrift} {

 global CollapseFlag
 set CollapseFlag "NO"

# set x [clock seconds];
# set RunTime [expr $x - $StartTime];
 
	 # Read the Floor Node Displacements and Deduce the Story Drift Ratio
	 for {set i 0} {$i<=$numStories-1} {incr i} {
		if { $i==0 } {
			set Node [lindex $MFFloorNodes $i]
			set NodeDisplI [nodeDisp $Node 1]
			set SDR_MF [expr $NodeDisplI/$h1]
			lappend SMFDrift [list $SDR_MF]
			
			# Addition by Ahmed Elkady 14 Dec 2016 for Tracing Drifts in EGF
			if { $TraceGFDrift == 1} {
				set Node [lindex $EGFFloorNodes $i]
				set NodeDisplI [nodeDisp $Node 1]
				set SDR_EGF [expr $NodeDisplI/$h1]
				lappend GFDrift [list $SDR_EGF]		
			}
			
		} elseif { $i > 0 } {
			set NodeI [lindex $MFFloorNodes $i]
			set NodeDisplI [nodeDisp $NodeI 1]
			set NodeJ [lindex $MFFloorNodes [expr $i-1]]
			set NodeDisplJ [nodeDisp $NodeJ 1]
			set SDR_MF [expr ($NodeDisplI - $NodeDisplJ)/$htyp]
			lappend SMFDrift [list  $SDR_MF]
			
			# Addition by Ahmed Elkady 14 Dec 2016 for Tracing Drifts in EGF
			if { $TraceGFDrift == 1} {
				set NodeI [lindex $EGFFloorNodes $i]
				set NodeDisplI [nodeDisp $NodeI 1]
				set NodeJ [lindex $EGFFloorNodes [expr $i-1]]
				set NodeDisplJ [nodeDisp $NodeJ 1]
				set SDR_EGF [expr ($NodeDisplI - $NodeDisplJ)/$htyp]
				lappend GFDrift [list  $SDR_EGF]		
			}
		}
	 } 
	 
	# Check if any Story Drift Ratio Exceeded the Drift Limit	 
	for {set i 0} {$i <= $numStories-1} {incr i} {
	    set SMFTDrift [ lindex $SMFDrift [expr $i] ]
		set SMFTDrift [expr abs($SMFTDrift)]
		
		# Addition by Ahmed Elkady 14 Dec 2016 for Tracing Drifts in EGF
		if { $TraceGFDrift == 1} {
			set GFTDrift [ lindex $GFDrift [expr $i] ]
			set GFTDrift [expr abs($GFTDrift)]
		}
		
		#set filename "CollapsedFrame.txt"
		
		# IF the Story Drift Ratio at Current Story is Less than the Drift Limit then
		# Open a file named "CollapsedFrame.txt" and write a value of "0" for no collapse
		if {$SMFTDrift < $SDRlimit && $GFTDrift < $SDRlimit} {
			set fileID2 [open CollapsedFrame.txt w];   # Create/Open CollapsedFrame.txt file (writing permission)
			puts -nonewline $fileID2 0;                # Write value of 0 in case of no collapse 
			close $fileID2;
		}
		
		# If Drift Limit was exceeded in MF
		if {$SMFTDrift > $SDRlimit} {
			puts "MF Collapse"
			set fileID2 [open CollapsedFrame.txt w];   # Create/Open CollapsedFrame.txt file (writing permission)
			puts -nonewline $fileID2 1;                # Write value of 1 in case of collapse in SMF 
			close $fileID2;   
		}
		
		# If Drift Limit was exceeded in EGF
		if {$GFTDrift > $SDRlimit} {
			puts "GF Collapse"
			set fileID2 [open CollapsedFrame.txt w];   # Create/Open CollapsedFrame.txt file (writing permission)
			puts -nonewline $fileID2 2;                # Write value of 2 in case of collapse in GF 
			close $fileID2;
		}
		
		# If Drift Limit was exceeded in both MF and EGF
		if { $SMFTDrift > $SDRlimit || $GFTDrift > $SDRlimit} {
			set CollapseFlag "YES"
			puts "Collapse"
			# Addition by Ahmed Elkady 25 July 2012 for Tracing the Collapse Point
			set fileID [open CollapseState.txt w];   # Create/Open CollapseState.txt file (writing permission)
            puts -nonewline $fileID 1;               # Write value of 1 in case of collapse in CollapseState.txt file (
			close $fileID;                           # Close CollapseState.txt file		
		}
	}
	
	
}