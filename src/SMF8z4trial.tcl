####################################################################################################
####################################################################################################
#                                        8-story MRF Building
####################################################################################################
####################################################################################################

# CLEAR ALL;
wipe all;

# BUILD MODEL (2D - 3 DOF/node)
model basic -ndm 2 -ndf 3

####################################################################################################
#                                        BASIC MODEL VARIABLES                                     #
####################################################################################################

set  global RunTime;
set  global StartTime;
set  global MaxRunTime;
set  MaxRunTime [expr 10.0000 * 60.];
set  StartTime [clock seconds];
set  RunTime 0.0;
set  EQ 0;
set  PO 0;
set  ELF 0;
set  Composite 0;
set  ShowAnimation 0;
set  MainDir {C:\Dropbox\Under Development\FM-2D};
set  RFpath {C:\Users\ahmed\Downloads};
set  MainFolder {C:\Users\ahmed\Downloads\Results};
set  ModePO 1;
set  DriftPO 0.100000;
set  DampModeI 1;
set  DampModeJ 3;
set  zeta 0.020000;

####################################################################################################
#                                       SOURCING SUBROUTINES                                       #
####################################################################################################

source DisplayModel3D.tcl;
source DisplayPlane.tcl;
source Spring_PZ.tcl;
source Spring_IMK.tcl;
source Spring_Zero.tcl;
source Spring_Rigid.tcl;
source Spring_Pinching.tcl;
source ConstructPanel_Rectangle.tcl;
source DynamicAnalysisCollapseSolverX.tcl;
source Generate_lognrmrand.tcl;

####################################################################################################
#                                          Create Results Folders                                  #
####################################################################################################

# RESULT FOLDER
set SubFolder  $GMname;
cd $RFpath;
file mkdir "Results";
cd "Results"
file mkdir $SubFolder;
cd $MainDir;

####################################################################################################
#                                              INPUT                                               #
####################################################################################################

# FRAME CENTERLINE DIMENSIONS
set NStory  8;
set NBay  3;

# MATERIAL PROPERTIES
set E  210.000; 
set mu  0.300; 
set fy  [expr 0.345 *   1.0];

# BASIC MATERIALS
uniaxialMaterial Elastic  9  1.e-9; 		#Flexible Material 
uniaxialMaterial Elastic  99 1000000000.;  #Rigid Material 
uniaxialMaterial UVCuniaxial  666 210.0000 0.3450 0.1241 10.0000 0.0000 1.0000 2 24.1317 180.0000 2.3787 10.0000; #Voce-Chaboche Material

# GEOMETRIC TRANSFORMATIONS IDs
geomTransf Linear 		 1;
geomTransf PDelta 		 2;
geomTransf Corotational 3;
set trans_Linear 	1;
set trans_PDelta 	2;
set trans_Corot  	3;
set trans_selected  2;

# STIFF ELEMENTS PROPERTY
set A_Stiff 1000000.0;
set I_Stiff 10000000000.0;

# COMPOSITE BEAM FACTOR
set Composite 0;
set Comp_I    1.400;
set Comp_I_GC 1.400;

# FIBER ELEMENT PROPERTIES
set nSegments    8;
set initialGI    0.00100;
set nIntegration 5;

# LOGARITHMIC STANDARD DEVIATIONS (FOR UNCERTAINTY CONSIDERATION)
global Sigma_IMKcol Sigma_IMKbeam Sigma_Pinching4 Sigma_PZ; 
set Sigma_IMKcol [list  1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 ];
set Sigma_IMKbeam   [list  1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 ];
set Sigma_Pinching4 [list  1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 ];
set Sigma_PZ        [list  1.e-9 1.e-9 1.e-9 1.e-9 ];
set Sigma_fy     1.e-9;
set Sigma_zeta   1.e-9;
global Sigma_fy Sigma_fyB Sigma_fyG Sigma_GI; global xRandom;
set SigmaX $Sigma_fy;  Generate_lognrmrand $fy 	$SigmaX; 	set fy      $xRandom;

####################################################################################################
#                                          PRE-CALCULATIONS                                        #
####################################################################################################

# REDUCED BEAM SECTION CONNECTION DISTANCE FROM COLUMN
set L_RBS9  [expr  0.100 * 190.40 +  0.000 * 457.00/2.];
set L_RBS8  [expr  0.100 * 190.40 +  0.000 * 457.00/2.];
set L_RBS7  [expr  0.100 * 190.40 +  0.000 * 457.00/2.];
set L_RBS6  [expr  0.100 * 190.40 +  0.000 * 457.00/2.];
set L_RBS5  [expr  0.100 * 209.30 +  0.000 * 533.10/2.];
set L_RBS4  [expr  0.100 * 209.30 +  0.000 * 533.10/2.];
set L_RBS3  [expr  0.100 * 209.30 +  0.000 * 533.10/2.];
set L_RBS2  [expr  0.100 * 209.30 +  0.000 * 533.10/2.];

# FRAME GRID LINES
set Floor9  32292.00;
set Floor8  28332.00;
set Floor7  24372.00;
set Floor6  20412.00;
set Floor5  16452.00;
set Floor4  12492.00;
set Floor3  8532.00;
set Floor2  4572.00;
set Floor1 0.0;

set Axis1 0.0;
set Axis2 6000.00;
set Axis3 12000.00;
set Axis4 18000.00;
set Axis5 24000.00;
set Axis6 30000.00;

set HBuilding 32292.00;
set WFrame 18000.00;
variable HBuilding 32292.00;

####################################################################################################
#                                                  NODES                                           #
####################################################################################################

# COMMAND SYNTAX 
# node $NodeID  $X-Coordinate  $Y-Coordinate;

#SUPPORT NODES
node 110   $Axis1  $Floor1; node 120   $Axis2  $Floor1; node 130   $Axis3  $Floor1; node 140   $Axis4  $Floor1; node 150   $Axis5  $Floor1; node 160   $Axis6  $Floor1; 

# EGF COLUMN GRID NODES
node 950   $Axis5  $Floor9; node 960   $Axis6  $Floor9; 
node 850   $Axis5  $Floor8; node 860   $Axis6  $Floor8; 
node 750   $Axis5  $Floor7; node 760   $Axis6  $Floor7; 
node 650   $Axis5  $Floor6; node 660   $Axis6  $Floor6; 
node 550   $Axis5  $Floor5; node 560   $Axis6  $Floor5; 
node 450   $Axis5  $Floor4; node 460   $Axis6  $Floor4; 
node 350   $Axis5  $Floor3; node 360   $Axis6  $Floor3; 
node 250   $Axis5  $Floor2; node 260   $Axis6  $Floor2; 

# EGF COLUMN NODES
node 951  $Axis5  $Floor9; node 961  $Axis6  $Floor9; 
node 853  $Axis5  $Floor8; node 863  $Axis6  $Floor8; 
node 851  $Axis5  $Floor8; node 861  $Axis6  $Floor8; 
node 753  $Axis5  $Floor7; node 763  $Axis6  $Floor7; 
node 751  $Axis5  $Floor7; node 761  $Axis6  $Floor7; 
node 653  $Axis5  $Floor6; node 663  $Axis6  $Floor6; 
node 651  $Axis5  $Floor6; node 661  $Axis6  $Floor6; 
node 553  $Axis5  $Floor5; node 563  $Axis6  $Floor5; 
node 551  $Axis5  $Floor5; node 561  $Axis6  $Floor5; 
node 453  $Axis5  $Floor4; node 463  $Axis6  $Floor4; 
node 451  $Axis5  $Floor4; node 461  $Axis6  $Floor4; 
node 353  $Axis5  $Floor3; node 363  $Axis6  $Floor3; 
node 351  $Axis5  $Floor3; node 361  $Axis6  $Floor3; 
node 253  $Axis5  $Floor2; node 263  $Axis6  $Floor2; 
node 251  $Axis5  $Floor2; node 261  $Axis6  $Floor2; 
node 153  $Axis5  $Floor1; node 163  $Axis6  $Floor1; 

# EGF BEAM NODES
node 954  $Axis5  $Floor9; node 962  $Axis6  $Floor9; 
node 854  $Axis5  $Floor8; node 862  $Axis6  $Floor8; 
node 754  $Axis5  $Floor7; node 762  $Axis6  $Floor7; 
node 654  $Axis5  $Floor6; node 662  $Axis6  $Floor6; 
node 554  $Axis5  $Floor5; node 562  $Axis6  $Floor5; 
node 454  $Axis5  $Floor4; node 462  $Axis6  $Floor4; 
node 354  $Axis5  $Floor3; node 362  $Axis6  $Floor3; 
node 254  $Axis5  $Floor2; node 262  $Axis6  $Floor2; 

