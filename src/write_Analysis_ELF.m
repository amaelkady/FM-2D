function write_Analysis_ELF(INP)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'NStory','ELF_Profile','FrameType','PZ_Multiplier');


fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#											ELF Analysis										   #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'if {$ELF==1} {\n');
fprintf(INP,'\n');

fprintf(INP,'# Create Load Pattern\n');
fprintf(INP,'pattern Plain 222 Linear {\n');
for Fi=NStory+1:-1:2
    if PZ_Multiplier==1 && FrameType~=4
        nodeID=400000+Fi*1000+1*100+03;
    else
        nodeID=(10*Fi+1)*10;
    end
    fprintf(INP,'	load %d %7.5f 0.0 0.0\n',nodeID,ELF_Profile(Fi-1,1));
end
fprintf(INP,'}\n');
fprintf(INP,'\n');

fprintf(INP,'# Conversion Parameters\n');
fprintf(INP,'constraints Plain;\n');
fprintf(INP,'numberer RCM;\n');
fprintf(INP,'system BandGeneral;\n');
fprintf(INP,'test NormDispIncr 1.0e-5 60 ;\n');
fprintf(INP,'algorithm Newton;\n');
fprintf(INP,'integrator LoadControl 0.1;\n');
fprintf(INP,'analysis Static;\n');
fprintf(INP,'FM2D_BeginStage STATIC;\n');
fprintf(INP,'set elfOK [FM2D_AnalyzeStaticChecked 10];\n');
fprintf(INP,'if {$elfOK != 0 || abs([getTime]-1.0) > 1.0e-8} {;\n');
fprintf(INP,'    error "ELF analysis failed or did not reach the target load factor";\n');
fprintf(INP,'};\n');
fprintf(INP,'FM2D_FinishStage COMPLETED [getTime] 1.0;\n');
fprintf(INP,'\n');

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#									puts "ELF complete"\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'}\n');
fprintf(INP,'\n');
