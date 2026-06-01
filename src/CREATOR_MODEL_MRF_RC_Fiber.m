function CREATOR_MODEL_MRF_RC_Fiber (AnalysisTypeID,TempPOrun)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'OpenSEESFileName','BuildOption','STATUS');

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

write_SourceSubroutine (INP, AnalysisTypeID);

write_ResultsFolder (INP, AnalysisTypeID, TempPOrun);

write_BasicInput (INP);

write_PreCalculatedGeometry (INP);

write_Nodes_FiberFrame (INP);

write_BeamsColumns_FiberFrame (INP);

write_FloorLinks_FiberFrame (INP);

write_EGFelements_FiberFrame (INP)

write_EGFsprings_FiberFrame (INP);

write_BCs_FiberFrame (INP);

write_Recorders_FiberFrame(INP, AnalysisTypeID);

write_Mass_FiberFrame(INP);