# MF COLUMN NODES
node 911  $Axis1 [expr $Floor9 - 457.00/2]; node 921  $Axis2 [expr $Floor9 - 457.00/2]; node 931  $Axis3 [expr $Floor9 - 457.00/2]; node 941  $Axis4 [expr $Floor9 - 457.00/2]; 
node 813  $Axis1 [expr $Floor8 + 457.00/2]; node 823  $Axis2 [expr $Floor8 + 457.00/2]; node 833  $Axis3 [expr $Floor8 + 457.00/2]; node 843  $Axis4 [expr $Floor8 + 457.00/2]; 
node 811  $Axis1 [expr $Floor8 - 457.00/2]; node 821  $Axis2 [expr $Floor8 - 457.00/2]; node 831  $Axis3 [expr $Floor8 - 457.00/2]; node 841  $Axis4 [expr $Floor8 - 457.00/2]; 
node 713  $Axis1 [expr $Floor7 + 457.00/2]; node 723  $Axis2 [expr $Floor7 + 457.00/2]; node 733  $Axis3 [expr $Floor7 + 457.00/2]; node 743  $Axis4 [expr $Floor7 + 457.00/2]; 
node 711  $Axis1 [expr $Floor7 - 457.00/2]; node 721  $Axis2 [expr $Floor7 - 457.00/2]; node 731  $Axis3 [expr $Floor7 - 457.00/2]; node 741  $Axis4 [expr $Floor7 - 457.00/2]; 
node 613  $Axis1 [expr $Floor6 + 457.00/2]; node 623  $Axis2 [expr $Floor6 + 457.00/2]; node 633  $Axis3 [expr $Floor6 + 457.00/2]; node 643  $Axis4 [expr $Floor6 + 457.00/2]; 
node 611  $Axis1 [expr $Floor6 - 457.00/2]; node 621  $Axis2 [expr $Floor6 - 457.00/2]; node 631  $Axis3 [expr $Floor6 - 457.00/2]; node 641  $Axis4 [expr $Floor6 - 457.00/2]; 
node 513  $Axis1 [expr $Floor5 + 533.10/2]; node 523  $Axis2 [expr $Floor5 + 533.10/2]; node 533  $Axis3 [expr $Floor5 + 533.10/2]; node 543  $Axis4 [expr $Floor5 + 533.10/2]; 
node 511  $Axis1 [expr $Floor5 - 533.10/2]; node 521  $Axis2 [expr $Floor5 - 533.10/2]; node 531  $Axis3 [expr $Floor5 - 533.10/2]; node 541  $Axis4 [expr $Floor5 - 533.10/2]; 
node 413  $Axis1 [expr $Floor4 + 533.10/2]; node 423  $Axis2 [expr $Floor4 + 533.10/2]; node 433  $Axis3 [expr $Floor4 + 533.10/2]; node 443  $Axis4 [expr $Floor4 + 533.10/2]; 
node 411  $Axis1 [expr $Floor4 - 533.10/2]; node 421  $Axis2 [expr $Floor4 - 533.10/2]; node 431  $Axis3 [expr $Floor4 - 533.10/2]; node 441  $Axis4 [expr $Floor4 - 533.10/2]; 
node 313  $Axis1 [expr $Floor3 + 533.10/2]; node 323  $Axis2 [expr $Floor3 + 533.10/2]; node 333  $Axis3 [expr $Floor3 + 533.10/2]; node 343  $Axis4 [expr $Floor3 + 533.10/2]; 
node 311  $Axis1 [expr $Floor3 - 533.10/2]; node 321  $Axis2 [expr $Floor3 - 533.10/2]; node 331  $Axis3 [expr $Floor3 - 533.10/2]; node 341  $Axis4 [expr $Floor3 - 533.10/2]; 
node 213  $Axis1 [expr $Floor2 + 533.10/2]; node 223  $Axis2 [expr $Floor2 + 533.10/2]; node 233  $Axis3 [expr $Floor2 + 533.10/2]; node 243  $Axis4 [expr $Floor2 + 533.10/2]; 
node 211  $Axis1 [expr $Floor2 - 533.10/2]; node 221  $Axis2 [expr $Floor2 - 533.10/2]; node 231  $Axis3 [expr $Floor2 - 533.10/2]; node 241  $Axis4 [expr $Floor2 - 533.10/2]; 
node 113  $Axis1 $Floor1; node 123  $Axis2 $Floor1; node 133  $Axis3 $Floor1; node 143  $Axis4 $Floor1; 

# MF BEAM NODES
node 914   [expr $Axis1 + $L_RBS9 + 355.60/2] $Floor9; node 922   [expr $Axis2 - $L_RBS9 - 355.60/2] $Floor9; node 924   [expr $Axis2 + $L_RBS9 + 355.60/2] $Floor9; node 932   [expr $Axis3 - $L_RBS9 - 355.60/2] $Floor9; node 934   [expr $Axis3 + $L_RBS9 + 355.60/2] $Floor9; node 942   [expr $Axis4 - $L_RBS9 - 355.60/2] $Floor9; 
node 814   [expr $Axis1 + $L_RBS8 + 362.00/2] $Floor8; node 822   [expr $Axis2 - $L_RBS8 - 362.00/2] $Floor8; node 824   [expr $Axis2 + $L_RBS8 + 362.00/2] $Floor8; node 832   [expr $Axis3 - $L_RBS8 - 362.00/2] $Floor8; node 834   [expr $Axis3 + $L_RBS8 + 362.00/2] $Floor8; node 842   [expr $Axis4 - $L_RBS8 - 362.00/2] $Floor8; 
node 714   [expr $Axis1 + $L_RBS7 + 362.00/2] $Floor7; node 722   [expr $Axis2 - $L_RBS7 - 362.00/2] $Floor7; node 724   [expr $Axis2 + $L_RBS7 + 362.00/2] $Floor7; node 732   [expr $Axis3 - $L_RBS7 - 362.00/2] $Floor7; node 734   [expr $Axis3 + $L_RBS7 + 362.00/2] $Floor7; node 742   [expr $Axis4 - $L_RBS7 - 362.00/2] $Floor7; 
node 614   [expr $Axis1 + $L_RBS6 + 368.20/2] $Floor6; node 622   [expr $Axis2 - $L_RBS6 - 368.20/2] $Floor6; node 624   [expr $Axis2 + $L_RBS6 + 368.20/2] $Floor6; node 632   [expr $Axis3 - $L_RBS6 - 368.20/2] $Floor6; node 634   [expr $Axis3 + $L_RBS6 + 368.20/2] $Floor6; node 642   [expr $Axis4 - $L_RBS6 - 368.20/2] $Floor6; 
node 514   [expr $Axis1 + $L_RBS5 + 368.20/2] $Floor5; node 522   [expr $Axis2 - $L_RBS5 - 368.20/2] $Floor5; node 524   [expr $Axis2 + $L_RBS5 + 368.20/2] $Floor5; node 532   [expr $Axis3 - $L_RBS5 - 368.20/2] $Floor5; node 534   [expr $Axis3 + $L_RBS5 + 368.20/2] $Floor5; node 542   [expr $Axis4 - $L_RBS5 - 368.20/2] $Floor5; 
node 414   [expr $Axis1 + $L_RBS4 + 381.00/2] $Floor4; node 422   [expr $Axis2 - $L_RBS4 - 381.00/2] $Floor4; node 424   [expr $Axis2 + $L_RBS4 + 381.00/2] $Floor4; node 432   [expr $Axis3 - $L_RBS4 - 381.00/2] $Floor4; node 434   [expr $Axis3 + $L_RBS4 + 381.00/2] $Floor4; node 442   [expr $Axis4 - $L_RBS4 - 381.00/2] $Floor4; 
node 314   [expr $Axis1 + $L_RBS3 + 381.00/2] $Floor3; node 322   [expr $Axis2 - $L_RBS3 - 381.00/2] $Floor3; node 324   [expr $Axis2 + $L_RBS3 + 381.00/2] $Floor3; node 332   [expr $Axis3 - $L_RBS3 - 381.00/2] $Floor3; node 334   [expr $Axis3 + $L_RBS3 + 381.00/2] $Floor3; node 342   [expr $Axis4 - $L_RBS3 - 381.00/2] $Floor3; 
node 214   [expr $Axis1 + $L_RBS2 + 381.00/2] $Floor2; node 222   [expr $Axis2 - $L_RBS2 - 381.00/2] $Floor2; node 224   [expr $Axis2 + $L_RBS2 + 381.00/2] $Floor2; node 232   [expr $Axis3 - $L_RBS2 - 381.00/2] $Floor2; node 234   [expr $Axis3 + $L_RBS2 + 381.00/2] $Floor2; node 242   [expr $Axis4 - $L_RBS2 - 381.00/2] $Floor2; 

