function CREATOR_MODEL_MRF (AnalysisTypeID,TempPOrun)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'OpenSEESFileName','BuildOption','STATUS');

if TempPOrun==1;      PM_Option=2; end
if AnalysisTypeID==1; PM_Option=2; end

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

if STATUS.Analysis==1
    write_OpenArguments(INP, BuildOption, AnalysisTypeID);
else
    write_OpenArguments(INP,           2, AnalysisTypeID);
end

write_SourceSubroutine (INP, AnalysisTypeID);

write_ResultsFolder (INP, AnalysisTypeID, TempPOrun);%, ANALYSIS);

write_BasicInput (INP);

write_PreCalculatedGeometry(INP);

write_Nodes(INP);

write_PZelement(INP);

write_PZspring(INP);

write_ElasticBeamsColumns(INP);

write_ElasticRBS (INP);

write_BeamSpring_MRF (INP);
    
write_ColumnSpring (INP);

write_SpliceSpring (INP);

write_FloorLinks (INP);

write_EGFelements(INP);

write_EGFsprings (INP);

write_BCs (INP);

write_Recorders(INP, AnalysisTypeID);

write_Mass(INP);