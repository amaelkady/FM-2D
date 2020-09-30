function write_Analysis_ELF(INP,NStory,ELF_Profile)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#											ELF Analysis										   #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'if {$ELF==1} {\n');
fprintf(INP,'\n');

fprintf(INP,'# Create Load Pattern\n');
fprintf(INP,'pattern Plain 222 Linear {\n');
for Floor=NStory+1:-1:2
    nodeID=400000+Floor*1000+1*100+03;
    fprintf(INP,'	load %d %7.5f 0.0 0.0\n',nodeID,ELF_Profile(Floor-1,1));
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
fprintf(INP,'analyze 10;\n');
fprintf(INP,'\n');

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#									puts "ELF complete"\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'}\n');
fprintf(INP,'\n');