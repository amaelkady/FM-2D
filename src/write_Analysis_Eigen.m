function write_Analysis_Eigen(INP,NStory,AnalysisTypeID,ModePO)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                        EIGEN VALUE ANALYSIS                                     #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'set pi [expr 2.0*asin(1.0)];\n');
fprintf(INP,'set nEigen %d;\n', NStory);
fprintf(INP,'set lambdaN [eigen [expr $nEigen]];\n');
for i=1:NStory
    fprintf(INP,'set lambda%d [lindex $lambdaN %d];\n',i,i-1);
end
for i=1:NStory
    fprintf(INP,'set w%d [expr pow($lambda%d,0.5)];\n',i,i);
end
for i=1:NStory
    fprintf(INP,'set T%d [expr round(2.0*$pi/$w%d *1000.)/1000.];\n',i,i);
end
for i=1:min(3,NStory)
    fprintf(INP,'puts "T%d = $T%d s";\n',i,i);
end

fprintf(INP,'cd $RFpath;\n');
fprintf(INP,'cd "Results"\n');    
fprintf(INP,'cd "EigenAnalysis"\n');    
fprintf(INP,'set fileX [open "EigenPeriod.out" w];\n');
for i=1:NStory
    fprintf(INP,'puts $fileX $T%d;',i);
end
fprintf(INP,'close $fileX;\n');
fprintf(INP,'cd $MainDir;\n');
fprintf(INP,'\n');

if AnalysisTypeID==1 || AnalysisTypeID==2
% Record mode eigen vector for pushover
fprintf(INP,'# Eigen Mode\n');
fprintf(INP,'recorder Node -file POmodepattern.out -node ');
for i=2:NStory+1
	nodeID=400000+i*1000+1*100+04;
	fprintf(INP,'%d ', nodeID);
end
fprintf(INP,' -dof 1 "eigen  %d";\n',ModePO);
fprintf(INP,'\n');
end

fprintf(INP,'constraints Plain;\n');
fprintf(INP,'algorithm Newton;\n');
fprintf(INP,'integrator LoadControl 1;\n');
fprintf(INP,'analysis Static;\n');
fprintf(INP,'analyze 1;\n');
fprintf(INP,'\n');


fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'									puts "Eigen Analysis Done"\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');