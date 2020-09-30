####################################################################################################
####################################################################################################
#                                        6-story CBF Building
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
set  EQ 1;
set  PO 0;
set  ELF 0;
set  Composite 1;
set  ShowAnimation 0;
set  MainDir {C:\Dropbox\Under Development\FM-2D};
set  RFpath {C:\Users\ahmed\OneDrive\Desktop};
set  MainFolder {C:\Users\ahmed\OneDrive\Desktop\Results};
set  ModePO 1;
set  DriftPO 0.100000;
set  DampModeI 1;
set  DampModeJ 3;
set  zeta 0.020000;

########################################################################
#Code Below is Only Needed To Run Dynamic Analysis through MATLAB Code #
########################################################################

# Opens file to read (r) the scale factor
set fileID1 [open SF.txt r];  
set EqSF [read $fileID1];

# Opens file to read (r) the current GM info
set fileID2 [open GMinfo.txt r];
gets  $fileID2 GMid
gets  $fileID2 GMname
gets  $fileID2 GMpoints
gets  $fileID2 GMdt
gets  $fileID2 Subfoldername

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
source Spring_Pinching.tcl;
source ConstructPanel_Rectangle.tcl;
source ConstructBrace.tcl;
source Spring_Gusset.tcl;
source FatigueMat.tcl;
source ConstructFiberColumn.tcl;
source FiberRHSS.tcl;
source FiberCHSS.tcl;
source FiberWF.tcl;
source DynamicAnalysisCollapseSolverX.tcl;
source Generate_lognrmrand.tcl;

####################################################################################################
#                                          Create Results Folders                                  #
####################################################################################################

# RESULT FOLDER
set SubFolder  $Subfoldername;
cd $RFpath;
file mkdir "Results";
cd "Results"
file mkdir $SubFolder;
cd $MainDir;

####################################################################################################
#                                              INPUT                                               #
####################################################################################################

# FRAME CENTERLINE DIMENSIONS
set NStory  6;
set NBay  1;

# MATERIAL PROPERTIES
set E  29000.0; 
set mu    0.3; 
set Fy  [expr  55.0 *   1.0];
set FyB [expr  55.0 *   1.0];
set FyG [expr  55.0 *   1.0];

# BASIC MATERIALS
uniaxialMaterial Elastic  9  1.e-9; 		#Flexible Material 
uniaxialMaterial Elastic  99 1000000000.;  #Rigid Material 
uniaxialMaterial UVCuniaxial  666 29000.0000 55.0000 18.0000 10.0000 0.0000 1.0000 2 3500.0000 180.0000 345.0000 10.0000; #Voce-Chaboche Material

# GEOMETRIC TRANSFORMATIONS IDs
geomTransf Linear 		 1;
geomTransf PDelta 		 2;
geomTransf Corotational 3;
set trans_Linear 	1;
set trans_PDelta 	2;
set trans_Corot  	3;
set trans_selected  2;

# STIFF ELEMENTS PROPERTY
set A_Stiff 1000.0;
set I_Stiff 100000.0;

# COMPOSITE BEAM FACTOR
puts "Composite Action is Considered"
set Composite 1;
set Comp_I    1.400;
set Comp_I_GC 1.400;

# FIBER ELEMENT PROPERTIES
set nSegments    8;
set initialGI    0.00100;
set nIntegration 5;

# LOGARITHMIC STANDARD DEVIATIONS (FOR UNCERTAINTY CONSIDERATION)
global Sigma_IMKcol Sigma_IMKbeam Sigma_Pinching4 Sigma_PZ; 
set Sigma_IMKcol [list  1.e-9 0.300 0.100 1.e-9 0.400 0.300 1.e-9 0.400 1.e-9 ];
set Sigma_IMKbeam   [list  1.e-9 0.300 0.200 1.e-9 0.300 0.400 1.e-9 0.400 1.e-9 ];
set Sigma_Pinching4 [list  1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 1.e-9 ];
set Sigma_PZ        [list  1.e-9 1.e-9 1.e-9 1.e-9 ];
set Sigma_fy     0.200;
 set Sigma_fyB    0.200;
 set Sigma_fyG    0.200;
 set Sigma_GI     0.200;
 set Sigma_zeta   0.500;
 global Sigma_fy Sigma_fyB Sigma_fyG Sigma_GI; global xRandom;
set SigmaX $Sigma_fy;  Generate_lognrmrand $Fy 	$SigmaX; 	set Fy      $xRandom;
set SigmaX $Sigma_fyB; Generate_lognrmrand $FyB 	$SigmaX; 	set FyB 	$xRandom;
set SigmaX $Sigma_fyG; Generate_lognrmrand $FyG 	$SigmaX; 	set FyG 	$xRandom;
set SigmaX $Sigma_GI;  Generate_lognrmrand 0.001000 	    $SigmaX; 	set initialGI 	$xRandom;

####################################################################################################
#                                          PRE-CALCULATIONS                                        #
####################################################################################################

set pi [expr 2.0*asin(1.0)];

# Geometry of Corner Gusset Plate
set   X_CGP1  25.4587;  set   Y_CGP1  25.4587;
set   X_CGP2  28.8588;  set   Y_CGP2  28.8588;
set   X_CGP3  27.9749;  set   Y_CGP3  27.9749;
set   X_CGP4  24.9697;  set   Y_CGP4  24.9697;
set   X_CGP5  22.5390;  set   Y_CGP5  22.5390;
set   X_CGP6  18.8267;  set   Y_CGP6  18.8267;
# Geometry of Mid-Span Gusset Plate
set   X_MGP1  18.6499;  set   Y_MGP1  18.6499;
set   X_MGP2  18.6499;  set   Y_MGP2  18.6499;
set   X_MGP3  16.1309;  set   Y_MGP3  16.1309;
set   X_MGP4  16.2635;  set   Y_MGP4  16.2635;
set   X_MGP5  18.4732;  set   Y_MGP5  18.4732;
set   X_MGP6  17.7219;  set   Y_MGP6  17.7219;

# FRAME GRID LINES
set Floor7  1080.00;
set Floor6  900.00;
set Floor5  720.00;
set Floor4  540.00;
set Floor3  360.00;
set Floor2  180.00;
set Floor1 0.0;

set Axis1 0.0;
set Axis2 360.00;
set Axis3 720.00;
set Axis4 1080.00;

set HBuilding 1080.00;
set WFrame 360.00;
variable HBuilding 1080.00;

####################################################################################################
#                                                  NODES                                           #
####################################################################################################

# COMMAND SYNTAX 
# node $NodeID  $X-Coordinate  $Y-Coordinate;

#SUPPORT NODES
node 110   $Axis1  $Floor1; node 120   $Axis2  $Floor1; node 130   $Axis3  $Floor1; node 140   $Axis4  $Floor1; 

# EGF COLUMN GRID NODES
node 730   $Axis3  $Floor7; node 740   $Axis4  $Floor7; 
node 630   $Axis3  $Floor6; node 640   $Axis4  $Floor6; 
node 530   $Axis3  $Floor5; node 540   $Axis4  $Floor5; 
node 430   $Axis3  $Floor4; node 440   $Axis4  $Floor4; 
node 330   $Axis3  $Floor3; node 340   $Axis4  $Floor3; 
node 230   $Axis3  $Floor2; node 240   $Axis4  $Floor2; 

# EGF COLUMN NODES
node 731  $Axis3  $Floor7; node 741  $Axis4  $Floor7; 
node 633  $Axis3  $Floor6; node 643  $Axis4  $Floor6; 
node 631  $Axis3  $Floor6; node 641  $Axis4  $Floor6; 
node 533  $Axis3  $Floor5; node 543  $Axis4  $Floor5; 
node 531  $Axis3  $Floor5; node 541  $Axis4  $Floor5; 
node 433  $Axis3  $Floor4; node 443  $Axis4  $Floor4; 
node 431  $Axis3  $Floor4; node 441  $Axis4  $Floor4; 
node 333  $Axis3  $Floor3; node 343  $Axis4  $Floor3; 
node 331  $Axis3  $Floor3; node 341  $Axis4  $Floor3; 
node 233  $Axis3  $Floor2; node 243  $Axis4  $Floor2; 
node 231  $Axis3  $Floor2; node 241  $Axis4  $Floor2; 
node 133  $Axis3  $Floor1; node 143  $Axis4  $Floor1; 

