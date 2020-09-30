function write_ResultsFolder (INP, AnalysisTypeID,TempPOrun,Uncertainty)

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                          Create Results Folders                                  #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

if AnalysisTypeID ==1
    fprintf(INP,'set SubFolder  "EigenAnalysis";\n');
    fprintf(INP,'cd $RFpath;\n');
    fprintf(INP,'file mkdir "Results";\n');
    fprintf(INP,'cd "Results"\n');
    fprintf(INP,'file mkdir $SubFolder;\n');
    fprintf(INP,'cd $MainDir;\n');
    fprintf(INP,'\n');
end

if AnalysisTypeID ==2
    if TempPOrun==1
        fprintf(INP,'set SubFolder  "TempPushover";\n');
    else
        fprintf(INP,'set SubFolder  "Pushover";\n');
    end
    fprintf(INP,'cd $RFpath;\n');
    fprintf(INP,'file mkdir "Results";\n');
    fprintf(INP,'cd "Results"\n');
    fprintf(INP,'file mkdir $SubFolder;\n');
    fprintf(INP,'cd $MainDir;\n');
    fprintf(INP,'\n');
end

if AnalysisTypeID ==3
    fprintf(INP,'# RESULT FOLDER\n');
    if Uncertainty==0; fprintf(INP,'set SubFolder  $GMname;\n'); end
    if Uncertainty==1; fprintf(INP,'set SubFolder  $Subfoldername;\n'); end
    fprintf(INP,'cd $RFpath;\n');
    fprintf(INP,'file mkdir "Results";\n');
    fprintf(INP,'cd "Results"\n');
    fprintf(INP,'file mkdir $SubFolder;\n');
    fprintf(INP,'cd $MainDir;\n');
    fprintf(INP,'\n');
end

if AnalysisTypeID ==4
    fprintf(INP,'set SubFolder  "ELF";\n');
    fprintf(INP,'cd $RFpath;\n');
    fprintf(INP,'file mkdir "Results";\n');
    fprintf(INP,'cd "Results"\n');
    fprintf(INP,'file mkdir $SubFolder;\n');
    fprintf(INP,'cd $MainDir;\n');
    fprintf(INP,'\n');
end