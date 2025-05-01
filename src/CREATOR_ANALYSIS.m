function CREATOR_ANALYSIS (AnalysisTypeID,TempPOrun)

arguments
    AnalysisTypeID   (1,1) {mustBePositive, mustBeInteger}
    TempPOrun (1,1) {mustBeInteger}
end


clc;
global ProjectName ProjectPath
load(strcat(ProjectPath,ProjectName))

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

write_Analysis_Eigen(INP,FrameType,NStory,AnalysisTypeID,ModePO);

if EV~=1 && AnalysisTypeID~=1
    if FrameType==1 && LoadApplyOption==2
        write_Analysis_Gravity_BeamUniform(INP);
    else
        write_Analysis_Gravity(INP);
    end
    write_Animation(INP,AnimSF,AnimX,AnimY);
end

if AnalysisTypeID==2
    write_Analysis_Pushover(INP,NStory,DriftPO,PZ_Multiplier,FrameType,Units);
elseif AnalysisTypeID==3
    write_Analysis_Dynamic(INP,NStory,NBay,HStory,zeta,DampModeI,DampModeJ,TFreeVibration,dtstep,EL_ELEMENTS,PZ_Multiplier,CollapseSDR);
elseif AnalysisTypeID==4
    write_Analysis_ELF(INP,NStory,ELF_Profile);
elseif AnalysisTypeID==5
    write_Analysis_Pushover_Tsunami_CDPO(INP,NStory,DriftPO,Units);
elseif AnalysisTypeID==6
    write_Analysis_TTH(INP,NStory,NBay,HStory,zeta,DampModeI,DampModeJ,dtstep,EL_ELEMENTS,PZ_Multiplier,CollapseSDR, Floor_F, TTHdt)
end

fprintf(INP,'wipe all;\n');