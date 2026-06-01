function CREATOR_MODEL_MRF_RC (AnalysisTypeID,TempPOrun)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'));

if TempPOrun==1; PM_Option=2; end

% Open File to Write Code
if AnalysisTypeID==1
    PO  = 0;
    ELF = 0;
    EQ  = 0;
    INP = fopen('TempModel.tcl','w+');
elseif TempPOrun==1  && AnalysisTypeID==2
    PO  = 1;
    ELF = 0;
    EQ  = 0;
    INP = fopen('TempModelPO.tcl','w+');
else
    INP = fopen(OpenSEESFileName,'w+');
end

if STATUS.Analysis==1
    write_OpenArguments(INP, BuildOption, AnalysisTypeID);
else
    write_OpenArguments(INP, 2, AnalysisTypeID);    
end

write_SourceSubroutine (INP,AnalysisTypeID);

write_ResultsFolder (INP);

write_BasicInput (INP);

write_PreCalculatedGeometry (INP);

write_Nodes (INP);

[EL_ELEMENTS] = write_ElasticBeamsColumns_RC (INP, NStory, NBay, ColElementOption, BeamElementOption, MF_COLUMNS, MF_BEAMS, nIntegration, coeff_cracked);

write_PZ_RC(INP,NStory,NBay,MF_COLUMNS,MF_BEAMS);

write_BeamSpring_MRF_RC (INP, NStory, NBay, WBay, ModelELOption, MF_COLUMNS, MF_BEAMS, bond_slip, Units);

[Py_Col]=write_ColumnSpring_RC (INP, NStory, NBay, HStory, ColElementOption, PM_Option, MF_COLUMNS, MF_BEAMS, fc, bond_slip, Units);

write_FloorLinks (INP);

write_EGFelements_RC (INP,NStory,NBay,HStory,GFX,Orientation,nMF,nGC,nGB,MF_COLUMNS,GF_COLUMNS,GF_BEAMS, coeff_cracked);

write_EGFsprings_RC (INP,NStory,NBay,HStory,GFX,Orientation,nMF,nGC,nGB,MF_COLUMNS,GF_COLUMNS,GF_BEAMS, coeff_cracked);

write_BCs (INP);

write_Recorders(INP, AnalysisTypeID);

write_Mass(INP);