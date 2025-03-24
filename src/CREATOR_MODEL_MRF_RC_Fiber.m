function CREATOR_MODEL_MRF_RC_Fiber (AnalysisTypeID,TempPOrun)
global MainDirectory ProjectName ProjectPath
clc;
cd(ProjectPath)
load(ProjectName)
cd(MainDirectory)

if TempPOrun==1; PM_Option=2; end

% Open File to Write Code
if AnalysisTypeID==1
    PO=0;
    ELF=0;
    EQ=0;
    INP = fopen('TempModel.tcl','w+');
elseif TempPOrun==1  && AnalysisTypeID==2
    PO=1;
    ELF=0;
    EQ=0;
    INP = fopen('TempModelPO.tcl','w+');
else
    INP = fopen(OpenSEESFileName,'w+');
end

if Analysisstatus==1
    write_OpenArguments(INP, NStory, FrameType, EQ, PO, ELF, CDPO, TTH, MaxRunTime, CompositeX, Animation, MainDirectory, RFpath, ModePO, DriftPO, DampModeI, DampModeJ, zeta, BuildOption, AnalysisTypeID);
else
    write_OpenArguments(INP, NStory, FrameType, 0, 0, 0, 0, 0, 60, CompositeX, 0, MainDirectory, RFpath, 1, 0.1, 1, NStory, 0.02, 2, AnalysisTypeID);    
end

write_SourceSubroutine (INP, FrameType,AnalysisTypeID,ColElementOption,GFX,PZ_Multiplier);

write_ResultsFolder (INP, AnalysisTypeID,TempPOrun,Uncertainty);

write_BasicInput (INP, FrameType,NStory,NBay,CompositeX,Comp_I,Comp_I_GC,Units,E,mu0,fy,fyBrace,fyGP,Er,fyR,muR,Ec,fc,muC,EL_Multiplier,SteelMatID,TransformationX,nSegments,initialGI,nIntegration,Sigma, Uncertainty);

write_PreCalculatedGeometry (INP, NStory, NBay, HStory, WBay, WBuilding, MF_BEAMS, CGP_RigidOffset, MGP_RigidOffset, a, b, FrameType, Units);

write_Nodes_FiberFrame (INP, NStory, NBay, HStory);

[EL_ELEMENTS] = write_BeamsColumns_FiberFrame (INP, NStory, NBay, ColElementOption, MF_COLUMNS, MF_BEAMS, nIntegration, coeff_cracked);

write_FloorLinks_FiberFrame (INP,NStory,NBay,WBay,FloorLink,Fs,Fs_Profile);

write_EGFelements_FiberFrame (INP,NStory,NBay,GFX,Orientation,nMF,nGC,nGB,MF_COLUMNS,GF_COLUMNS,GF_BEAMS)

write_EGFsprings_FiberFrame (INP,NStory,NBay,GFX);

write_BCs_FiberFrame (INP,NStory,NBay,RigidFloor,Support);

write_Recorders_FiberFrame(INP, NStory, NBay, Recorders, Filename, FloorLink, AnalysisTypeID);

write_Mass_FiberFrame(INP, EL_ELEMENTS);