# EGF BEAM NODES
node 734  $Axis3  $Floor7; node 742  $Axis4  $Floor7; 
node 634  $Axis3  $Floor6; node 642  $Axis4  $Floor6; 
node 534  $Axis3  $Floor5; node 542  $Axis4  $Floor5; 
node 434  $Axis3  $Floor4; node 442  $Axis4  $Floor4; 
node 334  $Axis3  $Floor3; node 342  $Axis4  $Floor3; 
node 234  $Axis3  $Floor2; node 242  $Axis4  $Floor2; 

# MF COLUMN NODES
node 711  $Axis1 [expr $Floor7 - 18.60/2]; node 721  $Axis2 [expr $Floor7 - 18.60/2]; 
node 613  $Axis1 [expr $Floor6 + 24.10/2]; node 623  $Axis2 [expr $Floor6 + 24.10/2]; 
node 611  $Axis1 [expr $Floor6 - 24.10/2]; node 621  $Axis2 [expr $Floor6 - 24.10/2]; 
node 513  $Axis1 [expr $Floor5 + 24.50/2]; node 523  $Axis2 [expr $Floor5 + 24.50/2]; 
node 511  $Axis1 [expr $Floor5 - 24.50/2]; node 521  $Axis2 [expr $Floor5 - 24.50/2]; 
node 413  $Axis1 [expr $Floor4 + 18.20/2]; node 423  $Axis2 [expr $Floor4 + 18.20/2]; 
node 411  $Axis1 [expr $Floor4 - 18.20/2]; node 421  $Axis2 [expr $Floor4 - 18.20/2]; 
node 313  $Axis1 [expr $Floor3 + 24.70/2]; node 323  $Axis2 [expr $Floor3 + 24.70/2]; 
node 311  $Axis1 [expr $Floor3 - 24.70/2]; node 321  $Axis2 [expr $Floor3 - 24.70/2]; 
node 213  $Axis1 [expr $Floor2 + 21.00/2]; node 223  $Axis2 [expr $Floor2 + 21.00/2]; 
node 211  $Axis1 [expr $Floor2 - 21.00/2]; node 221  $Axis2 [expr $Floor2 - 21.00/2]; 
node 113  $Axis1 $Floor1; node 123  $Axis2 $Floor1; 

# MF BEAM NODES
node 714   [expr $Axis1 + 14.00/2] $Floor7; node 722   [expr $Axis2 - 14.00/2] $Floor7; 
node 614   [expr $Axis1 + 15.20/2] $Floor6; node 622   [expr $Axis2 - 15.20/2] $Floor6; 
node 514   [expr $Axis1 + 15.20/2] $Floor5; node 522   [expr $Axis2 - 15.20/2] $Floor5; 
node 414   [expr $Axis1 + 17.50/2] $Floor4; node 422   [expr $Axis2 - 17.50/2] $Floor4; 
node 314   [expr $Axis1 + 17.50/2] $Floor3; node 322   [expr $Axis2 - 17.50/2] $Floor3; 
node 214   [expr $Axis1 + 17.50/2] $Floor2; node 222   [expr $Axis2 - 17.50/2] $Floor2; 

# COLUMN SPLICE NODES
node 105172 $Axis1 [expr ($Floor5 + 0.50 * 180)]; node 105272 $Axis2 [expr ($Floor5 + 0.50 * 180)]; node 105372 $Axis3 [expr ($Floor5 + 0.50 * 180)]; node 105472 $Axis4 [expr ($Floor5 + 0.50 * 180)]; 
node 105171 $Axis1 [expr ($Floor5 + 0.50 * 180)]; node 105271 $Axis2 [expr ($Floor5 + 0.50 * 180)]; node 105371 $Axis3 [expr ($Floor5 + 0.50 * 180)]; node 105471 $Axis4 [expr ($Floor5 + 0.50 * 180)]; 
node 103172 $Axis1 [expr ($Floor3 + 0.50 * 180)]; node 103272 $Axis2 [expr ($Floor3 + 0.50 * 180)]; node 103372 $Axis3 [expr ($Floor3 + 0.50 * 180)]; node 103472 $Axis4 [expr ($Floor3 + 0.50 * 180)]; 
node 103171 $Axis1 [expr ($Floor3 + 0.50 * 180)]; node 103271 $Axis2 [expr ($Floor3 + 0.50 * 180)]; node 103371 $Axis3 [expr ($Floor3 + 0.50 * 180)]; node 103471 $Axis4 [expr ($Floor3 + 0.50 * 180)]; 

# MID-SPAN GUSSET PLATE RIGID OFFSET NODES
node 206101   [expr ($Axis1 + $Axis2)/2] $Floor6;
node 206102   [expr ($Axis1 + $Axis2)/2 - 69.8750/2] $Floor6;
node 206112   [expr ($Axis1 + $Axis2)/2 - 69.8750/2] $Floor6;
node 206105   [expr ($Axis1 + $Axis2)/2 + 69.8750/2] $Floor6;
node 206115   [expr ($Axis1 + $Axis2)/2 + 69.8750/2] $Floor6;
node 206104   [expr ($Axis1 + $Axis2)/2 + $X_MGP5] [expr $Floor6 - $Y_MGP5];
node 206114   [expr ($Axis1 + $Axis2)/2 + $X_MGP5] [expr $Floor6 - $Y_MGP5];
node 206103   [expr ($Axis1 + $Axis2)/2 - $X_MGP5] [expr $Floor6 - $Y_MGP5];
node 206113   [expr ($Axis1 + $Axis2)/2 - $X_MGP5] [expr $Floor6 - $Y_MGP5];
node 206106   [expr ($Axis1 + $Axis2)/2 + $X_MGP6] [expr $Floor6 + $Y_MGP6];
node 206116   [expr ($Axis1 + $Axis2)/2 + $X_MGP6] [expr $Floor6 + $Y_MGP6];
node 206107   [expr ($Axis1 + $Axis2)/2 - $X_MGP6] [expr $Floor6 + $Y_MGP6];
node 206117   [expr ($Axis1 + $Axis2)/2 - $X_MGP6] [expr $Floor6 + $Y_MGP6];
node 204101   [expr ($Axis1 + $Axis2)/2] $Floor4;
node 204102   [expr ($Axis1 + $Axis2)/2 - 79.0625/2] $Floor4;
node 204112   [expr ($Axis1 + $Axis2)/2 - 79.0625/2] $Floor4;
node 204105   [expr ($Axis1 + $Axis2)/2 + 79.0625/2] $Floor4;
node 204115   [expr ($Axis1 + $Axis2)/2 + 79.0625/2] $Floor4;
node 204104   [expr ($Axis1 + $Axis2)/2 + $X_MGP3] [expr $Floor4 - $Y_MGP3];
node 204114   [expr ($Axis1 + $Axis2)/2 + $X_MGP3] [expr $Floor4 - $Y_MGP3];
node 204103   [expr ($Axis1 + $Axis2)/2 - $X_MGP3] [expr $Floor4 - $Y_MGP3];
node 204113   [expr ($Axis1 + $Axis2)/2 - $X_MGP3] [expr $Floor4 - $Y_MGP3];
node 204106   [expr ($Axis1 + $Axis2)/2 + $X_MGP4] [expr $Floor4 + $Y_MGP4];
node 204116   [expr ($Axis1 + $Axis2)/2 + $X_MGP4] [expr $Floor4 + $Y_MGP4];
node 204107   [expr ($Axis1 + $Axis2)/2 - $X_MGP4] [expr $Floor4 + $Y_MGP4];
node 204117   [expr ($Axis1 + $Axis2)/2 - $X_MGP4] [expr $Floor4 + $Y_MGP4];
node 202101   [expr ($Axis1 + $Axis2)/2] $Floor2;
node 202102   [expr ($Axis1 + $Axis2)/2 - 87.8750/2] $Floor2;
node 202112   [expr ($Axis1 + $Axis2)/2 - 87.8750/2] $Floor2;
node 202105   [expr ($Axis1 + $Axis2)/2 + 87.8750/2] $Floor2;
node 202115   [expr ($Axis1 + $Axis2)/2 + 87.8750/2] $Floor2;
node 202104   [expr ($Axis1 + $Axis2)/2 + $X_MGP1] [expr $Floor2 - $Y_MGP1];
node 202114   [expr ($Axis1 + $Axis2)/2 + $X_MGP1] [expr $Floor2 - $Y_MGP1];
node 202103   [expr ($Axis1 + $Axis2)/2 - $X_MGP1] [expr $Floor2 - $Y_MGP1];
node 202113   [expr ($Axis1 + $Axis2)/2 - $X_MGP1] [expr $Floor2 - $Y_MGP1];
node 202106   [expr ($Axis1 + $Axis2)/2 + $X_MGP2] [expr $Floor2 + $Y_MGP2];
node 202116   [expr ($Axis1 + $Axis2)/2 + $X_MGP2] [expr $Floor2 + $Y_MGP2];
node 202107   [expr ($Axis1 + $Axis2)/2 - $X_MGP2] [expr $Floor2 + $Y_MGP2];
node 202117   [expr ($Axis1 + $Axis2)/2 - $X_MGP2] [expr $Floor2 + $Y_MGP2];

