function write_Mass(INP, EL_ELEMENTS)
global MainDirectory ProjectName ProjectPath
clc;
cd(ProjectPath)
load(ProjectName)
cd(MainDirectory)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                              NODAL MASS                                         #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'set g %5.2f;\n', g);

MassTot=0;

for Floor=NStory+1:-1:2
    
    LoadColFloor=0;
    Story=Floor-1;
    
    if Floor==NStory+1
        Loadmf =  (cDL_M * RoofDL    + cLL_M * RoofLL    + cGL_M * RoofGL)    * TA_MF    + cCL_M *Cladding * (HStory(Story)*0.5) * (Perimeter/nMF);
    elseif Floor==1
        Loadmf =  (cDL_M * TypicalDL + cLL_M * TypicalLL + cGL_M * TypicalGL) * TA_MF    + cCL_M *Cladding * ((HStory(Story)*0.5+HStory(Story+1)*0.5)) * (Perimeter/nMF);
    else
        Loadmf =  (cDL_M * TypicalDL + cLL_M * TypicalLL + cGL_M * TypicalGL) * TA_MF    + cCL_M *Cladding * (HStory(Story)) * (Perimeter/nMF);
    end
    
    for Axis=1:NBay+1
        if Axis==1 || Axis==NBay+3; TribArea=TribAreaEx; TA1=TAin1; else TribArea=TribAreaIn;  TA1=TAex1; end
        
        if Floor==NStory+1
            Loadcol =  (cDL_M * RoofDL    + cLL_M * RoofLL    + cGL_M * RoofGL)    * TribArea + cCL_M *Cladding * (HStory(Story)*0.5) * TA1;
        elseif Floor==1
            Loadcol =  (cDL_M * TypicalDL + cLL_M * TypicalLL + cGL_M * TypicalGL) * TribArea + cCL_M *Cladding * ((HStory(Story)*0.5+HStory(Story+1)*0.5)) * TA1;
        else
            Loadcol =  (cDL_M * TypicalDL + cLL_M * TypicalLL + cGL_M * TypicalGL) * TribArea + cCL_M *Cladding * (HStory(Story)) * TA1;
        end
        
        Mass = Loadcol / g;
        if PZ_Multiplier==1; nodeID=400000+1000*Floor+100*Axis+04; else; nodeID=(10*Floor+Axis)*10; end
        fprintf(INP,'mass %d %6.4f  1.e-9 1.e-9; ', nodeID, Mass);
        
        LoadColFloor=LoadColFloor+Loadcol;
        MassTot=MassTot+Mass;
    end
    
    for Axis=NBay+2:NBay+3

        Mass = (Loadmf - LoadColFloor) / g / 2;
        nodeID=(10*Floor+Axis)*10;
        fprintf(INP,'mass %d %6.4f  1.e-9 1.e-9; ', nodeID, Mass);
        
        MassTot=MassTot+Mass;
    end
    MassMatrix(Story,1)=MassTot;
    fprintf(INP,'\n');
end
fprintf(INP,'\n');

fprintf(INP,'constraints Plain;\n');
fprintf(INP,'\n');

cd(ProjectPath)
save(ProjectName,'EL_ELEMENTS','MassTot','MassMatrix','-append');
cd(MainDirectory)