# BEAM SPRING NODES
node 9140   [expr $Axis1 + $L_RBS9 + 355.60/2] $Floor9; node 9220   [expr $Axis2 - $L_RBS9 - 355.60/2] $Floor9; node 9240   [expr $Axis2 + $L_RBS9 + 355.60/2] $Floor9; node 9320   [expr $Axis3 - $L_RBS9 - 355.60/2] $Floor9; node 9340   [expr $Axis3 + $L_RBS9 + 355.60/2] $Floor9; node 9420   [expr $Axis4 - $L_RBS9 - 355.60/2] $Floor9; 
node 8140   [expr $Axis1 + $L_RBS8 + 362.00/2] $Floor8; node 8220   [expr $Axis2 - $L_RBS8 - 362.00/2] $Floor8; node 8240   [expr $Axis2 + $L_RBS8 + 362.00/2] $Floor8; node 8320   [expr $Axis3 - $L_RBS8 - 362.00/2] $Floor8; node 8340   [expr $Axis3 + $L_RBS8 + 362.00/2] $Floor8; node 8420   [expr $Axis4 - $L_RBS8 - 362.00/2] $Floor8; 
node 7140   [expr $Axis1 + $L_RBS7 + 362.00/2] $Floor7; node 7220   [expr $Axis2 - $L_RBS7 - 362.00/2] $Floor7; node 7240   [expr $Axis2 + $L_RBS7 + 362.00/2] $Floor7; node 7320   [expr $Axis3 - $L_RBS7 - 362.00/2] $Floor7; node 7340   [expr $Axis3 + $L_RBS7 + 362.00/2] $Floor7; node 7420   [expr $Axis4 - $L_RBS7 - 362.00/2] $Floor7; 
node 6140   [expr $Axis1 + $L_RBS6 + 368.20/2] $Floor6; node 6220   [expr $Axis2 - $L_RBS6 - 368.20/2] $Floor6; node 6240   [expr $Axis2 + $L_RBS6 + 368.20/2] $Floor6; node 6320   [expr $Axis3 - $L_RBS6 - 368.20/2] $Floor6; node 6340   [expr $Axis3 + $L_RBS6 + 368.20/2] $Floor6; node 6420   [expr $Axis4 - $L_RBS6 - 368.20/2] $Floor6; 
node 5140   [expr $Axis1 + $L_RBS5 + 368.20/2] $Floor5; node 5220   [expr $Axis2 - $L_RBS5 - 368.20/2] $Floor5; node 5240   [expr $Axis2 + $L_RBS5 + 368.20/2] $Floor5; node 5320   [expr $Axis3 - $L_RBS5 - 368.20/2] $Floor5; node 5340   [expr $Axis3 + $L_RBS5 + 368.20/2] $Floor5; node 5420   [expr $Axis4 - $L_RBS5 - 368.20/2] $Floor5; 
node 4140   [expr $Axis1 + $L_RBS4 + 381.00/2] $Floor4; node 4220   [expr $Axis2 - $L_RBS4 - 381.00/2] $Floor4; node 4240   [expr $Axis2 + $L_RBS4 + 381.00/2] $Floor4; node 4320   [expr $Axis3 - $L_RBS4 - 381.00/2] $Floor4; node 4340   [expr $Axis3 + $L_RBS4 + 381.00/2] $Floor4; node 4420   [expr $Axis4 - $L_RBS4 - 381.00/2] $Floor4; 
node 3140   [expr $Axis1 + $L_RBS3 + 381.00/2] $Floor3; node 3220   [expr $Axis2 - $L_RBS3 - 381.00/2] $Floor3; node 3240   [expr $Axis2 + $L_RBS3 + 381.00/2] $Floor3; node 3320   [expr $Axis3 - $L_RBS3 - 381.00/2] $Floor3; node 3340   [expr $Axis3 + $L_RBS3 + 381.00/2] $Floor3; node 3420   [expr $Axis4 - $L_RBS3 - 381.00/2] $Floor3; 
node 2140   [expr $Axis1 + $L_RBS2 + 381.00/2] $Floor2; node 2220   [expr $Axis2 - $L_RBS2 - 381.00/2] $Floor2; node 2240   [expr $Axis2 + $L_RBS2 + 381.00/2] $Floor2; node 2320   [expr $Axis3 - $L_RBS2 - 381.00/2] $Floor2; node 2340   [expr $Axis3 + $L_RBS2 + 381.00/2] $Floor2; node 2420   [expr $Axis4 - $L_RBS2 - 381.00/2] $Floor2; 

# COLUMN SPLICE NODES
node 107172 $Axis1 [expr ($Floor7 + 0.50 * 3960)]; node 107272 $Axis2 [expr ($Floor7 + 0.50 * 3960)]; node 107372 $Axis3 [expr ($Floor7 + 0.50 * 3960)]; node 107472 $Axis4 [expr ($Floor7 + 0.50 * 3960)]; node 107572 $Axis5 [expr ($Floor7 + 0.50 * 3960)]; node 107672 $Axis6 [expr ($Floor7 + 0.50 * 3960)]; 
node 107171 $Axis1 [expr ($Floor7 + 0.50 * 3960)]; node 107271 $Axis2 [expr ($Floor7 + 0.50 * 3960)]; node 107371 $Axis3 [expr ($Floor7 + 0.50 * 3960)]; node 107471 $Axis4 [expr ($Floor7 + 0.50 * 3960)]; node 107571 $Axis5 [expr ($Floor7 + 0.50 * 3960)]; node 107671 $Axis6 [expr ($Floor7 + 0.50 * 3960)]; 
node 105172 $Axis1 [expr ($Floor5 + 0.50 * 3960)]; node 105272 $Axis2 [expr ($Floor5 + 0.50 * 3960)]; node 105372 $Axis3 [expr ($Floor5 + 0.50 * 3960)]; node 105472 $Axis4 [expr ($Floor5 + 0.50 * 3960)]; node 105572 $Axis5 [expr ($Floor5 + 0.50 * 3960)]; node 105672 $Axis6 [expr ($Floor5 + 0.50 * 3960)]; 
node 105171 $Axis1 [expr ($Floor5 + 0.50 * 3960)]; node 105271 $Axis2 [expr ($Floor5 + 0.50 * 3960)]; node 105371 $Axis3 [expr ($Floor5 + 0.50 * 3960)]; node 105471 $Axis4 [expr ($Floor5 + 0.50 * 3960)]; node 105571 $Axis5 [expr ($Floor5 + 0.50 * 3960)]; node 105671 $Axis6 [expr ($Floor5 + 0.50 * 3960)]; 
node 103172 $Axis1 [expr ($Floor3 + 0.50 * 3960)]; node 103272 $Axis2 [expr ($Floor3 + 0.50 * 3960)]; node 103372 $Axis3 [expr ($Floor3 + 0.50 * 3960)]; node 103472 $Axis4 [expr ($Floor3 + 0.50 * 3960)]; node 103572 $Axis5 [expr ($Floor3 + 0.50 * 3960)]; node 103672 $Axis6 [expr ($Floor3 + 0.50 * 3960)]; 
node 103171 $Axis1 [expr ($Floor3 + 0.50 * 3960)]; node 103271 $Axis2 [expr ($Floor3 + 0.50 * 3960)]; node 103371 $Axis3 [expr ($Floor3 + 0.50 * 3960)]; node 103471 $Axis4 [expr ($Floor3 + 0.50 * 3960)]; node 103571 $Axis5 [expr ($Floor3 + 0.50 * 3960)]; node 103671 $Axis6 [expr ($Floor3 + 0.50 * 3960)]; 

###################################################################################################
#                                  PANEL ZONE NODES & ELEMENTS                                    #
###################################################################################################

# PANEL ZONE NODES AND ELASTIC ELEMENTS
# Command Syntax; 
# ConstructPanel_Rectangle Axis Floor X_Axis Y_Floor E A_Panel I_Panel d_Col d_Beam transfTag 
ConstructPanel_Rectangle  1 9 $Axis1 $Floor9 $E $A_Stiff $I_Stiff 355.60 457.00 $trans_selected; ConstructPanel_Rectangle  2 9 $Axis2 $Floor9 $E $A_Stiff $I_Stiff 355.60 457.00 $trans_selected; ConstructPanel_Rectangle  3 9 $Axis3 $Floor9 $E $A_Stiff $I_Stiff 355.60 457.00 $trans_selected; ConstructPanel_Rectangle  4 9 $Axis4 $Floor9 $E $A_Stiff $I_Stiff 355.60 457.00 $trans_selected; 
ConstructPanel_Rectangle  1 8 $Axis1 $Floor8 $E $A_Stiff $I_Stiff 362.00 457.00 $trans_selected; ConstructPanel_Rectangle  2 8 $Axis2 $Floor8 $E $A_Stiff $I_Stiff 362.00 457.00 $trans_selected; ConstructPanel_Rectangle  3 8 $Axis3 $Floor8 $E $A_Stiff $I_Stiff 362.00 457.00 $trans_selected; ConstructPanel_Rectangle  4 8 $Axis4 $Floor8 $E $A_Stiff $I_Stiff 362.00 457.00 $trans_selected; 
ConstructPanel_Rectangle  1 7 $Axis1 $Floor7 $E $A_Stiff $I_Stiff 362.00 457.00 $trans_selected; ConstructPanel_Rectangle  2 7 $Axis2 $Floor7 $E $A_Stiff $I_Stiff 362.00 457.00 $trans_selected; ConstructPanel_Rectangle  3 7 $Axis3 $Floor7 $E $A_Stiff $I_Stiff 362.00 457.00 $trans_selected; ConstructPanel_Rectangle  4 7 $Axis4 $Floor7 $E $A_Stiff $I_Stiff 362.00 457.00 $trans_selected; 
ConstructPanel_Rectangle  1 6 $Axis1 $Floor6 $E $A_Stiff $I_Stiff 368.20 457.00 $trans_selected; ConstructPanel_Rectangle  2 6 $Axis2 $Floor6 $E $A_Stiff $I_Stiff 368.20 457.00 $trans_selected; ConstructPanel_Rectangle  3 6 $Axis3 $Floor6 $E $A_Stiff $I_Stiff 368.20 457.00 $trans_selected; ConstructPanel_Rectangle  4 6 $Axis4 $Floor6 $E $A_Stiff $I_Stiff 368.20 457.00 $trans_selected; 
ConstructPanel_Rectangle  1 5 $Axis1 $Floor5 $E $A_Stiff $I_Stiff 368.20 533.10 $trans_selected; ConstructPanel_Rectangle  2 5 $Axis2 $Floor5 $E $A_Stiff $I_Stiff 368.20 533.10 $trans_selected; ConstructPanel_Rectangle  3 5 $Axis3 $Floor5 $E $A_Stiff $I_Stiff 368.20 533.10 $trans_selected; ConstructPanel_Rectangle  4 5 $Axis4 $Floor5 $E $A_Stiff $I_Stiff 368.20 533.10 $trans_selected; 
ConstructPanel_Rectangle  1 4 $Axis1 $Floor4 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; ConstructPanel_Rectangle  2 4 $Axis2 $Floor4 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; ConstructPanel_Rectangle  3 4 $Axis3 $Floor4 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; ConstructPanel_Rectangle  4 4 $Axis4 $Floor4 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; 
ConstructPanel_Rectangle  1 3 $Axis1 $Floor3 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; ConstructPanel_Rectangle  2 3 $Axis2 $Floor3 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; ConstructPanel_Rectangle  3 3 $Axis3 $Floor3 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; ConstructPanel_Rectangle  4 3 $Axis4 $Floor3 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; 
ConstructPanel_Rectangle  1 2 $Axis1 $Floor2 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; ConstructPanel_Rectangle  2 2 $Axis2 $Floor2 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; ConstructPanel_Rectangle  3 2 $Axis3 $Floor2 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; ConstructPanel_Rectangle  4 2 $Axis4 $Floor2 $E $A_Stiff $I_Stiff 381.00 533.10 $trans_selected; 