# CORNER X-BRACING RIGID OFFSET NODES
node 107150   [expr $Axis1 + $X_CGP6] [expr $Floor7 - $Y_CGP6];
node 107151   [expr $Axis1 + $X_CGP6] [expr $Floor7 - $Y_CGP6];
node 107250   [expr $Axis2 - $X_CGP6] [expr $Floor7 - $Y_CGP6];
node 107251   [expr $Axis2 - $X_CGP6] [expr $Floor7 - $Y_CGP6];
node 105140   [expr $Axis1 + $X_CGP5] [expr $Floor5 + $Y_CGP5];
node 105141   [expr $Axis1 + $X_CGP5] [expr $Floor5 + $Y_CGP5];
node 105150   [expr $Axis1 + $X_CGP4] [expr $Floor5 - $Y_CGP4];
node 105151   [expr $Axis1 + $X_CGP4] [expr $Floor5 - $Y_CGP4];
node 105240   [expr $Axis2 - $X_CGP5] [expr $Floor5 + $Y_CGP5];
node 105241   [expr $Axis2 - $X_CGP5] [expr $Floor5 + $Y_CGP5];
node 105250   [expr $Axis2 - $X_CGP4] [expr $Floor5 - $Y_CGP4];
node 105251   [expr $Axis2 - $X_CGP4] [expr $Floor5 - $Y_CGP4];
node 103140   [expr $Axis1 + $X_CGP3] [expr $Floor3 + $Y_CGP3];
node 103141   [expr $Axis1 + $X_CGP3] [expr $Floor3 + $Y_CGP3];
node 103150   [expr $Axis1 + $X_CGP2] [expr $Floor3 - $Y_CGP2];
node 103151   [expr $Axis1 + $X_CGP2] [expr $Floor3 - $Y_CGP2];
node 103240   [expr $Axis2 - $X_CGP3] [expr $Floor3 + $Y_CGP3];
node 103241   [expr $Axis2 - $X_CGP3] [expr $Floor3 + $Y_CGP3];
node 103250   [expr $Axis2 - $X_CGP2] [expr $Floor3 - $Y_CGP2];
node 103251   [expr $Axis2 - $X_CGP2] [expr $Floor3 - $Y_CGP2];
node 101140   [expr $Axis1 + $X_CGP1] [expr $Floor1 + $Y_CGP1];
node 101141   [expr $Axis1 + $X_CGP1] [expr $Floor1 + $Y_CGP1];
node 101240   [expr $Axis2 - $X_CGP1] [expr $Floor1 + $Y_CGP1];
node 101241   [expr $Axis2 - $X_CGP1] [expr $Floor1 + $Y_CGP1];

###################################################################################################
#                                  PANEL ZONE NODES & ELEMENTS                                    #
###################################################################################################

# PANEL ZONE NODES AND ELASTIC ELEMENTS
# Command Syntax; 
# ConstructPanel_Rectangle Axis Floor X_Axis Y_Floor E A_Panel I_Panel d_Col d_Beam transfTag 
ConstructPanel_Rectangle  1 7 $Axis1 $Floor7 $E $A_Stiff $I_Stiff 14.00 18.60 $trans_selected; ConstructPanel_Rectangle  2 7 $Axis2 $Floor7 $E $A_Stiff $I_Stiff 14.00 18.60 $trans_selected; 
ConstructPanel_Rectangle  1 6 $Axis1 $Floor6 $E $A_Stiff $I_Stiff 15.20 24.10 $trans_selected; ConstructPanel_Rectangle  2 6 $Axis2 $Floor6 $E $A_Stiff $I_Stiff 15.20 24.10 $trans_selected; 
ConstructPanel_Rectangle  1 5 $Axis1 $Floor5 $E $A_Stiff $I_Stiff 15.20 24.50 $trans_selected; ConstructPanel_Rectangle  2 5 $Axis2 $Floor5 $E $A_Stiff $I_Stiff 15.20 24.50 $trans_selected; 
ConstructPanel_Rectangle  1 4 $Axis1 $Floor4 $E $A_Stiff $I_Stiff 17.50 18.20 $trans_selected; ConstructPanel_Rectangle  2 4 $Axis2 $Floor4 $E $A_Stiff $I_Stiff 17.50 18.20 $trans_selected; 
ConstructPanel_Rectangle  1 3 $Axis1 $Floor3 $E $A_Stiff $I_Stiff 17.50 24.70 $trans_selected; ConstructPanel_Rectangle  2 3 $Axis2 $Floor3 $E $A_Stiff $I_Stiff 17.50 24.70 $trans_selected; 
ConstructPanel_Rectangle  1 2 $Axis1 $Floor2 $E $A_Stiff $I_Stiff 17.50 21.00 $trans_selected; ConstructPanel_Rectangle  2 2 $Axis2 $Floor2 $E $A_Stiff $I_Stiff 17.50 21.00 $trans_selected; 

####################################################################################################
#                                          PANEL ZONE SPRINGS                                      #
####################################################################################################

# COMMAND SYNTAX 
# Spring_PZ    Element_ID Node_i Node_j E mu Fy tw_Col tdp d_Col d_Beam tf_Col bf_Col Ic trib ts Response_ID transfTag
Spring_PZ    907100 407109 407110 $E $mu [expr $Fy *   1.0]  0.41   0.00 14.00 18.60  0.72 10.00 722.00 3.500 4.000 2 1; Spring_PZ    907200 407209 407210 $E $mu [expr $Fy *   1.0]  0.41   0.00 14.00 18.60  0.72 10.00 722.00 3.500 4.000 2 1; 
Spring_PZ    906100 406109 406110 $E $mu [expr $Fy *   1.0]  0.41   0.00 14.00 24.10  0.72 10.00 722.00 3.500 4.000 2 1; Spring_PZ    906200 406209 406210 $E $mu [expr $Fy *   1.0]  0.41   0.00 14.00 24.10  0.72 10.00 722.00 3.500 4.000 2 1; 
Spring_PZ    905100 405109 405110 $E $mu [expr $Fy *   1.0]  0.83   0.00 15.20 24.50  1.31 15.70 2140.00 3.500 4.000 2 1; Spring_PZ    905200 405209 405210 $E $mu [expr $Fy *   1.0]  0.83   0.00 15.20 24.50  1.31 15.70 2140.00 3.500 4.000 2 1; 
Spring_PZ    904100 404109 404110 $E $mu [expr $Fy *   1.0]  0.83   0.00 15.20 18.20  1.31 15.70 2140.00 3.500 4.000 2 1; Spring_PZ    904200 404209 404210 $E $mu [expr $Fy *   1.0]  0.83   0.00 15.20 18.20  1.31 15.70 2140.00 3.500 4.000 2 1; 
Spring_PZ    903100 403109 403110 $E $mu [expr $Fy *   1.0]  1.54   0.00 17.50 24.70  2.47 16.40 4900.00 3.500 4.000 2 1; Spring_PZ    903200 403209 403210 $E $mu [expr $Fy *   1.0]  1.54   0.00 17.50 24.70  2.47 16.40 4900.00 3.500 4.000 2 1; 
Spring_PZ    902100 402109 402110 $E $mu [expr $Fy *   1.0]  1.54   0.00 17.50 21.00  2.47 16.40 4900.00 3.500 4.000 2 1; Spring_PZ    902200 402209 402210 $E $mu [expr $Fy *   1.0]  1.54   0.00 17.50 21.00  2.47 16.40 4900.00 3.500 4.000 2 1; 

####################################################################################################
#                                          RIGID BRACE LINKS                                       #
####################################################################################################

