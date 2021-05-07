function write_OpenArguments(INP, NStory, FrameType, EQ, PO, ELF, MaxRunTime, CompositeX, Animation, MainDirectory, RFpath, ModePO, DriftPO, DampModeI, DampModeJ, zeta, BuildOption, AnalysisTypeID)

% HEADER LINES
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'####################################################################################################\n');
if FrameType==1; fprintf(INP,'#                                        %d-story MRF Building\n',NStory); end
if FrameType==2; fprintf(INP,'#                                        %d-story CBF Building\n',NStory); end
if FrameType==3; fprintf(INP,'#                                        %d-story EBF Building\n',NStory); end
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# CLEAR ALL;\n');
fprintf(INP,'wipe all;\n');
fprintf(INP,'\n');

fprintf(INP,'# BUILD MODEL (2D - 3 DOF/node)\n');
fprintf(INP,'model basic -ndm 2 -ndf 3\n');
fprintf(INP,'\n');

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                        BASIC MODEL VARIABLES                                     #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'set  global RunTime;\n');
fprintf(INP,'set  global StartTime;\n');
fprintf(INP,'set  global MaxRunTime;\n');
fprintf(INP,'set  MaxRunTime [expr %.4f * 60.];\n',MaxRunTime);
fprintf(INP,'set  StartTime [clock seconds];\n');
fprintf(INP,'set  RunTime 0.0;\n');
fprintf(INP,'set  EQ %d;\n',EQ);
fprintf(INP,'set  PO %d;\n',PO);
fprintf(INP,'set  ELF %d;\n',ELF);
fprintf(INP,'set  Composite %d;\n',CompositeX);
fprintf(INP,'set  ShowAnimation %d;\n',Animation);
fprintf(INP,'set  MainDir {%s};\n',MainDirectory);
fprintf(INP,'set  RFpath {%s};\n',RFpath);
fprintf(INP,'set  MainFolder {%s};\n',[RFpath,'\Results']);
fprintf(INP,'set  ModePO %d;\n',ModePO);
fprintf(INP,'set  DriftPO %f;\n',DriftPO);
fprintf(INP,'set  DampModeI %d;\n',DampModeI);
fprintf(INP,'set  DampModeJ %d;\n',DampModeJ);
fprintf(INP,'set  zeta %f;\n',zeta);
fprintf(INP,'\n');

if BuildOption==2
    if AnalysisTypeID==3
        fprintf(INP,'########################################################################\n');
        fprintf(INP,'#Code Below is Only Needed To Run Dynamic Analysis through MATLAB Code #\n');
        fprintf(INP,'########################################################################\n');
        fprintf(INP,'\n');

        fprintf(INP,'# Opens file to read (r) the scale factor\n');
        fprintf(INP,'set fileID1 [open SF.txt r];  \n');
        fprintf(INP,'set EqSF [read $fileID1];\n');
        fprintf(INP,'\n');
        fprintf(INP,'# Opens file to read (r) the current GM info\n');
        fprintf(INP,'set fileID2 [open GMinfo.txt r];\n');
        fprintf(INP,'gets  $fileID2 GMid\n');
        fprintf(INP,'gets  $fileID2 GMname\n');
        fprintf(INP,'gets  $fileID2 GMpoints\n');
        fprintf(INP,'gets  $fileID2 GMdt\n');
        fprintf(INP,'gets  $fileID2 Subfoldername\n');
        fprintf(INP,'\n');
    end
end