####################################################################################################
#                                          PANEL ZONE SPRINGS                                      #
####################################################################################################

# COMMAND SYNTAX 
# Spring_PZ    Element_ID Node_i Node_j E mu fy tw_Col tdp d_Col d_Beam tf_Col bf_Col Ic trib ts Response_ID transfTag
Spring_PZ    909100 409109 409110 $E $mu [expr $fy *   1.0] 10.40   0.00 355.60 457.00 17.50 368.60 402500000.00 88.900 101.600 2 1; Spring_PZ    909200 409209 409210 $E $mu [expr $fy *   1.0] 10.40   0.00 355.60 457.00 17.50 368.60 402500000.00 88.900 101.600 2 1; Spring_PZ    909300 409309 409310 $E $mu [expr $fy *   1.0] 10.40   0.00 355.60 457.00 17.50 368.60 402500000.00 88.900 101.600 2 1; Spring_PZ    909400 409409 409410 $E $mu [expr $fy *   1.0] 10.40   0.00 355.60 457.00 17.50 368.60 402500000.00 88.900 101.600 2 1; 
Spring_PZ    908100 408109 408110 $E $mu [expr $fy *   1.0] 10.40   0.00 355.60 457.00 17.50 368.60 402500000.00 88.900 101.600 2 1; Spring_PZ    908200 408209 408210 $E $mu [expr $fy *   1.0] 10.40   0.00 355.60 457.00 17.50 368.60 402500000.00 88.900 101.600 2 1; Spring_PZ    908300 408309 408310 $E $mu [expr $fy *   1.0] 10.40   0.00 355.60 457.00 17.50 368.60 402500000.00 88.900 101.600 2 1; Spring_PZ    908400 408409 408410 $E $mu [expr $fy *   1.0] 10.40   0.00 355.60 457.00 17.50 368.60 402500000.00 88.900 101.600 2 1; 
Spring_PZ    907100 407109 407110 $E $mu [expr $fy *   1.0] 12.30   0.00 362.00 457.00 20.70 370.50 485900000.00 88.900 101.600 2 1; Spring_PZ    907200 407209 407210 $E $mu [expr $fy *   1.0] 12.30   0.00 362.00 457.00 20.70 370.50 485900000.00 88.900 101.600 2 1; Spring_PZ    907300 407309 407310 $E $mu [expr $fy *   1.0] 12.30   0.00 362.00 457.00 20.70 370.50 485900000.00 88.900 101.600 2 1; Spring_PZ    907400 407409 407410 $E $mu [expr $fy *   1.0] 12.30   0.00 362.00 457.00 20.70 370.50 485900000.00 88.900 101.600 2 1; 
Spring_PZ    906100 406109 406110 $E $mu [expr $fy *   1.0] 12.30   0.00 362.00 457.00 20.70 370.50 485900000.00 88.900 101.600 2 1; Spring_PZ    906200 406209 406210 $E $mu [expr $fy *   1.0] 12.30   0.00 362.00 457.00 20.70 370.50 485900000.00 88.900 101.600 2 1; Spring_PZ    906300 406309 406310 $E $mu [expr $fy *   1.0] 12.30   0.00 362.00 457.00 20.70 370.50 485900000.00 88.900 101.600 2 1; Spring_PZ    906400 406409 406410 $E $mu [expr $fy *   1.0] 12.30   0.00 362.00 457.00 20.70 370.50 485900000.00 88.900 101.600 2 1; 
Spring_PZ    905100 405109 405110 $E $mu [expr $fy *   1.0] 14.40   0.00 368.20 533.10 23.80 372.60 571200000.00 88.900 101.600 2 1; Spring_PZ    905200 405209 405210 $E $mu [expr $fy *   1.0] 14.40   0.00 368.20 533.10 23.80 372.60 571200000.00 88.900 101.600 2 1; Spring_PZ    905300 405309 405310 $E $mu [expr $fy *   1.0] 14.40   0.00 368.20 533.10 23.80 372.60 571200000.00 88.900 101.600 2 1; Spring_PZ    905400 405409 405410 $E $mu [expr $fy *   1.0] 14.40   0.00 368.20 533.10 23.80 372.60 571200000.00 88.900 101.600 2 1; 
Spring_PZ    904100 404109 404110 $E $mu [expr $fy *   1.0] 14.40   0.00 368.20 533.10 23.80 372.60 571200000.00 88.900 101.600 2 1; Spring_PZ    904200 404209 404210 $E $mu [expr $fy *   1.0] 14.40   0.00 368.20 533.10 23.80 372.60 571200000.00 88.900 101.600 2 1; Spring_PZ    904300 404309 404310 $E $mu [expr $fy *   1.0] 14.40   0.00 368.20 533.10 23.80 372.60 571200000.00 88.900 101.600 2 1; Spring_PZ    904400 404409 404410 $E $mu [expr $fy *   1.0] 14.40   0.00 368.20 533.10 23.80 372.60 571200000.00 88.900 101.600 2 1; 
Spring_PZ    903100 403109 403110 $E $mu [expr $fy *   1.0] 18.40   0.00 381.00 533.10 30.20 394.80 790800000.00 88.900 101.600 2 1; Spring_PZ    903200 403209 403210 $E $mu [expr $fy *   1.0] 18.40   0.00 381.00 533.10 30.20 394.80 790800000.00 88.900 101.600 2 1; Spring_PZ    903300 403309 403310 $E $mu [expr $fy *   1.0] 18.40   0.00 381.00 533.10 30.20 394.80 790800000.00 88.900 101.600 2 1; Spring_PZ    903400 403409 403410 $E $mu [expr $fy *   1.0] 18.40   0.00 381.00 533.10 30.20 394.80 790800000.00 88.900 101.600 2 1; 
Spring_PZ    902100 402109 402110 $E $mu [expr $fy *   1.0] 18.40   0.00 381.00 533.10 30.20 394.80 790800000.00 88.900 101.600 2 1; Spring_PZ    902200 402209 402210 $E $mu [expr $fy *   1.0] 18.40   0.00 381.00 533.10 30.20 394.80 790800000.00 88.900 101.600 2 1; Spring_PZ    902300 402309 402310 $E $mu [expr $fy *   1.0] 18.40   0.00 381.00 533.10 30.20 394.80 790800000.00 88.900 101.600 2 1; Spring_PZ    902400 402409 402410 $E $mu [expr $fy *   1.0] 18.40   0.00 381.00 533.10 30.20 394.80 790800000.00 88.900 101.600 2 1; 

####################################################################################################
#                                     ELASTIC COLUMNS AND BEAMS                                    #
####################################################################################################

# COMMAND SYNTAX 
# element ModElasticBeam2d $ElementID $iNode $jNode $Area $E $Ix $K11 $K33 $K44 $transformation 

# STIFFNESS MODIFIERS
set n 10.;
set K44_2 [expr 6*(1+$n)/(2+3*$n)];
set K11_2 [expr (1+2*$n)*$K44_2/(1+$n)];
set K33_2 [expr (1+2*$n)*$K44_2/(1+$n)];
set K44_1 [expr 6*$n/(1+3*$n)];
set K11_1 [expr (1+2*$n)*$K44_1/(1+$n)];
set K33_1 [expr 2*$K44_1];

