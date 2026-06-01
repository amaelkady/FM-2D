function CREATOR_ANALYSIS (AnalysisTypeID,TempPOrun)

arguments
    AnalysisTypeID   (1,1) {mustBePositive, mustBeInteger}
    TempPOrun (1,1) {mustBeInteger}
end

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'FrameType','EV','LoadApplyOption','OpenSEESFileName');

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

write_Analysis_Eigen(INP,AnalysisTypeID);

if EV~=1 && AnalysisTypeID~=1
    if FrameType==1 && LoadApplyOption==2
        write_Analysis_Gravity_BeamUniform(INP);
    else
        write_Analysis_Gravity(INP);
    end
    write_Animation(INP);
end

if AnalysisTypeID==2
    write_Analysis_Pushover(INP);
elseif AnalysisTypeID==3
    write_Analysis_Dynamic(INP);
elseif AnalysisTypeID==4
    write_Analysis_ELF(INP);
elseif AnalysisTypeID==5
    write_Analysis_Pushover_Tsunami_CDPO(INP);
elseif AnalysisTypeID==6
    write_Analysis_TTH(INP)
end

fprintf(INP,'wipe all;\n');