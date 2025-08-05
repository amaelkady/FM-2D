function CREATOR_MODEL_CBF (AnalysisTypeID,TempPOrun)
global MainDirectory ProjectName ProjectPath resource_root
load(strcat(ProjectPath,ProjectName))

clc;

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
    write_OpenArguments(INP, NStory, FrameType, EQ, PO, ELF, CDPO, TTH, MaxRunTime, CompositeX, Animation, MainDirectory, RFpath, ModePO, DriftPO, DampModeI, DampModeJ, zeta, BuildOption, AnalysisTypeID, Version, Units);
else
    write_OpenArguments(INP, NStory, FrameType, 0,   0,   0,    0,   0, 60, CompositeX, 0, MainDirectory, RFpath, 1, 0.1, 1, NStory, 0.02, 2, AnalysisTypeID, Version, Units);    
end

write_SourceSubroutine (INP, FrameType,AnalysisTypeID,ColElementOption,GFX, EGFconnection,PZ_Multiplier);

write_ResultsFolder (INP, AnalysisTypeID,TempPOrun,Uncertainty);

write_BasicInput (INP, FrameType,NStory,NBay,CompositeX,Comp_I,Comp_I_GC,Units,E,mu0,fy,fyBrace,fyGP,Er,fyR,muR,Ec,fc,muC,EL_Multiplier,SteelMatID,TransformationX,nSegments,initialGI,nIntegration,Sigma, Uncertainty, resource_root);

write_PreCalculatedGeometry (INP, NStory, NBay, HStory, WBay, WBuilding, MF_BEAMS, CGP_RigidOffset, MGP_RigidOffset, a, b, FrameType, Units);

write_Nodes (INP, NStory, NBay, FrameType, BraceLayout, MF_COLUMNS, MF_BEAMS, MGP_W, EBF_W, Splice, HStory, Units);

write_PZelement(INP,NStory,NBay,PZ_Multiplier,MF_COLUMNS,MF_BEAMS,Units);

write_PZspring(INP,NStory,NBay,PZ_Multiplier,EL_Multiplier,CompositeX,MF_COLUMNS,MF_BEAMS,Doubler,trib,ts,Units);

write_BraceRigidLinks (INP, NStory, NBay, FrameType, BraceLayout,PZ_Multiplier);
%write_BraceLinks_FB (INP, NStory, NBay, FrameType, BraceLayout,PZ_Multiplier, BRACES, CGP_tp, CGP_Lc, MGP_tp, MGP_Lc, Units);

write_GPspring (INP, NStory, NBay, FrameType, BraceLayout, BRACES, MGP_L123, MGP_tp, MGP_Lc, CGP_L123, CGP_tp, CGP_Lc, Units);
%write_GPspring_Rigid (INP, NStory, NBay, FrameType, BraceLayout, Units);

write_Braces (INP, NStory, NBay, BRACES, Brace_L, FrameType, BraceLayout, nSegments, initialGI, nIntegration, Units);

[EL_ELEMENTS] = write_ElasticBeamsColumns (INP, NStory, NBay, FrameType, BraceLayout, ColElementOption, MF_COLUMNS, MF_BEAMS, MF_SL, Splice, initialGI, nIntegration, Material, SteelMatID,  Units);

write_BeamSpring_CBF (INP, NStory, NBay, WBay, FrameType, BraceLayout, MF_COLUMNS, MF_BEAMS, MGP_W, MFconnectionOdd, MFconnectionEven, fy, Units);

[Py_Col]=write_ColumnSpring (INP, NStory, NBay, HStory, ColElementOption, PM_Option, MF_COLUMNS, MF_BEAMS, Splice, fy, Units);

write_SpliceSpring (INP, NStory, NBay, Splice, SpliceConnection);

write_FloorLinks (INP,NStory,NBay,WBay,PZ_Multiplier,FloorLink,Fs,Fs_Profile);

write_EGFelements (INP,NStory,NBay,HStory,GFX,CompositeX,Orientation,nMF,nGC,nGB,MF_COLUMNS,MF_BEAMS,GF_COLUMNS,GF_BEAMS,Splice,fy,Units);

write_EGFsprings (INP,GFX,EGFconnection, CONNECTIONS,CompositeX,Orientation,MF_COLUMNS,MF_BEAMS,GF_COLUMNS,GF_BEAMS,Splice, LAYOUT, MATERIALS, LOADS, Units);

write_BCs (INP,FrameType,NStory,NBay,PZ_Multiplier,RigidFloor,Support,MidSpanConstraint,BraceLayout);

write_Recorders(INP, NStory, NBay, Recorders, Filename, FrameType, BraceLayout, Splice, FloorLink, AnalysisTypeID, GFX, Orientation);

write_Mass(INP,EL_ELEMENTS);