# COMMAND SYNTAX 
# element elasticBeamColumn $ElementID $NodeIDi $NodeIDj $Area $E $Inertia $transformation;

# MIDDLE RIGID LINKS

element elasticBeamColumn 706122 206101 206102 $A_Stiff $E $I_Stiff  $trans_selected;
element elasticBeamColumn 706133 206101 206103 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 706144 206101 206104 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 706155 206101 206105 $A_Stiff $E $I_Stiff  $trans_selected;
element elasticBeamColumn 706166 206101 206106 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 706177 206101 206107 $A_Stiff $E $I_Stiff  $trans_Corot;


element elasticBeamColumn 704122 204101 204102 $A_Stiff $E $I_Stiff  $trans_selected;
element elasticBeamColumn 704133 204101 204103 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 704144 204101 204104 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 704155 204101 204105 $A_Stiff $E $I_Stiff  $trans_selected;
element elasticBeamColumn 704166 204101 204106 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 704177 204101 204107 $A_Stiff $E $I_Stiff  $trans_Corot;


element elasticBeamColumn 702122 202101 202102 $A_Stiff $E $I_Stiff  $trans_selected;
element elasticBeamColumn 702133 202101 202103 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 702144 202101 202104 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 702155 202101 202105 $A_Stiff $E $I_Stiff  $trans_selected;
element elasticBeamColumn 702166 202101 202106 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 702177 202101 202107 $A_Stiff $E $I_Stiff  $trans_Corot;


# CORNER RIGID LINKS
element elasticBeamColumn 707199 407199 107150 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 707299 407206 107250 $A_Stiff $E $I_Stiff  $trans_Corot;

element elasticBeamColumn 705111 405110 105140 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 705199 405199 105150 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 705211 405208 105240 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 705299 405206 105250 $A_Stiff $E $I_Stiff  $trans_Corot;

element elasticBeamColumn 703111 403110 103140 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 703199 403199 103150 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 703211 403208 103240 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 703299 403206 103250 $A_Stiff $E $I_Stiff  $trans_Corot;

element elasticBeamColumn 701111 110 101140 $A_Stiff $E $I_Stiff  $trans_Corot;
element elasticBeamColumn 701211 120 101240 $A_Stiff $E $I_Stiff  $trans_Corot;


####################################################################################################
#                                 			GUSSET PLATE SPRINGS   		                            #
####################################################################################################

# COMMAND SYNTAX 
# Spring_Gusset $SpringID $NodeIDi $NodeIDj $Fy $E $L_buckling $t_plate $L_connection $d_brace $MatID;

# BEAM MID-SPAN GUSSET PLATE SPRING
Spring_Gusset 906133 206113 206103 $FyG $E 4.0753 0.5000 16.0000 9.6300  4000;
Spring_Gusset 906144 206114 206104 $FyG $E 4.0753 0.5000 16.0000 9.6300  4001;
Spring_Gusset 906166 206116 206106 $FyG $E 8.3462 0.5000 17.0625 7.5000  4002;
Spring_Gusset 906177 206117 206107 $FyG $E 8.3462 0.5000 17.0625 7.5000  4003;

Spring_Gusset 904133 204113 204103 $FyG $E 1.4242 0.6250 24.0000 11.2500  4004;
Spring_Gusset 904144 204114 204104 $FyG $E 1.4242 0.6250 24.0000 11.2500  4005;
Spring_Gusset 904166 204116 204106 $FyG $E 1.8213 0.6250 24.8125 9.6300  4006;
Spring_Gusset 904177 204117 204107 $FyG $E 1.8213 0.6250 24.8125 9.6300  4007;

Spring_Gusset 902133 202113 202103 $FyG $E 0.1401 0.6250 27.0000 12.5000  4008;
Spring_Gusset 902144 202114 202104 $FyG $E 0.1401 0.6250 27.0000 12.5000  4009;
Spring_Gusset 902166 202116 202106 $FyG $E 0.1401 0.6250 27.0000 12.5000  4010;
Spring_Gusset 902177 202117 202107 $FyG $E 0.1401 0.6250 27.0000 12.5000  4011;


# CORNER GUSSET PLATE SPRINGS
Spring_Gusset 907199 107150 107151 $FyG $E 8.1910 0.5000 10.0000 7.5000  4012;
Spring_Gusset 907299 107250 107251 $FyG $E 8.1910 0.5000 10.0000 7.5000  4013;

Spring_Gusset 905111 105140 105141 $FyG $E 7.3522 0.5000 26.0000 9.6300  4014;
Spring_Gusset 905199 105150 105151 $FyG $E 8.9130 0.6250 21.0000 9.6300  4015;
Spring_Gusset 905211 105240 105241 $FyG $E 7.3522 0.5000 26.0000 9.6300  4016;
Spring_Gusset 905299 105250 105251 $FyG $E 8.9130 0.6250 21.0000 9.6300  4017;

Spring_Gusset 903111 103140 103141 $FyG $E 16.3098 0.6250 24.0000 11.2500  4018;
Spring_Gusset 903199 103150 103151 $FyG $E 10.4640 0.6250 27.0000 12.5000  4019;
Spring_Gusset 903211 103240 103241 $FyG $E 16.3098 0.6250 24.0000 11.2500  4020;
Spring_Gusset 903299 103250 103251 $FyG $E 10.4640 0.6250 27.0000 12.5000  4021;

Spring_Gusset 901111 101140 101141 $FyG $E 13.7306 0.6250 27.0000 12.5000  4022;
Spring_Gusset 901211 101240 101241 $FyG $E 13.7306 0.6250 27.0000 12.5000  4023;


####################################################################################################
#                                 BRACE MEMBERS WITH FATIGUE MATERIAL                              #
####################################################################################################

# CREATE FATIGUE MATERIALS
# COMMAND SYNTAX 
# FatigueMat $MatID $BraceSecType $Fy $E $L_brace $ry_brace $ht_brace $htw_brace $bftf_brace;
FatigueMat 100 2 $FyB $E 190.1875 4.2600 26.9000  0.0 0.0;
FatigueMat 102 2 $FyB $E 187.3750 4.2600 26.9000  0.0 0.0;
FatigueMat 104 2 $FyB $E 191.1875 3.8200 24.2000  0.0 0.0;
FatigueMat 106 2 $FyB $E 196.2500 3.2400 20.7000  0.0 0.0;
FatigueMat 108 2 $FyB $E 196.6250 3.2800 27.6000  0.0 0.0;
FatigueMat 110 2 $FyB $E 202.9375 2.5500 25.8000  0.0 0.0;

# CREATE THE BRACE SECTIONS
# COMMAND SYNTAX 
# FiberRHSS $BraceSecType $FatigueMatID $h_brace $t_brace $nFiber $nFiber $nFiber $nFiber;
FiberCHSS     1   101 12.5000 0.5000 12 4; 
FiberCHSS     2   103 12.5000 0.5000 12 4; 
FiberCHSS     3   105 11.2500 0.5000 12 4; 
FiberCHSS     4   107 9.6300 0.5000 12 4; 
FiberCHSS     5   109 9.6300 0.3750 12 4; 
FiberCHSS     6   111 7.5000 0.3120 12 4; 

# CONSTRUCT THE BRACE MEMBERS
# COMMAND SYNTAX 
# ConstructBrace $BraceID $NodeIDi $NodeIDj $nSegments $Imperfeection $nIntgeration $transformation;
ConstructBrace 8101100   101141   202113     1   $nSegments $initialGI $nIntegration  $trans_Corot;
ConstructBrace 8201100   101241   202114     1   $nSegments $initialGI $nIntegration  $trans_Corot;

ConstructBrace 8102100   103151   202117     2   $nSegments $initialGI $nIntegration  $trans_Corot;
ConstructBrace 8202100   103251   202116     2   $nSegments $initialGI $nIntegration  $trans_Corot;

ConstructBrace 8103100   103141   204113     3   $nSegments $initialGI $nIntegration  $trans_Corot;
ConstructBrace 8203100   103241   204114     3   $nSegments $initialGI $nIntegration  $trans_Corot;

ConstructBrace 8104100   105151   204117     4   $nSegments $initialGI $nIntegration  $trans_Corot;
ConstructBrace 8204100   105251   204116     4   $nSegments $initialGI $nIntegration  $trans_Corot;

