function CREATOR_MODEL_MRF_RC (AnalysisTypeID,TempPOrun)
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
    write_OpenArguments(INP, NStory, FrameType,  0, 0, 0, 0, 0, 60, CompositeX, 0, MainDirectory, RFpath, 1, 0.1, 1, NStory, 0.02, 2, AnalysisTypeID);    
end

write_SourceSubroutine (INP, FrameType,AnalysisTypeID,ColElementOption,GFX,PZ_Multiplier);

write_ResultsFolder (INP, AnalysisTypeID,TempPOrun,Uncertainty);

write_BasicInput (INP, FrameType,NStory,NBay,CompositeX,Comp_I,Comp_I_GC,Units,E,mu0,fy,fyBrace,fyGP,Er,fyR,muR,Ec,fc,muC,EL_Multiplier,SteelMatID,TransformationX,nSegments,initialGI,nIntegration,Sigma, Uncertainty);

write_PreCalculatedGeometry (INP, NStory, NBay, HStory, WBay, WBuilding, MF_BEAMS, CGP_RigidOffset, MGP_RigidOffset, a, b, FrameType, Units);

write_Nodes (INP, NStory, NBay, FrameType, BraceLayout, MF_COLUMNS, MF_BEAMS, MGP_W, EBF_W, Splice, HStory, Units);

[EL_ELEMENTS] = write_ElasticBeamsColumns_RC (INP, NStory, NBay, ColElementOption, BeamElementOption, MF_COLUMNS, MF_BEAMS, nIntegration, coeff_cracked);

write_PZ_RC(INP,NStory,NBay,MF_COLUMNS,MF_BEAMS);

write_BeamSpring_MRF_RC (INP, NStory, NBay, WBay, ModelELOption, MF_COLUMNS, MF_BEAMS, bond_slip, Units);

[Py_Col]=write_ColumnSpring_RC (INP, NStory, NBay, HStory, ColElementOption, PM_Option, MF_COLUMNS, MF_BEAMS, fc, bond_slip, Units);

write_FloorLinks (INP,NStory,NBay,WBay,PZ_Multiplier,FloorLink,Fs,Fs_Profile);

write_EGFelements_RC (INP,NStory,NBay,HStory,GFX,Orientation,nMF,nGC,nGB,MF_COLUMNS,GF_COLUMNS,GF_BEAMS, coeff_cracked);

write_EGFsprings_RC (INP,NStory,NBay,HStory,GFX,Orientation,nMF,nGC,nGB,MF_COLUMNS,GF_COLUMNS,GF_BEAMS, coeff_cracked);

write_BCs (INP,FrameType,NStory,NBay,PZ_Multiplier,RigidFloor,Support,MidSpanConstraint,BraceLayout);

write_Recorders(INP, NStory, NBay, Recorders, Filename, FrameType, BraceLayout, Splice, FloorLink, AnalysisTypeID);

write_Mass(INP, EL_ELEMENTS);