# COLUMNS
element ModElasticBeam2d   608100      813      911  16430.0000 $E [expr ($n+1)/$n*402500000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   608200      823      921  16430.0000 $E [expr ($n+1)/$n*402500000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   608300      833      931  16430.0000 $E [expr ($n+1)/$n*402500000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   608400      843      941  16430.0000 $E [expr ($n+1)/$n*402500000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   607102   107172      811 16430.0000 $E [expr ($n+1)/$n*402500000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   607202   107272      821 16430.0000 $E [expr ($n+1)/$n*402500000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   607302   107372      831 16430.0000 $E [expr ($n+1)/$n*402500000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   607402   107472      841 16430.0000 $E [expr ($n+1)/$n*402500000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  
element ModElasticBeam2d   607101      713   107171 19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   607201      723   107271 19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   607301      733   107371 19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   607401      743   107471 19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  
element ModElasticBeam2d   606100      613      711  19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   606200      623      721  19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   606300      633      731  19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   606400      643      741  19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   605102   105172      611 19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   605202   105272      621 19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   605302   105372      631 19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   605402   105472      641 19480.0000 $E [expr ($n+1)/$n*485900000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  
element ModElasticBeam2d   605101      513   105171 22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   605201      523   105271 22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   605301      533   105371 22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   605401      543   105471 22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  
element ModElasticBeam2d   604100      413      511  22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   604200      423      521  22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   604300      433      531  22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   604400      443      541  22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   603102   103172      411 22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   603202   103272      421 22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   603302   103372      431 22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   603402   103472      441 22550.0000 $E [expr ($n+1)/$n*571200000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  
element ModElasticBeam2d   603101      313   103171 29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   603201      323   103271 29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   603301      333   103371 29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  element ModElasticBeam2d   603401      343   103471 29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K33_1 $K11_1 $K44_1 $trans_selected;  
element ModElasticBeam2d   602100      213      311  29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   602200      223      321  29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   602300      233      331  29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   602400      243      341  29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   601100      113      211  29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   601200      123      221  29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   601300      133      231  29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   601400      143      241  29900.0000 $E [expr ($n+1)/$n*790800000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 

# BEAMS
element ModElasticBeam2d   509100      914      922  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   509200      924      932  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   509300      934      942  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   508100      814      822  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   508200      824      832  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   508300      834      842  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   507100      714      722  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   507200      724      732  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   507300      734      742  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   506100      614      622  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   506200      624      632  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   506300      634      642  9460.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*333200000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   505100      514      522  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   505200      524      532  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   505300      534      542  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   504100      414      422  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   504200      424      432  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   504300      434      442  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   503100      314      322  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   503200      324      332  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   503300      334      342  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d   502100      214      222  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   502200      224      232  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d   502300      234      242  11740.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*552300000.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 

####################################################################################################
#                                      ELASTIC RBS ELEMENTS                                        #
####################################################################################################

element elasticBeamColumn 509104 409104 9140 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 509202 409202 9220 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 509204 409204 9240 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 509302 409302 9320 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 509304 409304 9340 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 509402 409402 9420 9460.000 $E [expr $Comp_I*333200000.000] 1; 
element elasticBeamColumn 508104 408104 8140 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 508202 408202 8220 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 508204 408204 8240 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 508302 408302 8320 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 508304 408304 8340 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 508402 408402 8420 9460.000 $E [expr $Comp_I*333200000.000] 1; 
element elasticBeamColumn 507104 407104 7140 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 507202 407202 7220 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 507204 407204 7240 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 507302 407302 7320 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 507304 407304 7340 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 507402 407402 7420 9460.000 $E [expr $Comp_I*333200000.000] 1; 
element elasticBeamColumn 506104 406104 6140 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 506202 406202 6220 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 506204 406204 6240 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 506302 406302 6320 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 506304 406304 6340 9460.000 $E [expr $Comp_I*333200000.000] 1; element elasticBeamColumn 506402 406402 6420 9460.000 $E [expr $Comp_I*333200000.000] 1; 
element elasticBeamColumn 505104 405104 5140 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 505202 405202 5220 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 505204 405204 5240 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 505302 405302 5320 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 505304 405304 5340 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 505402 405402 5420 11740.000 $E [expr $Comp_I*552300000.000] 1; 
element elasticBeamColumn 504104 404104 4140 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 504202 404202 4220 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 504204 404204 4240 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 504302 404302 4320 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 504304 404304 4340 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 504402 404402 4420 11740.000 $E [expr $Comp_I*552300000.000] 1; 
element elasticBeamColumn 503104 403104 3140 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 503202 403202 3220 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 503204 403204 3240 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 503302 403302 3320 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 503304 403304 3340 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 503402 403402 3420 11740.000 $E [expr $Comp_I*552300000.000] 1; 
element elasticBeamColumn 502104 402104 2140 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 502202 402202 2220 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 502204 402204 2240 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 502302 402302 2320 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 502304 402304 2340 11740.000 $E [expr $Comp_I*552300000.000] 1; element elasticBeamColumn 502402 402402 2420 11740.000 $E [expr $Comp_I*552300000.000] 1; 

###################################################################################################
#                                           MF BEAM SPRINGS                                       #
###################################################################################################

# Command Syntax 
# Spring_IMK SpringID iNode jNode E fy Ix d htw bftf ry L Ls Lb My PgPye CompositeFLAG MFconnection Units; 

Spring_IMK 909104 914 9140 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; Spring_IMK 909202 9220 922 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; Spring_IMK 909204 924 9240 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; Spring_IMK 909302 9320 932 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; Spring_IMK 909304 934 9340 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; Spring_IMK 909402 9420 942 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; 
Spring_IMK 908104 814 8140 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; Spring_IMK 908202 8220 822 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; Spring_IMK 908204 824 8240 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; Spring_IMK 908302 8320 832 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; Spring_IMK 908304 834 8340 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; Spring_IMK 908402 8420 842 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5606.320 2803.160 2822.200 620033.931 0.0 $Composite 1 1; 
Spring_IMK 907104 714 7140 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; Spring_IMK 907202 7220 722 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; Spring_IMK 907204 724 7240 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; Spring_IMK 907302 7320 732 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; Spring_IMK 907304 734 7340 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; Spring_IMK 907402 7420 742 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; 
Spring_IMK 906104 614 6140 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; Spring_IMK 906202 6220 622 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; Spring_IMK 906204 624 6240 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; Spring_IMK 906302 6320 632 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; Spring_IMK 906304 634 6340 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; Spring_IMK 906402 6420 642 $E $fy [expr $Comp_I*333200000.000] 457.000 45.333 6.566 42.000 5599.920 2799.960 2819.000 620033.931 0.0 $Composite 1 1; 
Spring_IMK 905104 514 5140 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; Spring_IMK 905202 5220 522 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; Spring_IMK 905204 524 5240 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; Spring_IMK 905302 5320 532 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; Spring_IMK 905304 534 5340 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; Spring_IMK 905402 5420 542 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; 
Spring_IMK 904104 414 4140 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; Spring_IMK 904202 4220 422 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; Spring_IMK 904204 424 4240 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; Spring_IMK 904302 4320 432 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; Spring_IMK 904304 434 4340 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; Spring_IMK 904402 4420 442 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5589.940 2794.970 2815.900 882616.628 0.0 $Composite 1 1; 
Spring_IMK 903104 314 3140 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; Spring_IMK 903202 3220 322 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; Spring_IMK 903204 324 3240 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; Spring_IMK 903302 3320 332 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; Spring_IMK 903304 334 3340 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; Spring_IMK 903402 3420 342 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; 
Spring_IMK 902104 214 2140 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; Spring_IMK 902202 2220 222 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; Spring_IMK 902204 224 2240 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; Spring_IMK 902302 2320 232 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; Spring_IMK 902304 234 2340 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; Spring_IMK 902402 2420 242 $E $fy [expr $Comp_I*552300000.000] 533.100 47.119 6.708 45.100 5577.140 2788.570 2809.500 882616.628 0.0 $Composite 1 1; 

###################################################################################################
#                                           MF COLUMN SPRINGS                                     #
###################################################################################################

Spring_IMK  909101  409101     911 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.0759  0 0 1; Spring_IMK  909201  409201     921 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.0759  0 0 1; Spring_IMK  909301  409301     931 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.0759  0 0 1; Spring_IMK  909401  409401     941 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.0759  0 0 1; 
Spring_IMK  908103  408103     813 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.0759  0 0 1; Spring_IMK  908203  408203     823 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.0759  0 0 1; Spring_IMK  908303  408303     833 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.0759  0 0 1; Spring_IMK  908403  408403     843 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.0759  0 0 1; 
Spring_IMK  908101  408101     811 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.1588  0 0 1; Spring_IMK  908201  408201     821 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.1588  0 0 1; Spring_IMK  908301  408301     831 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.1588  0 0 1; Spring_IMK  908401  408401     841 $E $fy 402500000.0000 355.6000 27.8846 10.5314 94.3000 3503.0000 1751.5000 3503.0000 940780.5000 0.1588  0 0 1; 
Spring_IMK  907103  407103     713 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.1340  0 0 1; Spring_IMK  907203  407203     723 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.1340  0 0 1; Spring_IMK  907303  407303     733 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.1340  0 0 1; Spring_IMK  907403  407403     743 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.1340  0 0 1; 
Spring_IMK  907101  407101     711 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2039  0 0 1; Spring_IMK  907201  407201     721 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2039  0 0 1; Spring_IMK  907301  407301     731 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2039  0 0 1; Spring_IMK  907401  407401     741 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2039  0 0 1; 
Spring_IMK  906103  406103     613 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2039  0 0 1; Spring_IMK  906203  406203     623 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2039  0 0 1; Spring_IMK  906303  406303     633 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2039  0 0 1; Spring_IMK  906403  406403     643 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2039  0 0 1; 
Spring_IMK  906101  406101     611 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2738  0 0 1; Spring_IMK  906201  406201     621 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2738  0 0 1; Spring_IMK  906301  406301     631 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2738  0 0 1; Spring_IMK  906401  406401     641 $E $fy 485900000.0000 362.0000 23.5772 8.9493 94.9000 3503.0000 1751.5000 3503.0000 1125217.5000 0.2738  0 0 1; 
Spring_IMK  905103  405103     513 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3464.9500 1732.4750 3464.9500 1311172.5000 0.2365  0 0 1; Spring_IMK  905203  405203     523 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3464.9500 1732.4750 3464.9500 1311172.5000 0.2365  0 0 1; Spring_IMK  905303  405303     533 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3464.9500 1732.4750 3464.9500 1311172.5000 0.2365  0 0 1; Spring_IMK  905403  405403     543 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3464.9500 1732.4750 3464.9500 1311172.5000 0.2365  0 0 1; 
Spring_IMK  905101  405101     511 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.2970  0 0 1; Spring_IMK  905201  405201     521 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.2970  0 0 1; Spring_IMK  905301  405301     531 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.2970  0 0 1; Spring_IMK  905401  405401     541 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.2970  0 0 1; 
Spring_IMK  904103  404103     413 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.2970  0 0 1; Spring_IMK  904203  404203     423 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.2970  0 0 1; Spring_IMK  904303  404303     433 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.2970  0 0 1; Spring_IMK  904403  404403     443 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.2970  0 0 1; 
Spring_IMK  904101  404101     411 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.3574  0 0 1; Spring_IMK  904201  404201     421 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.3574  0 0 1; Spring_IMK  904301  404301     431 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.3574  0 0 1; Spring_IMK  904401  404401     441 $E $fy 571200000.0000 368.2000 20.1389 7.8277 95.4000 3426.9000 1713.4500 3426.9000 1311172.5000 0.3574  0 0 1; 
Spring_IMK  903103  403103     313 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.2695  0 0 1; Spring_IMK  903203  403203     323 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.2695  0 0 1; Spring_IMK  903303  403303     333 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.2695  0 0 1; Spring_IMK  903403  403403     343 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.2695  0 0 1; 
Spring_IMK  903101  403101     311 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.3151  0 0 1; Spring_IMK  903201  403201     321 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.3151  0 0 1; Spring_IMK  903301  403301     331 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.3151  0 0 1; Spring_IMK  903401  403401     341 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.3151  0 0 1; 
Spring_IMK  902103  402103     213 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.3151  0 0 1; Spring_IMK  902203  402203     223 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.3151  0 0 1; Spring_IMK  902303  402303     233 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.3151  0 0 1; Spring_IMK  902403  402403     243 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 3426.9000 1713.4500 3426.9000 1778716.5000 0.3151  0 0 1; 
Spring_IMK  902101  402101     211 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 4305.4500 2152.7250 4305.4500 1778716.5000 0.3612  0 0 1; Spring_IMK  902201  402201     221 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 4305.4500 2152.7250 4305.4500 1778716.5000 0.3612  0 0 1; Spring_IMK  902301  402301     231 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 4305.4500 2152.7250 4305.4500 1778716.5000 0.3612  0 0 1; Spring_IMK  902401  402401     241 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 4305.4500 2152.7250 4305.4500 1778716.5000 0.3612  0 0 1; 
Spring_IMK  901103     110     113 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 4305.4500 2152.7250 4305.4500 1778716.5000 0.3612  0 0 1; Spring_IMK  901203     120     123 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 4305.4500 2152.7250 4305.4500 1778716.5000 0.3612  0 0 1; Spring_IMK  901303     130     133 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 4305.4500 2152.7250 4305.4500 1778716.5000 0.3612  0 0 1; Spring_IMK  901403     140     143 $E $fy 790800000.0000 381.0000 15.7609 6.5364 102.0000 4305.4500 2152.7250 4305.4500 1778716.5000 0.3612  0 0 1; 

###################################################################################################
#                                          COLUMN SPLICE SPRINGS                                  #
###################################################################################################

Spring_Rigid 907107 107171 107172; 
Spring_Rigid 907207 107271 107272; 
Spring_Rigid 907307 107371 107372; 
Spring_Rigid 907407 107471 107472; 
Spring_Rigid 907507 107571 107572; 
Spring_Rigid 907607 107671 107672; 
Spring_Rigid 905107 105171 105172; 
Spring_Rigid 905207 105271 105272; 
Spring_Rigid 905307 105371 105372; 
Spring_Rigid 905407 105471 105472; 
Spring_Rigid 905507 105571 105572; 
Spring_Rigid 905607 105671 105672; 
Spring_Rigid 903107 103171 103172; 
Spring_Rigid 903207 103271 103272; 
Spring_Rigid 903307 103371 103372; 
Spring_Rigid 903407 103471 103472; 
Spring_Rigid 903507 103571 103572; 
Spring_Rigid 903607 103671 103672; 

####################################################################################################
#                                              FLOOR LINKS                                         #
####################################################################################################

# Command Syntax 
# element truss $ElementID $iNode $jNode $Area $matID
element truss 1009 409404 950 $A_Stiff 99;
element truss 1008 408404 850 $A_Stiff 99;
element truss 1007 407404 750 $A_Stiff 99;
element truss 1006 406404 650 $A_Stiff 99;
element truss 1005 405404 550 $A_Stiff 99;
element truss 1004 404404 450 $A_Stiff 99;
element truss 1003 403404 350 $A_Stiff 99;
element truss 1002 402404 250 $A_Stiff 99;

####################################################################################################
#                                          EGF COLUMNS AND BEAMS                                   #
####################################################################################################

# GRAVITY COLUMNS
element elasticBeamColumn  608500     853     951 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  608600     863     961 100000.0000 $E 100000000.0000 $trans_PDelta; 
element elasticBeamColumn  607502  107572     851 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  607602  107672     861 100000.0000 $E 100000000.0000 $trans_PDelta; 
element elasticBeamColumn  607501     753  107571 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  607601     763  107671 100000.0000 $E 100000000.0000 $trans_PDelta; 
element elasticBeamColumn  606500     653     751 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  606600     663     761 100000.0000 $E 100000000.0000 $trans_PDelta; 
element elasticBeamColumn  605502  105572     651 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  605602  105672     661 100000.0000 $E 100000000.0000 $trans_PDelta; 
element elasticBeamColumn  605501     553  105571 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  605601     563  105671 100000.0000 $E 100000000.0000 $trans_PDelta; 
element elasticBeamColumn  604500     453     551 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  604600     463     561 100000.0000 $E 100000000.0000 $trans_PDelta; 
element elasticBeamColumn  603502  103572     451 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  603602  103672     461 100000.0000 $E 100000000.0000 $trans_PDelta; 
element elasticBeamColumn  603501     353  103571 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  603601     363  103671 100000.0000 $E 100000000.0000 $trans_PDelta; 
element elasticBeamColumn  602500     253     351 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  602600     263     361 100000.0000 $E 100000000.0000 $trans_PDelta; 
element elasticBeamColumn  601500     153     251 100000.0000 $E 100000000.0000 $trans_PDelta; element elasticBeamColumn  601600     163     261 100000.0000 $E 100000000.0000 $trans_PDelta; 

# GRAVITY BEAMS
element elasticBeamColumn  509400     954     962 100000.0000 $E 100000000.0000 $trans_PDelta;
element elasticBeamColumn  508400     854     862 100000.0000 $E 100000000.0000 $trans_PDelta;
element elasticBeamColumn  507400     754     762 100000.0000 $E 100000000.0000 $trans_PDelta;
element elasticBeamColumn  506400     654     662 100000.0000 $E 100000000.0000 $trans_PDelta;
element elasticBeamColumn  505400     554     562 100000.0000 $E 100000000.0000 $trans_PDelta;
element elasticBeamColumn  504400     454     462 100000.0000 $E 100000000.0000 $trans_PDelta;
element elasticBeamColumn  503400     354     362 100000.0000 $E 100000000.0000 $trans_PDelta;
element elasticBeamColumn  502400     254     262 100000.0000 $E 100000000.0000 $trans_PDelta;

# GRAVITY COLUMNS SPRINGS
Spring_Zero  909501     950     951; Spring_Zero  909601     960     961; 
Spring_Zero  908503     850     853; Spring_Zero  908603     860     863; 
Spring_Zero  908501     850     851; Spring_Zero  908601     860     861; 
Spring_Zero  907503     750     753; Spring_Zero  907603     760     763; 
Spring_Zero  907501     750     751; Spring_Zero  907601     760     761; 
Spring_Zero  906503     650     653; Spring_Zero  906603     660     663; 
Spring_Zero  906501     650     651; Spring_Zero  906601     660     661; 
Spring_Zero  905503     550     553; Spring_Zero  905603     560     563; 
Spring_Zero  905501     550     551; Spring_Zero  905601     560     561; 
Spring_Zero  904503     450     453; Spring_Zero  904603     460     463; 
Spring_Zero  904501     450     451; Spring_Zero  904601     460     461; 
Spring_Zero  903503     350     353; Spring_Zero  903603     360     363; 
Spring_Zero  903501     350     351; Spring_Zero  903601     360     361; 
Spring_Zero  902503     250     253; Spring_Zero  902603     260     263; 
Spring_Zero  902501     250     251; Spring_Zero  902601     260     261; 
Spring_Zero  901503     150     153; Spring_Zero  901603     160     163; 

# GRAVITY BEAMS SPRINGS
Spring_Rigid  909504     950     954; Spring_Rigid  909602     960     962; 
Spring_Rigid  908504     850     854; Spring_Rigid  908602     860     862; 
Spring_Rigid  907504     750     754; Spring_Rigid  907602     760     762; 
Spring_Rigid  906504     650     654; Spring_Rigid  906602     660     662; 
Spring_Rigid  905504     550     554; Spring_Rigid  905602     560     562; 
Spring_Rigid  904504     450     454; Spring_Rigid  904602     460     462; 
Spring_Rigid  903504     350     354; Spring_Rigid  903602     360     362; 
Spring_Rigid  902504     250     254; Spring_Rigid  902602     260     262; 

###################################################################################################
#                                       BOUNDARY CONDITIONS                                       #
###################################################################################################

# MF SUPPORTS
fix 110 1 1 1; 
fix 120 1 1 1; 
fix 130 1 1 1; 
fix 140 1 1 1; 

# EGF SUPPORTS
fix 150 1 1 0; fix 160 1 1 0; 

# MF FLOOR MOVEMENT
equalDOF 409104 409204 1; equalDOF 409104 409304 1; equalDOF 409104 409404 1; 
equalDOF 408104 408204 1; equalDOF 408104 408304 1; equalDOF 408104 408404 1; 
equalDOF 407104 407204 1; equalDOF 407104 407304 1; equalDOF 407104 407404 1; 
equalDOF 406104 406204 1; equalDOF 406104 406304 1; equalDOF 406104 406404 1; 
equalDOF 405104 405204 1; equalDOF 405104 405304 1; equalDOF 405104 405404 1; 
equalDOF 404104 404204 1; equalDOF 404104 404304 1; equalDOF 404104 404404 1; 
equalDOF 403104 403204 1; equalDOF 403104 403304 1; equalDOF 403104 403404 1; 
equalDOF 402104 402204 1; equalDOF 402104 402304 1; equalDOF 402104 402404 1; 

# EGF FLOOR MOVEMENT
equalDOF 950 960 1;
equalDOF 850 860 1;
equalDOF 750 760 1;
equalDOF 650 660 1;
equalDOF 550 560 1;
equalDOF 450 460 1;
equalDOF 350 360 1;
equalDOF 250 260 1;


##################################################################################################
##################################################################################################
                                       puts "Model Built"
##################################################################################################
##################################################################################################

###################################################################################################
#                                             RECORDERS                                           #
###################################################################################################

# EIGEN VECTORS
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode1.out -node 402104 403104 404104 405104 406104 407104 408104 409104  -dof 1 "eigen  1";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode2.out -node 402104 403104 404104 405104 406104 407104 408104 409104  -dof 1 "eigen  2";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode3.out -node 402104 403104 404104 405104 406104 407104 408104 409104  -dof 1 "eigen  3";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode4.out -node 402104 403104 404104 405104 406104 407104 408104 409104  -dof 1 "eigen  4";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode5.out -node 402104 403104 404104 405104 406104 407104 408104 409104  -dof 1 "eigen  5";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode6.out -node 402104 403104 404104 405104 406104 407104 408104 409104  -dof 1 "eigen  6";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode7.out -node 402104 403104 404104 405104 406104 407104 408104 409104  -dof 1 "eigen  7";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode8.out -node 402104 403104 404104 405104 406104 407104 408104 409104  -dof 1 "eigen  8";

# TIME
recorder Node -file $MainFolder/$SubFolder/Time.out  -time -node 110 -dof 1 disp;

# SUPPORT REACTIONS
recorder Node -file $MainFolder/$SubFolder/Support1.out -node     110 -dof 1 2 6 reaction; recorder Node -file $MainFolder/$SubFolder/Support2.out -node     120 -dof 1 2 6 reaction; recorder Node -file $MainFolder/$SubFolder/Support3.out -node     130 -dof 1 2 6 reaction; recorder Node -file $MainFolder/$SubFolder/Support4.out -node     140 -dof 1 2 6 reaction; recorder Node -file $MainFolder/$SubFolder/Support5.out -node     150 -dof 1 2 6 reaction; recorder Node -file $MainFolder/$SubFolder/Support6.out -node     160 -dof 1 2 6 reaction; 

# STORY DRIFT RATIO
recorder Drift -file $MainFolder/$SubFolder/SDR8_MF.out -iNode  408104 -jNode  409104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR7_MF.out -iNode  407104 -jNode  408104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR6_MF.out -iNode  406104 -jNode  407104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR5_MF.out -iNode  405104 -jNode  406104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR4_MF.out -iNode  404104 -jNode  405104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR3_MF.out -iNode  403104 -jNode  404104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR2_MF.out -iNode  402104 -jNode  403104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR1_MF.out -iNode     110 -jNode  402104 -dof 1 -perpDirn 2; 

# COLUMN ELASTIC ELEMENT FORCES
recorder Element -file $MainFolder/$SubFolder/Column81.out -ele  608100 force; recorder Element -file $MainFolder/$SubFolder/Column82.out -ele  608200 force; recorder Element -file $MainFolder/$SubFolder/Column83.out -ele  608300 force; recorder Element -file $MainFolder/$SubFolder/Column84.out -ele  608400 force; recorder Element -file $MainFolder/$SubFolder/Column85.out -ele  608500 force; recorder Element -file $MainFolder/$SubFolder/Column86.out -ele  608600 force; 
recorder Element -file $MainFolder/$SubFolder/Column71.out -ele  607101 force; recorder Element -file $MainFolder/$SubFolder/Column72.out -ele  607201 force; recorder Element -file $MainFolder/$SubFolder/Column73.out -ele  607301 force; recorder Element -file $MainFolder/$SubFolder/Column74.out -ele  607401 force; recorder Element -file $MainFolder/$SubFolder/Column75.out -ele  607501 force; recorder Element -file $MainFolder/$SubFolder/Column76.out -ele  607601 force; 
recorder Element -file $MainFolder/$SubFolder/Column61.out -ele  606100 force; recorder Element -file $MainFolder/$SubFolder/Column62.out -ele  606200 force; recorder Element -file $MainFolder/$SubFolder/Column63.out -ele  606300 force; recorder Element -file $MainFolder/$SubFolder/Column64.out -ele  606400 force; recorder Element -file $MainFolder/$SubFolder/Column65.out -ele  606500 force; recorder Element -file $MainFolder/$SubFolder/Column66.out -ele  606600 force; 
recorder Element -file $MainFolder/$SubFolder/Column51.out -ele  605101 force; recorder Element -file $MainFolder/$SubFolder/Column52.out -ele  605201 force; recorder Element -file $MainFolder/$SubFolder/Column53.out -ele  605301 force; recorder Element -file $MainFolder/$SubFolder/Column54.out -ele  605401 force; recorder Element -file $MainFolder/$SubFolder/Column55.out -ele  605501 force; recorder Element -file $MainFolder/$SubFolder/Column56.out -ele  605601 force; 
recorder Element -file $MainFolder/$SubFolder/Column41.out -ele  604100 force; recorder Element -file $MainFolder/$SubFolder/Column42.out -ele  604200 force; recorder Element -file $MainFolder/$SubFolder/Column43.out -ele  604300 force; recorder Element -file $MainFolder/$SubFolder/Column44.out -ele  604400 force; recorder Element -file $MainFolder/$SubFolder/Column45.out -ele  604500 force; recorder Element -file $MainFolder/$SubFolder/Column46.out -ele  604600 force; 
recorder Element -file $MainFolder/$SubFolder/Column31.out -ele  603101 force; recorder Element -file $MainFolder/$SubFolder/Column32.out -ele  603201 force; recorder Element -file $MainFolder/$SubFolder/Column33.out -ele  603301 force; recorder Element -file $MainFolder/$SubFolder/Column34.out -ele  603401 force; recorder Element -file $MainFolder/$SubFolder/Column35.out -ele  603501 force; recorder Element -file $MainFolder/$SubFolder/Column36.out -ele  603601 force; 
recorder Element -file $MainFolder/$SubFolder/Column21.out -ele  602100 force; recorder Element -file $MainFolder/$SubFolder/Column22.out -ele  602200 force; recorder Element -file $MainFolder/$SubFolder/Column23.out -ele  602300 force; recorder Element -file $MainFolder/$SubFolder/Column24.out -ele  602400 force; recorder Element -file $MainFolder/$SubFolder/Column25.out -ele  602500 force; recorder Element -file $MainFolder/$SubFolder/Column26.out -ele  602600 force; 
recorder Element -file $MainFolder/$SubFolder/Column11.out -ele  601100 force; recorder Element -file $MainFolder/$SubFolder/Column12.out -ele  601200 force; recorder Element -file $MainFolder/$SubFolder/Column13.out -ele  601300 force; recorder Element -file $MainFolder/$SubFolder/Column14.out -ele  601400 force; recorder Element -file $MainFolder/$SubFolder/Column15.out -ele  601500 force; recorder Element -file $MainFolder/$SubFolder/Column16.out -ele  601600 force; 

###################################################################################################
#                                              NODAL MASS                                         #
###################################################################################################

set g 9810.00;
mass 409104 0.0363  1.e-9 1.e-9; mass 409204 0.0363  1.e-9 1.e-9; mass 409304 0.0363  1.e-9 1.e-9; mass 409404 0.0363  1.e-9 1.e-9; mass 950 -0.0041  1.e-9 1.e-9; mass 960 -0.0041  1.e-9 1.e-9; 
mass 408104 0.0402  1.e-9 1.e-9; mass 408204 0.0402  1.e-9 1.e-9; mass 408304 0.0402  1.e-9 1.e-9; mass 408404 0.0402  1.e-9 1.e-9; mass 850 -0.0041  1.e-9 1.e-9; mass 860 -0.0041  1.e-9 1.e-9; 
mass 407104 0.0402  1.e-9 1.e-9; mass 407204 0.0402  1.e-9 1.e-9; mass 407304 0.0402  1.e-9 1.e-9; mass 407404 0.0402  1.e-9 1.e-9; mass 750 -0.0041  1.e-9 1.e-9; mass 760 -0.0041  1.e-9 1.e-9; 
mass 406104 0.0402  1.e-9 1.e-9; mass 406204 0.0402  1.e-9 1.e-9; mass 406304 0.0402  1.e-9 1.e-9; mass 406404 0.0402  1.e-9 1.e-9; mass 650 -0.0041  1.e-9 1.e-9; mass 660 -0.0041  1.e-9 1.e-9; 
mass 405104 0.0402  1.e-9 1.e-9; mass 405204 0.0402  1.e-9 1.e-9; mass 405304 0.0402  1.e-9 1.e-9; mass 405404 0.0402  1.e-9 1.e-9; mass 550 -0.0041  1.e-9 1.e-9; mass 560 -0.0041  1.e-9 1.e-9; 
mass 404104 0.0402  1.e-9 1.e-9; mass 404204 0.0402  1.e-9 1.e-9; mass 404304 0.0402  1.e-9 1.e-9; mass 404404 0.0402  1.e-9 1.e-9; mass 450 -0.0041  1.e-9 1.e-9; mass 460 -0.0041  1.e-9 1.e-9; 
mass 403104 0.0402  1.e-9 1.e-9; mass 403204 0.0402  1.e-9 1.e-9; mass 403304 0.0402  1.e-9 1.e-9; mass 403404 0.0402  1.e-9 1.e-9; mass 350 -0.0041  1.e-9 1.e-9; mass 360 -0.0041  1.e-9 1.e-9; 
mass 402104 0.0414  1.e-9 1.e-9; mass 402204 0.0414  1.e-9 1.e-9; mass 402304 0.0414  1.e-9 1.e-9; mass 402404 0.0414  1.e-9 1.e-9; mass 250 -0.0041  1.e-9 1.e-9; mass 260 -0.0041  1.e-9 1.e-9; 

constraints Plain;

###################################################################################################
#                                        EIGEN VALUE ANALYSIS                                     #
###################################################################################################

set pi [expr 2.0*asin(1.0)];
set nEigen 8;
set lambdaN [eigen [expr $nEigen]];
set lambda1 [lindex $lambdaN 0];
set lambda2 [lindex $lambdaN 1];
set lambda3 [lindex $lambdaN 2];
set lambda4 [lindex $lambdaN 3];
set lambda5 [lindex $lambdaN 4];
set lambda6 [lindex $lambdaN 5];
set lambda7 [lindex $lambdaN 6];
set lambda8 [lindex $lambdaN 7];
set w1 [expr pow($lambda1,0.5)];
set w2 [expr pow($lambda2,0.5)];
set w3 [expr pow($lambda3,0.5)];
set w4 [expr pow($lambda4,0.5)];
set w5 [expr pow($lambda5,0.5)];
set w6 [expr pow($lambda6,0.5)];
set w7 [expr pow($lambda7,0.5)];
set w8 [expr pow($lambda8,0.5)];
set T1 [expr round(2.0*$pi/$w1 *1000.)/1000.];
set T2 [expr round(2.0*$pi/$w2 *1000.)/1000.];
set T3 [expr round(2.0*$pi/$w3 *1000.)/1000.];
set T4 [expr round(2.0*$pi/$w4 *1000.)/1000.];
set T5 [expr round(2.0*$pi/$w5 *1000.)/1000.];
set T6 [expr round(2.0*$pi/$w6 *1000.)/1000.];
set T7 [expr round(2.0*$pi/$w7 *1000.)/1000.];
set T8 [expr round(2.0*$pi/$w8 *1000.)/1000.];
puts "T1 = $T1 s";
puts "T2 = $T2 s";
puts "T3 = $T3 s";
cd $RFpath;
cd "Results"
cd "EigenAnalysis"
set fileX [open "EigenPeriod.out" w];
puts $fileX $T1;puts $fileX $T2;puts $fileX $T3;puts $fileX $T4;puts $fileX $T5;puts $fileX $T6;puts $fileX $T7;puts $fileX $T8;close $fileX;
cd $MainDir;

constraints Plain;
algorithm Newton;
integrator LoadControl 1;
analysis Static;
analyze 1;

###################################################################################################
###################################################################################################
									puts "Eigen Analysis Done"
###################################################################################################
###################################################################################################

###################################################################################################
#                                   DYNAMIC EARTHQUAKE ANALYSIS                                   #
###################################################################################################

if {$EQ==1} {

# Rayleigh Damping
global Sigma_zeta; global xRandom;
set zeta 0.020;
set SigmaX $Sigma_zeta; Generate_lognrmrand $zeta 		$SigmaX; 		set zeta 	$xRandom;
set a0 [expr $zeta*2.0*$w1*$w3/($w1 + $w3)];
set a1 [expr $zeta*2.0/($w1 + $w3)];
set a1_mod [expr $a1*(1.0+$n)/$n];
region 1 -ele  608100 608200 608300 608400 607102 607202 607302 607402 607101 607201 607301 607401 606100 606200 606300 606400 605102 605202 605302 605402 605101 605201 605301 605401 604100 604200 604300 604400 603102 603202 603302 603402 603101 603201 603301 603401 602100 602200 602300 602400 601100 601200 601300 601400 509100 509200 509300 508100 508200 508300 507100 507200 507300 506100 506200 506300 505100 505200 505300 504100 504200 504300 503100 503200 503300 502100 502200 502300  -rayleigh 0.0 0.0 $a1_mod 0.0;
region 2 -node  402104 402204 402304 402404 250 260 403104 403204 403304 403404 350 360 404104 404204 404304 404404 450 460 405104 405204 405304 405404 550 560 406104 406204 406304 406404 650 660 407104 407204 407304 407404 750 760 408104 408204 408304 408404 850 860 409104 409204 409304 409404 950 960  -rayleigh $a0 0.0 0.0 0.0;
region 3 -eleRange  900000  999999 -rayleigh 0.0 0.0 [expr $a1_mod/10] 0.0;

# GROUND MOTION ACCELERATION FILE INPUT
set AccelSeries "Series -dt $GMdt -filePath GM.txt -factor  [expr $EqSF * $g]"
pattern UniformExcitation  200 1 -accel $AccelSeries

set MF_FloorNodes [list  402104 403104 404104 405104 406104 407104 408104 409104 ];
set EGF_FloorNodes [list  250 350 450 550 650 750 850 950 ];
set GMduration [expr $GMdt*$GMpoints];
set FVduration 10.000000;
set NumSteps [expr round(($GMduration + $FVduration)/$GMdt)];	# number of steps in analysis
set totTime [expr $GMdt*$NumSteps];                            # Total time of analysis
set dtAnalysis [expr 0.500000*$GMdt];                             	# dt of Analysis

DynamicAnalysisCollapseSolverX  $GMdt	$dtAnalysis	$totTime $NStory	 0.15   $MF_FloorNodes	$EGF_FloorNodes	4572.00 3960.00 1 $StartTime $MaxRunTime;

###################################################################################################
###################################################################################################
							puts "Ground Motion Done. End Time: [getTime]"
###################################################################################################
###################################################################################################
}

wipe all;
