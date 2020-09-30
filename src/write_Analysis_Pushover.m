function write_Analysis_Pushover(INP,NStory,DriftPO,Units)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#											Pushover Analysis                     		    	   #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');


fprintf(INP,'if {$PO==1} {\n');
fprintf(INP,'\n');

XX=importdata('POmodepattern.out');
EigenVal=XX(1,:);

fprintf(INP,'# Create Load Pattern\n');
fprintf(INP,'pattern Plain 222 Linear {\n');
for Floor=NStory+1:-1:2
    nodeID=400000+Floor*1000+1*100+03;
    fprintf(INP,'	load %d %7.5f 0.0 0.0\n',nodeID,EigenVal(1,Floor-1));
end
fprintf(INP,'}\n');
fprintf(INP,'\n');

fprintf(INP,'# Displacement Control Parameters\n');
nodeID=400000+(NStory+1)*1000+1*100+04;
fprintf(INP,'set CtrlNode %d;\n', nodeID);
fprintf(INP,'set CtrlDOF 1;\n');
fprintf(INP,'set Dmax [expr %5.3f*$Floor%d];\n',DriftPO,NStory+1);
if Units==1
    fprintf(INP,'set Dincr [expr 0.5];\n');
else
    fprintf(INP,'set Dincr [expr 0.005];\n');
end
fprintf(INP,'\n');

fprintf(INP,'set Nsteps [expr int($Dmax/$Dincr)];\n');
fprintf(INP,'set ok 0;\n');
fprintf(INP,'set controlDisp 0.0;\n');
fprintf(INP,'source LibAnalysisStaticParameters.tcl;\n');
fprintf(INP,'source SolutionAlgorithm.tcl;\n');

fprintf(INP,'}\n');
fprintf(INP,'\n');

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#										puts "Pushover complete"\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');