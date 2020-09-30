function write_Analysis_Dynamic(INP,NStory,NBay,HStory,zeta,DampModeI,DampModeJ,TFreeVibration,dtstep,EL_ELEMENTS,PZ_Multiplier,CollapseSDR)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                   DYNAMIC EARTHQUAKE ANALYSIS                                   #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'if {$EQ==1} {\n');
fprintf(INP,'\n');

fprintf(INP,'# Rayleigh Damping\n');
fprintf(INP,'global Sigma_zeta; global xRandom;\n');
fprintf(INP,'set zeta %5.3f;\n',zeta);
fprintf(INP,'set SigmaX $Sigma_zeta; Generate_lognrmrand $zeta 		$SigmaX; 		set zeta 	$xRandom;\n');
fprintf(INP,'set a0 [expr $zeta*2.0*$w%d*$w%d/($w%d + $w%d)];\n',DampModeI,DampModeJ,DampModeI,DampModeJ);
fprintf(INP,'set a1 [expr $zeta*2.0/($w%d + $w%d)];\n',DampModeI,DampModeJ);
fprintf(INP,'set a1_mod [expr $a1*(1.0+$n)/$n];\n');

fprintf(INP,'region 1 -ele  ');
for i=1:size(EL_ELEMENTS,1)
    fprintf(INP,'%d ',EL_ELEMENTS(i,1));
end
fprintf(INP,' -rayleigh 0.0 0.0 $a1_mod 0.0;\n');

fprintf(INP,'region 2 -node  ');
for Floor=2:NStory+1
    for Axis=1:NBay+3
        if PZ_Multiplier==1; nodeIDmf=400000+1000*Floor+100*Axis+04; else; nodeIDmf=(10*Floor+Axis)*10; end
        nodeIDegf=(10*Floor+Axis)*10;
        if Axis<NBay+2; 	fprintf(INP,'%d ',nodeIDmf); end
        if Axis>=NBay+2; 	fprintf(INP,'%d ',nodeIDegf); end
    end
end
fprintf(INP,' -rayleigh $a0 0.0 0.0 0.0;\n');

fprintf(INP,'region 3 -eleRange  900000  999999 -rayleigh 0.0 0.0 [expr $a1_mod/10] 0.0;\n');
fprintf(INP,'\n');

fprintf(INP,'# GROUND MOTION ACCELERATION FILE INPUT\n');
fprintf(INP,'set AccelSeries "Series -dt $GMdt -filePath GM.txt -factor  [expr $EqSF * $g]"\n');
fprintf(INP,'pattern UniformExcitation  200 1 -accel $AccelSeries\n');
fprintf(INP,'\n');

fprintf(INP,'set MF_FloorNodes [list  ');
for Floor=2:NStory+1
    nodeID=400000+Floor*1000+1*100+04;
    if Floor==1;  fprintf(INP,'110 '); else fprintf(INP,'%d ', nodeID); end
end
fprintf(INP,'];\n');

fprintf(INP,'set EGF_FloorNodes [list  ');
for Floor=2:NStory+1
    nodeID=(Floor*10+(NBay+2))*10;
    fprintf(INP,'%d ',nodeID);
end
fprintf(INP,'];\n');

fprintf(INP,'set GMduration [expr $GMdt*$GMpoints];\n');
fprintf(INP,'set FVduration %f;\n',TFreeVibration);
fprintf(INP,'set NumSteps [expr round(($GMduration + $FVduration)/$GMdt)];	# number of steps in analysis\n');
fprintf(INP,'set totTime [expr $GMdt*$NumSteps];                            # Total time of analysis\n');
fprintf(INP,'set dtAnalysis [expr %f*$GMdt];                             	# dt of Analysis\n',dtstep);
fprintf(INP,'\n');

fprintf(INP,'DynamicAnalysisCollapseSolverX  $GMdt	$dtAnalysis	$totTime $NStory	%5.2f   $MF_FloorNodes	$EGF_FloorNodes	%5.2f %5.2f 1 $StartTime $MaxRunTime;\n',CollapseSDR,HStory(1), HStory(2));
fprintf(INP,'\n');

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'							puts "Ground Motion Done. End Time: [getTime]"\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'}\n');
fprintf(INP,'\n');