ConstructBrace 8105100   105141   206113     5   $nSegments $initialGI $nIntegration  $trans_Corot;
ConstructBrace 8205100   105241   206114     5   $nSegments $initialGI $nIntegration  $trans_Corot;

ConstructBrace 8106100   107151   206117     6   $nSegments $initialGI $nIntegration  $trans_Corot;
ConstructBrace 8206100   107251   206116     6   $nSegments $initialGI $nIntegration  $trans_Corot;


# CONSTRUCT THE GHOST BRACES
uniaxialMaterial Elastic 1000 100.0
element corotTruss 4101100   101141   202113  0.05  1000;
element corotTruss 4201100   101241   202114  0.05  1000;
element corotTruss 4102100   103151   202117  0.05  1000;
element corotTruss 4202100   103251   202116  0.05  1000;
element corotTruss 4103100   103141   204113  0.05  1000;
element corotTruss 4203100   103241   204114  0.05  1000;
element corotTruss 4104100   105151   204117  0.05  1000;
element corotTruss 4204100   105251   204116  0.05  1000;
element corotTruss 4105100   105141   206113  0.05  1000;
element corotTruss 4205100   105241   206114  0.05  1000;
element corotTruss 4106100   107151   206117  0.05  1000;
element corotTruss 4206100   107251   206116  0.05  1000;

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
FiberWF    101 666 14.0000 10.0000 0.7200 0.4150 6 2 6 2; ConstructFiberColumn 606100     613    711   101 5 0.0010 5 $trans_selected 0;
FiberWF    102 666 14.0000 10.0000 0.7200 0.4150 6 2 6 2; ConstructFiberColumn 606200     623    721   102 5 0.0010 5 $trans_selected 0;

FiberWF    103 666 14.0000 10.0000 0.7200 0.4150 6 2 6 2; ConstructFiberColumn 605102  105172    611   103 2 0.0010 5 $trans_selected 2;
FiberWF    104 666 14.0000 10.0000 0.7200 0.4150 6 2 6 2; ConstructFiberColumn 605202  105272    621   104 2 0.0010 5 $trans_selected 2;

FiberWF    105 666 15.2000 15.7000 1.3100 0.8300 6 2 6 2; ConstructFiberColumn  605101      513  105171   105 2 0.0010 5 $trans_selected 1;
FiberWF    106 666 15.2000 15.7000 1.3100 0.8300 6 2 6 2; ConstructFiberColumn  605201      523  105271   106 2 0.0010 5 $trans_selected 1;

FiberWF    107 666 15.2000 15.7000 1.3100 0.8300 6 2 6 2; ConstructFiberColumn 604100     413    511   107 5 0.0010 5 $trans_selected 0;
FiberWF    108 666 15.2000 15.7000 1.3100 0.8300 6 2 6 2; ConstructFiberColumn 604200     423    521   108 5 0.0010 5 $trans_selected 0;

FiberWF    109 666 15.2000 15.7000 1.3100 0.8300 6 2 6 2; ConstructFiberColumn 603102  103172    411   109 2 0.0010 5 $trans_selected 2;
FiberWF    110 666 15.2000 15.7000 1.3100 0.8300 6 2 6 2; ConstructFiberColumn 603202  103272    421   110 2 0.0010 5 $trans_selected 2;

FiberWF    111 666 17.5000 16.4000 2.4700 1.5400 6 2 6 2; ConstructFiberColumn  603101      313  103171   111 2 0.0010 5 $trans_selected 1;
FiberWF    112 666 17.5000 16.4000 2.4700 1.5400 6 2 6 2; ConstructFiberColumn  603201      323  103271   112 2 0.0010 5 $trans_selected 1;

FiberWF    113 666 17.5000 16.4000 2.4700 1.5400 6 2 6 2; ConstructFiberColumn 602100     213    311   113 5 0.0010 5 $trans_selected 0;
FiberWF    114 666 17.5000 16.4000 2.4700 1.5400 6 2 6 2; ConstructFiberColumn 602200     223    321   114 5 0.0010 5 $trans_selected 0;

FiberWF    115 666 17.5000 16.4000 2.4700 1.5400 6 2 6 2; ConstructFiberColumn 601100     113    211   115 5 0.0010 5 $trans_selected 0;
FiberWF    116 666 17.5000 16.4000 2.4700 1.5400 6 2 6 2; ConstructFiberColumn 601200     123    221   116 5 0.0010 5 $trans_selected 0;


