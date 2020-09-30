function CREATOR_ANALYSIS (AnalysisTypeID,TempPOrun)
global MainDirectory ProjectName ProjectPath
clc;
cd(ProjectPath)
load(ProjectName)
cd(MainDirectory)

% Open Existing tcl File to Write Appended Code
if AnalysisTypeID==1
    PO=0;
    ELF=0;
    EQ=0;
    INP = fopen('TempModel.tcl','a');
elseif TempPOrun==1  && AnalysisTypeID==2
    PO=1;
    ELF=0;
    EQ=0;
    INP = fopen('TempModelPO.tcl','a');
else
    INP = fopen(OpenSEESFileName,'a');
end

write_Analysis_Eigen(INP,NStory,AnalysisTypeID,ModePO);

if EV~=1 && AnalysisTypeID~=1
    write_Analysis_Gravity(INP);
    write_Animation(INP,AnimSF,AnimX,AnimY);
end

if AnalysisTypeID==2
    write_Analysis_Pushover(INP,NStory,DriftPO,Units);
end

if AnalysisTypeID==4
    write_Analysis_ELF(INP,NStory,ELF_Profile);
end

if AnalysisTypeID==3
    write_Analysis_Dynamic(INP,NStory,NBay,HStory,zeta,DampModeI,DampModeJ,TFreeVibration,dtstep,EL_ELEMENTS,PZ_Multiplier,CollapseSDR);
end

fprintf(INP,'wipe all;\n');