function [MassTot, Ws, Pnode] = get_Weight_and_Mass()

clc;

global  ProjectName ProjectPath
load(strcat(ProjectPath,ProjectName))

%% Seismic Weight Calculation
Ws=0;

for Fi=NStory+1:-1:2
    Si=Fi-1;
    for Axis=1:NBay+1
        Bay=max(1,Axis-1);
        if Fi~=NStory+1 && Fi~=2
            if Axis>1  && Axis < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Si)+0.5*HStory(Si+1)) * (TAin1); end
            if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Si)+0.5*HStory(Si+1)) * (TAex1); end
        elseif Fi==NStory+1
            if Axis>1  && Axis < NBay+1; Load  = (cDL_W * RoofDL	+ cLL_W * RoofLL + cGL_W * RoofGL)       * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Si)) * (TAin1); end
            if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * RoofDL    + cLL_W * RoofLL + cGL_W * RoofGL)       * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Si)) * (TAex1); end
        elseif Fi==2
            if Axis>1  && Axis < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (0.5*HStory(2)+0.5*HStory(Si)) * (TAin1); end
            if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (0.5*HStory(2)+0.5*HStory(Si)) * (TAex1); end
        end
        Pnode(Fi, Axis) = Load;
        Ws=Ws+Load;        
    end
end

for Fi=NStory+1:-1:2
    Si=Fi-1;
    for Axis=NBay+2:NBay+3
        SumLoadMF  = 0.0;
        if Fi~=NStory+1 && Fi~=2
                                           Load_ToT  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TA_MF      + cCL_W * Cladding * (HStory(2))* (Perimeter/nMF);
            for AxisX=1:NBay+1
                if AxisX>1  && AxisX < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Si)+0.5*HStory(Si+1)) * (TAin1); end
                if AxisX==1 || AxisX ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Si)+0.5*HStory(Si+1)) * (TAex1); end
                SumLoadMF  = SumLoadMF + Load;
            end
        elseif Fi==NStory+1

            if NStory == 1; HStory_indx=1; else; HStory_indx=2; end
                                           Load_ToT  = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * TA_MF      + cCL_W * Cladding * (0.5*HStory(HStory_indx)) * (Perimeter/nMF);
            for AxisX=1:NBay+1
                if AxisX>1  && AxisX < NBay+1; Load  = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * TribAreaIn + cCL_W * Cladding * 0.5*HStory(Si) * (TAin1); end
                if AxisX==1 || AxisX ==NBay+1; Load  = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * TribAreaEx + cCL_W * Cladding * 0.5*HStory(Si) * (TAex1); end
                SumLoadMF  = SumLoadMF + Load;
            end
        elseif Fi==2
                                           Load_ToT  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TA_MF      + cCL_W * Cladding * ((HStory(2)*0.5+HStory(1)*0.5)) * (Perimeter/nMF);
            for AxisX=1:NBay+1
                if AxisX>1  && AxisX < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (HStory(2)*0.5+HStory(Si)*0.5) * (TAin1); end
                if AxisX==1 || AxisX ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (HStory(2)*0.5+HStory(Si)*0.5) * (TAex1); end
                SumLoadMF  = SumLoadMF + Load;
            end
        end
        Load_GF=(Load_ToT-SumLoadMF)/2;
        Pnode(Fi, Axis) = Load_GF;
        Ws=Ws+Load_GF;
    end
end

%% Mass Calculation

MassTot=0;
for Fi=NStory+1:-1:2
    Si=Fi-1;
    for Axis=1:NBay+3
        if Fi==NStory+1
            Load =  (cDL_M * RoofDL    + cLL_M * RoofLL    + cGL_M * RoofGL)    * TA_MF + cCL_M * Cladding * (HStory(Si)*0.5) * (Perimeter/nMF);
        end
        if Fi==1
            Load =  (cDL_M * TypicalDL + cLL_M * TypicalLL + cGL_M * TypicalGL) * TA_MF + cCL_M * Cladding * ((HStory(Si)*0.5+HStory(Si+1)*0.5)) * (Perimeter/nMF);
        end
        if Fi~=NStory+1 && Fi~=1
            Load =  (cDL_M * TypicalDL + cLL_M * TypicalLL + cGL_M * TypicalGL) * TA_MF + cCL_M * Cladding * (HStory(Si)) * (Perimeter/nMF);
        end
        Mass = Load / g / (NBay+3);
        
        MassTot=MassTot+Mass;
    end
    MassMatrix(Si,1)=MassTot;
end

save(strcat(ProjectPath,ProjectName),'Ws','Pnode','-append');