# BEAMS
element ModElasticBeam2d  507100     714     722  28.5000 $E [expr ($n+1)/$n*0.90*$Comp_I*1750.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d  506101     614  206112  30.6000 $E [expr ($n+1)/$n*0.90*$Comp_I*3100.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d  506102     622  206115  30.6000 $E [expr ($n+1)/$n*0.90*$Comp_I*3100.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d  505100     514     522  38.5000 $E [expr ($n+1)/$n*0.90*$Comp_I*4020.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d  504101     414  204112  22.3000 $E [expr ($n+1)/$n*0.90*$Comp_I*1330.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d  504102     422  204115  22.3000 $E [expr ($n+1)/$n*0.90*$Comp_I*1330.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d  503100     314     322  43.0000 $E [expr ($n+1)/$n*0.90*$Comp_I*4580.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 
element ModElasticBeam2d  502101     214  202112  18.3000 $E [expr ($n+1)/$n*0.90*$Comp_I*1330.0000] $K11_2 $K33_2 $K44_2 $trans_selected; element ModElasticBeam2d  502102     222  202115  18.3000 $E [expr ($n+1)/$n*0.90*$Comp_I*1330.0000] $K11_2 $K33_2 $K44_2 $trans_selected; 

###################################################################################################
#                                           MF BEAM SPRINGS                                       #
###################################################################################################

Spring_Zero  906104  406104 614; Spring_Zero  906202  622 406202; Spring_IMK 906122 206102 206112 $E $Fy [expr $Comp_I*3100.0000] 24.1000 43.1000 8.5000 2.9100 137.4625 68.7313 68.7313 17484.5000 0 $Composite 0 2; Spring_IMK 906155 206105 206115 $E $Fy [expr $Comp_I*3100.0000] 24.1000 43.1000 8.5000 2.9100 137.4625 68.7313 68.7313 17484.5000 0 $Composite 0 2; 
Spring_Zero  904104  404104 414; Spring_Zero  904202  422 404202; Spring_IMK 904122 204102 204112 $E $Fy [expr $Comp_I*1330.0000] 18.2000 37.8000 8.1100 2.6100 131.7188 65.8594 65.8594 9861.5000 0 $Composite 0 2; Spring_IMK 904155 204105 204115 $E $Fy [expr $Comp_I*1330.0000] 18.2000 37.8000 8.1100 2.6100 131.7188 65.8594 65.8594 9861.5000 0 $Composite 0 2; 
Spring_Zero  902104  402104 214; Spring_Zero  902202  222 402202; Spring_IMK 902122 202102 202112 $E $Fy [expr $Comp_I*1330.0000] 21.0000 46.9000 6.7000 1.7700 127.3125 63.6563 63.6563 8712.0000 0 $Composite 0 2; Spring_IMK 902155 202105 202115 $E $Fy [expr $Comp_I*1330.0000] 21.0000 46.9000 6.7000 1.7700 127.3125 63.6563 63.6563 8712.0000 0 $Composite 0 2; 

Spring_IMK 907104 407104 714 $E $Fy [expr $Comp_I*1750.0000] 18.6000 30.0000 6.4100 2.6500 346.0000 173.0000 173.0000 12765.5000 0 $Composite 0 2; Spring_IMK 907202 722 407202 $E $Fy [expr $Comp_I*1750.0000] 18.6000 30.0000 6.4100 2.6500 346.0000 173.0000 173.0000 12765.5000 0 $Composite 0 2; 
Spring_IMK 905104 405104 514 $E $Fy [expr $Comp_I*4020.0000] 24.5000 35.6000 6.7000 2.9700 344.8000 172.4000 172.4000 22385.0000 0 $Composite 0 2; Spring_IMK 905202 522 405202 $E $Fy [expr $Comp_I*4020.0000] 24.5000 35.6000 6.7000 2.9700 344.8000 172.4000 172.4000 22385.0000 0 $Composite 0 2; 
Spring_IMK 903104 403104 314 $E $Fy [expr $Comp_I*4580.0000] 24.7000 33.2000 5.9200 3.0100 342.5000 171.2500 171.2500 25289.0000 0 $Composite 0 2; Spring_IMK 903202 322 403202 $E $Fy [expr $Comp_I*4580.0000] 24.7000 33.2000 5.9200 3.0100 342.5000 171.2500 171.2500 25289.0000 0 $Composite 0 2; 

###################################################################################################
#                                           MF COLUMN SPRINGS                                     #
###################################################################################################

Spring_Rigid  907101  407101     711; Spring_Rigid  907201  407201     721; 
Spring_Rigid  906103  406103     613; Spring_Rigid  906203  406203     623; 
Spring_Rigid  906101  406101     611; Spring_Rigid  906201  406201     621; 
Spring_Rigid  905103  405103     513; Spring_Rigid  905203  405203     523; 
Spring_Rigid  905101  405101     511; Spring_Rigid  905201  405201     521; 
Spring_Rigid  904103  404103     413; Spring_Rigid  904203  404203     423; 
Spring_Rigid  904101  404101     411; Spring_Rigid  904201  404201     421; 
Spring_Rigid  903103  403103     313; Spring_Rigid  903203  403203     323; 
Spring_Rigid  903101  403101     311; Spring_Rigid  903201  403201     321; 
Spring_Rigid  902103  402103     213; Spring_Rigid  902203  402203     223; 
Spring_Rigid  902101  402101     211; Spring_Rigid  902201  402201     221; 
Spring_Rigid  901103     110     113; Spring_Rigid  901203     120     123; 

###################################################################################################
#                                          COLUMN SPLICE SPRINGS                                  #
###################################################################################################

Spring_Rigid 905107 105171 105172; 
Spring_Rigid 905207 105271 105272; 
Spring_Rigid 905307 105371 105372; 
Spring_Rigid 905407 105471 105472; 
Spring_Rigid 903107 103171 103172; 
Spring_Rigid 903207 103271 103272; 
Spring_Rigid 903307 103371 103372; 
Spring_Rigid 903407 103471 103472; 

####################################################################################################
#                                              FLOOR LINKS                                         #
####################################################################################################

# Command Syntax 
# element truss $ElementID $iNode $jNode $Area $matID
element truss 1007 407204 730 $A_Stiff 99;
element truss 1006 406204 630 $A_Stiff 99;
element truss 1005 405204 530 $A_Stiff 99;
element truss 1004 404204 430 $A_Stiff 99;
element truss 1003 403204 330 $A_Stiff 99;
element truss 1002 402204 230 $A_Stiff 99;

####################################################################################################
#                                          EGF COLUMNS AND BEAMS                                   #
####################################################################################################

# GRAVITY COLUMNS
element elasticBeamColumn  606300     633     731 67.5000 $E [expr (408.3750  + 242.0000)] $trans_PDelta; element elasticBeamColumn  606400     643     741 67.5000 $E [expr (408.3750  + 242.0000)] $trans_PDelta; 
element elasticBeamColumn  605302  105372     631 67.5000 $E [expr (408.3750  + 242.0000)] $trans_PDelta; element elasticBeamColumn  605402  105472     641 67.5000 $E [expr (408.3750  + 242.0000)] $trans_PDelta; 
element elasticBeamColumn  605301     533  105371  67.5000 $E [expr (408.3750  + 1676.0000)] $trans_PDelta; element elasticBeamColumn  605401     543  105471  67.5000 $E [expr (408.3750  + 1676.0000)] $trans_PDelta; 
element elasticBeamColumn  604300     433     531 81.0000 $E [expr (499.5000  + 1676.0000)] $trans_PDelta; element elasticBeamColumn  604400     443     541 81.0000 $E [expr (499.5000  + 1676.0000)] $trans_PDelta; 
element elasticBeamColumn  603302  103372     431 81.0000 $E [expr (499.5000  + 1676.0000)] $trans_PDelta; element elasticBeamColumn  603402  103472     441 81.0000 $E [expr (499.5000  + 1676.0000)] $trans_PDelta; 
element elasticBeamColumn  603301     333  103371  81.0000 $E [expr (499.5000  + 3620.0000)] $trans_PDelta; element elasticBeamColumn  603401     343  103471  81.0000 $E [expr (499.5000  + 3620.0000)] $trans_PDelta; 
element elasticBeamColumn  602300     233     331 89.4375 $E [expr (1221.7500  + 3620.0000)] $trans_PDelta; element elasticBeamColumn  602400     243     341 89.4375 $E [expr (1221.7500  + 3620.0000)] $trans_PDelta; 
element elasticBeamColumn  601300     133     231 89.4375 $E [expr (1221.7500  + 3620.0000)] $trans_PDelta; element elasticBeamColumn  601400     143     241 89.4375 $E [expr (1221.7500  + 3620.0000)] $trans_PDelta; 

# GRAVITY BEAMS
element elasticBeamColumn  507200     734     742  193.9000 $E [expr $Comp_I_GC * 18900.0000] $trans_PDelta;
element elasticBeamColumn  506200     634     642  214.2000 $E [expr $Comp_I_GC * 21700.0000] $trans_PDelta;
element elasticBeamColumn  505200     534     542  214.2000 $E [expr $Comp_I_GC * 21700.0000] $trans_PDelta;
element elasticBeamColumn  504200     434     442  214.2000 $E [expr $Comp_I_GC * 21700.0000] $trans_PDelta;
element elasticBeamColumn  503200     334     342  214.2000 $E [expr $Comp_I_GC * 21700.0000] $trans_PDelta;
element elasticBeamColumn  502200     234     242  214.2000 $E [expr $Comp_I_GC * 21700.0000] $trans_PDelta;

# GRAVITY COLUMNS SPRINGS
Spring_IMK   907301     730     731 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   907401     740     741 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   906303     630     633 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   906403     640     643 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   906301     630     631 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   906401     640     641 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   905303     530     533 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   905403     540     543 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   905301     530     531 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   905401     540     541 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   904303     430     433 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   904403     440     443 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   904301     430     431 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   904401     440     441 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   903303     330     333 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   903403     340     343 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   903301     330     331 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   903401     340     341 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   902303     230     233 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   902403     240     243 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   902301     230     231 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; Spring_IMK   902401     240     241 $E $Fy [expr (1221.7500 + 3620.0000)] 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 56334.5750 0 $Composite 0 2; 
Spring_IMK   901303     130     133 $E $Fy 3620.0000 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 40898.0000 0 $Composite 0 2; Spring_IMK   901403     140     143 $E $Fy 3620.0000 14.0000 25.9000 10.2000 3.7000 180.0000 90.0000 180.0000 40898.0000 0 $Composite 0 2; 

# GRAVITY BEAMS SPRINGS
set gap 0.08;
Spring_Pinching   907304     730     734 107569.0000 $gap 1; Spring_Pinching   907402     740     742 107569.0000 $gap 1; 
Spring_Pinching   906304     630     634 122391.5000 $gap 1; Spring_Pinching   906402     640     642 122391.5000 $gap 1; 
Spring_Pinching   905304     530     534 122391.5000 $gap 1; Spring_Pinching   905402     540     542 122391.5000 $gap 1; 
Spring_Pinching   904304     430     434 122391.5000 $gap 1; Spring_Pinching   904402     440     442 122391.5000 $gap 1; 
Spring_Pinching   903304     330     334 122391.5000 $gap 1; Spring_Pinching   903402     340     342 122391.5000 $gap 1; 
Spring_Pinching   902304     230     234 122391.5000 $gap 1; Spring_Pinching   902402     240     242 122391.5000 $gap 1; 

###################################################################################################
#                                       BOUNDARY CONDITIONS                                       #
###################################################################################################

# MF SUPPORTS
fix 110 1 1 1; 
fix 120 1 1 1; 

# EGF SUPPORTS
fix 130 1 1 0; fix 140 1 1 0; 

# MF FLOOR MOVEMENT
equalDOF 407104 407204 1; 
equalDOF 406104 406204 1; 
equalDOF 405104 405204 1; 
equalDOF 404104 404204 1; 
equalDOF 403104 403204 1; 
equalDOF 402104 402204 1; 

# BEAM MID-SPAN HORIZONTAL MOVEMENT CONSTRAINT
equalDOF 406104 206101 1; 
equalDOF 404104 204101 1; 
equalDOF 402104 202101 1; 

# EGF FLOOR MOVEMENT
equalDOF 730 740 1;
equalDOF 630 640 1;
equalDOF 530 540 1;
equalDOF 430 440 1;
equalDOF 330 340 1;
equalDOF 230 240 1;


##################################################################################################
##################################################################################################
                                       puts "Model Built"
##################################################################################################
##################################################################################################

###################################################################################################
#                                             RECORDERS                                           #
###################################################################################################

# EIGEN VECTORS
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode1.out -node 402104 403104 404104 405104 406104 407104  -dof 1 "eigen  1";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode2.out -node 402104 403104 404104 405104 406104 407104  -dof 1 "eigen  2";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode3.out -node 402104 403104 404104 405104 406104 407104  -dof 1 "eigen  3";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode4.out -node 402104 403104 404104 405104 406104 407104  -dof 1 "eigen  4";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode5.out -node 402104 403104 404104 405104 406104 407104  -dof 1 "eigen  5";
recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode6.out -node 402104 403104 404104 405104 406104 407104  -dof 1 "eigen  6";

# TIME
recorder Node -file $MainFolder/$SubFolder/Time.out  -time -node 110 -dof 1 disp;

# SUPPORT REACTIONS
recorder Node -file $MainFolder/$SubFolder/Support1.out -node     110 -dof 1 2 6 reaction; recorder Node -file $MainFolder/$SubFolder/Support2.out -node     120 -dof 1 2 6 reaction; recorder Node -file $MainFolder/$SubFolder/Support3.out -node     130 -dof 1 2 6 reaction; recorder Node -file $MainFolder/$SubFolder/Support4.out -node     140 -dof 1 2 6 reaction; 

# FLOOR LATERAL DISPLACEMENT
recorder Node -file $MainFolder/$SubFolder/Disp7_MF.out  -node  407104 -dof 1 disp; 
recorder Node -file $MainFolder/$SubFolder/Disp6_MF.out  -node  406104 -dof 1 disp; 
recorder Node -file $MainFolder/$SubFolder/Disp5_MF.out  -node  405104 -dof 1 disp; 
recorder Node -file $MainFolder/$SubFolder/Disp4_MF.out  -node  404104 -dof 1 disp; 
recorder Node -file $MainFolder/$SubFolder/Disp3_MF.out  -node  403104 -dof 1 disp; 
recorder Node -file $MainFolder/$SubFolder/Disp2_MF.out  -node  402104 -dof 1 disp; 

# STORY DRIFT RATIO
recorder Drift -file $MainFolder/$SubFolder/SDR6_MF.out -iNode  406104 -jNode  407104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR5_MF.out -iNode  405104 -jNode  406104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR4_MF.out -iNode  404104 -jNode  405104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR3_MF.out -iNode  403104 -jNode  404104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR2_MF.out -iNode  402104 -jNode  403104 -dof 1 -perpDirn 2; 
recorder Drift -file $MainFolder/$SubFolder/SDR1_MF.out -iNode     110 -jNode  402104 -dof 1 -perpDirn 2; 

# FLOOR ACCELERATION
recorder Node -file $MainFolder/$SubFolder/RFA7_MF.out -node 407104 -dof 1 accel; 
recorder Node -file $MainFolder/$SubFolder/RFA6_MF.out -node 406104 -dof 1 accel; 
recorder Node -file $MainFolder/$SubFolder/RFA5_MF.out -node 405104 -dof 1 accel; 
recorder Node -file $MainFolder/$SubFolder/RFA4_MF.out -node 404104 -dof 1 accel; 
recorder Node -file $MainFolder/$SubFolder/RFA3_MF.out -node 403104 -dof 1 accel; 
recorder Node -file $MainFolder/$SubFolder/RFA2_MF.out -node 402104 -dof 1 accel; 
recorder Node -file $MainFolder/$SubFolder/RFA1_MF.out -node 110 -dof 1 accel; 

# FLOOR LINK FORCE
recorder Element -file $MainFolder/$SubFolder/FloorLink7_F.out -ele    1007 force;
recorder Element -file $MainFolder/$SubFolder/FloorLink6_F.out -ele    1006 force;
recorder Element -file $MainFolder/$SubFolder/FloorLink5_F.out -ele    1005 force;
recorder Element -file $MainFolder/$SubFolder/FloorLink4_F.out -ele    1004 force;
recorder Element -file $MainFolder/$SubFolder/FloorLink3_F.out -ele    1003 force;
recorder Element -file $MainFolder/$SubFolder/FloorLink2_F.out -ele    1002 force;

# FLOOR LINK DEFORMATION
recorder Element -file $MainFolder/$SubFolder/FloorLink7_D.out -ele    1007 deformation;
recorder Element -file $MainFolder/$SubFolder/FloorLink6_D.out -ele    1006 deformation;
recorder Element -file $MainFolder/$SubFolder/FloorLink5_D.out -ele    1005 deformation;
recorder Element -file $MainFolder/$SubFolder/FloorLink4_D.out -ele    1004 deformation;
recorder Element -file $MainFolder/$SubFolder/FloorLink3_D.out -ele    1003 deformation;
recorder Element -file $MainFolder/$SubFolder/FloorLink2_D.out -ele    1002 deformation;

# COLUMN ELASTIC ELEMENT FORCES
recorder Element -file $MainFolder/$SubFolder/Column61.out -ele  606100 force; recorder Element -file $MainFolder/$SubFolder/Column62.out -ele  606200 force; recorder Element -file $MainFolder/$SubFolder/Column63.out -ele  606300 force; recorder Element -file $MainFolder/$SubFolder/Column64.out -ele  606400 force; 
recorder Element -file $MainFolder/$SubFolder/Column51.out -ele  605101 force; recorder Element -file $MainFolder/$SubFolder/Column52.out -ele  605201 force; recorder Element -file $MainFolder/$SubFolder/Column53.out -ele  605301 force; recorder Element -file $MainFolder/$SubFolder/Column54.out -ele  605401 force; 
recorder Element -file $MainFolder/$SubFolder/Column41.out -ele  604100 force; recorder Element -file $MainFolder/$SubFolder/Column42.out -ele  604200 force; recorder Element -file $MainFolder/$SubFolder/Column43.out -ele  604300 force; recorder Element -file $MainFolder/$SubFolder/Column44.out -ele  604400 force; 
recorder Element -file $MainFolder/$SubFolder/Column31.out -ele  603101 force; recorder Element -file $MainFolder/$SubFolder/Column32.out -ele  603201 force; recorder Element -file $MainFolder/$SubFolder/Column33.out -ele  603301 force; recorder Element -file $MainFolder/$SubFolder/Column34.out -ele  603401 force; 
recorder Element -file $MainFolder/$SubFolder/Column21.out -ele  602100 force; recorder Element -file $MainFolder/$SubFolder/Column22.out -ele  602200 force; recorder Element -file $MainFolder/$SubFolder/Column23.out -ele  602300 force; recorder Element -file $MainFolder/$SubFolder/Column24.out -ele  602400 force; 
recorder Element -file $MainFolder/$SubFolder/Column11.out -ele  601100 force; recorder Element -file $MainFolder/$SubFolder/Column12.out -ele  601200 force; recorder Element -file $MainFolder/$SubFolder/Column13.out -ele  601300 force; recorder Element -file $MainFolder/$SubFolder/Column14.out -ele  601400 force; 

# BRACE ELEMENTS
recorder Element -file $MainFolder/$SubFolder/Brace11L_F.out -ele   701111 localForce;
recorder Element -file $MainFolder/$SubFolder/Brace11R_F.out -ele   701211 localForce;

recorder Element -file $MainFolder/$SubFolder/Brace21L_F.out -ele   703199 localForce;
recorder Element -file $MainFolder/$SubFolder/Brace21R_F.out -ele   703299 localForce;

recorder Element -file $MainFolder/$SubFolder/Brace31L_F.out -ele   703111 localForce;
recorder Element -file $MainFolder/$SubFolder/Brace31R_F.out -ele   703211 localForce;

recorder Element -file $MainFolder/$SubFolder/Brace41L_F.out -ele   705199 localForce;
recorder Element -file $MainFolder/$SubFolder/Brace41R_F.out -ele   705299 localForce;

recorder Element -file $MainFolder/$SubFolder/Brace51L_F.out -ele   705111 localForce;
recorder Element -file $MainFolder/$SubFolder/Brace51R_F.out -ele   705211 localForce;

recorder Element -file $MainFolder/$SubFolder/Brace61L_F.out -ele   707199 localForce;
recorder Element -file $MainFolder/$SubFolder/Brace61R_F.out -ele   707299 localForce;


# BRACE AXIAL DEFORMATION FROM GHOST BRACES
recorder Element -file $MainFolder/$SubFolder/Brace11L_D.out -ele  4101100 deformation;
recorder Element -file $MainFolder/$SubFolder/Brace11R_D.out -ele  4201100 deformation;

recorder Element -file $MainFolder/$SubFolder/Brace21L_D.out -ele  4102100 deformation;
recorder Element -file $MainFolder/$SubFolder/Brace21R_D.out -ele  4202100 deformation;

recorder Element -file $MainFolder/$SubFolder/Brace31L_D.out -ele  4103100 deformation;
recorder Element -file $MainFolder/$SubFolder/Brace31R_D.out -ele  4203100 deformation;

recorder Element -file $MainFolder/$SubFolder/Brace41L_D.out -ele  4104100 deformation;
recorder Element -file $MainFolder/$SubFolder/Brace41R_D.out -ele  4204100 deformation;

recorder Element -file $MainFolder/$SubFolder/Brace51L_D.out -ele  4105100 deformation;
recorder Element -file $MainFolder/$SubFolder/Brace51R_D.out -ele  4205100 deformation;

recorder Element -file $MainFolder/$SubFolder/Brace61L_D.out -ele  4106100 deformation;
recorder Element -file $MainFolder/$SubFolder/Brace61R_D.out -ele  4206100 deformation;


###################################################################################################
#                                              NODAL MASS                                         #
###################################################################################################

set g 386.10;
mass 407104 0.2509  1.e-9 1.e-9; mass 407204 0.2509  1.e-9 1.e-9; mass 730 1.0808  1.e-9 1.e-9; mass 740 1.0808  1.e-9 1.e-9; 
mass 406104 0.3969  1.e-9 1.e-9; mass 406204 0.3969  1.e-9 1.e-9; mass 630 1.0078  1.e-9 1.e-9; mass 640 1.0078  1.e-9 1.e-9; 
mass 405104 0.3969  1.e-9 1.e-9; mass 405204 0.3969  1.e-9 1.e-9; mass 530 1.0078  1.e-9 1.e-9; mass 540 1.0078  1.e-9 1.e-9; 
mass 404104 0.3969  1.e-9 1.e-9; mass 404204 0.3969  1.e-9 1.e-9; mass 430 1.0078  1.e-9 1.e-9; mass 440 1.0078  1.e-9 1.e-9; 
mass 403104 0.3969  1.e-9 1.e-9; mass 403204 0.3969  1.e-9 1.e-9; mass 330 1.0078  1.e-9 1.e-9; mass 340 1.0078  1.e-9 1.e-9; 
mass 402104 0.3969  1.e-9 1.e-9; mass 402204 0.3969  1.e-9 1.e-9; mass 230 1.0078  1.e-9 1.e-9; mass 240 1.0078  1.e-9 1.e-9; 

constraints Plain;

###################################################################################################
#                                        EIGEN VALUE ANALYSIS                                     #
###################################################################################################

set pi [expr 2.0*asin(1.0)];
set nEigen 6;
set lambdaN [eigen [expr $nEigen]];
set lambda1 [lindex $lambdaN 0];
set lambda2 [lindex $lambdaN 1];
set lambda3 [lindex $lambdaN 2];
set lambda4 [lindex $lambdaN 3];
set lambda5 [lindex $lambdaN 4];
set lambda6 [lindex $lambdaN 5];
set w1 [expr pow($lambda1,0.5)];
set w2 [expr pow($lambda2,0.5)];
set w3 [expr pow($lambda3,0.5)];
set w4 [expr pow($lambda4,0.5)];
set w5 [expr pow($lambda5,0.5)];
set w6 [expr pow($lambda6,0.5)];
set T1 [expr round(2.0*$pi/$w1 *1000.)/1000.];
set T2 [expr round(2.0*$pi/$w2 *1000.)/1000.];
set T3 [expr round(2.0*$pi/$w3 *1000.)/1000.];
set T4 [expr round(2.0*$pi/$w4 *1000.)/1000.];
set T5 [expr round(2.0*$pi/$w5 *1000.)/1000.];
set T6 [expr round(2.0*$pi/$w6 *1000.)/1000.];
puts "T1 = $T1 s";
puts "T2 = $T2 s";
puts "T3 = $T3 s";
cd $RFpath;
cd "Results"
cd "EigenAnalysis"
set fileX [open "EigenPeriod.out" w];
puts $fileX $T1;puts $fileX $T2;puts $fileX $T3;puts $fileX $T4;puts $fileX $T5;puts $fileX $T6;close $fileX;
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
#                                      STATIC GRAVITY ANALYSIS                                    #
###################################################################################################

pattern Plain 100 Linear {

	# MF COLUMNS LOADS
	load 407103 0. -59.703 0.; 	load 407203 0. -59.703 0.; 
	load 406103 0. -82.471 0.; 	load 406203 0. -82.471 0.; 
	load 405103 0. -82.471 0.; 	load 405203 0. -82.471 0.; 
	load 404103 0. -82.471 0.; 	load 404203 0. -82.471 0.; 
	load 403103 0. -82.471 0.; 	load 403203 0. -82.471 0.; 
	load 402103 0. -82.471 0.; 	load 402203 0. -82.471 0.; 

	# EGF COLUMN LOADS
	load 730 0. -615.301920 0.; 	load 740 0. -615.301920 0.; 
	load 630 0. -824.307840 0.; 	load 640 0. -824.307840 0.; 
	load 530 0. -824.307840 0.; 	load 540 0. -824.307840 0.; 
	load 430 0. -824.307840 0.; 	load 440 0. -824.307840 0.; 
	load 330 0. -824.307840 0.; 	load 340 0. -824.307840 0.; 
	load 230 0. -824.307840 0.; 	load 240 0. -824.307840 0.; 

}

# Conversion Parameters
constraints Plain;
numberer RCM;
system BandGeneral;
test NormDispIncr 1.0e-5 60 ;
algorithm Newton;
integrator LoadControl 0.1;
analysis Static;
analyze 10;

loadConst -time 0.0;

###################################################################################################
###################################################################################################
										puts "Gravity Done"
###################################################################################################
###################################################################################################

puts "Seismic Weight= 10417.799 kip";
puts "Seismic Mass=  16.711 kip.sec2/in";

if {$ShowAnimation == 1} {
	DisplayModel3D DeformedShape 5.00 100 100  1000 750;
}

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
region 1 -ele  606100 606200 605102 605202 605101 605201 604100 604200 603102 603202 603101 603201 602100 602200 601100 601200 507100 506101 506102 505100 504101 504102 503100 502101 502102  -rayleigh 0.0 0.0 $a1_mod 0.0;
region 2 -node  402104 402204 230 240 403104 403204 330 340 404104 404204 430 440 405104 405204 530 540 406104 406204 630 640 407104 407204 730 740  -rayleigh $a0 0.0 0.0 0.0;
region 3 -eleRange  900000  999999 -rayleigh 0.0 0.0 [expr $a1_mod/10] 0.0;

# GROUND MOTION ACCELERATION FILE INPUT
set AccelSeries "Series -dt $GMdt -filePath GM.txt -factor  [expr $EqSF * $g]"
pattern UniformExcitation  200 1 -accel $AccelSeries

set MF_FloorNodes [list  402104 403104 404104 405104 406104 407104 ];
set EGF_FloorNodes [list  230 330 430 530 630 730 ];
set GMduration [expr $GMdt*$GMpoints];
set FVduration 0.000000;
set NumSteps [expr round(($GMduration + $FVduration)/$GMdt)];	# number of steps in analysis
set totTime [expr $GMdt*$NumSteps];                            # Total time of analysis
set dtAnalysis [expr 1.000000*$GMdt];                             	# dt of Analysis

DynamicAnalysisCollapseSolverX  $GMdt	$dtAnalysis	$totTime $NStory	 0.15   $MF_FloorNodes	$EGF_FloorNodes	180.00 180.00 1 $StartTime $MaxRunTime;

###################################################################################################
###################################################################################################
							puts "Ground Motion Done. End Time: [getTime]"
###################################################################################################
###################################################################################################
}

wipe all;
