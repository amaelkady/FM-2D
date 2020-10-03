function [T1_computed,MassTot,Ws] = Get_Mass_and_Period()
global MainDirectory ProjectName ProjectPath
clc;
cd(ProjectPath)
load(ProjectName)
cd(MainDirectory)

%% Seismic Weight Calculation
Ws=0;

for Floor=NStory+1:-1:2
    Story=Floor-1;
    for Axis=1:NBay+1
        Bay=max(1,Axis-1);
        if Floor~=NStory+1 && Floor~=2
            if Axis>1  && Axis < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Story)+0.5*HStory(Story+1)) * (TAin1); end
            if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Story)+0.5*HStory(Story+1)) * (TAex1); end
        elseif Floor==NStory+1
            if Axis>1  && Axis < NBay+1; Load  = (cDL_W * RoofDL	+ cLL_W * RoofLL + cGL_W * RoofGL)       * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Story)) * (TAin1); end
            if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * RoofDL    + cLL_W * RoofLL + cGL_W * RoofGL)       * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Story)) * (TAex1); end
        elseif Floor==2
            if Axis>1  && Axis < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (0.5*HStory(2)+0.5*HStory(Story)) * (TAin1); end
            if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (0.5*HStory(2)+0.5*HStory(Story)) * (TAex1); end
        end
        Ws=Ws+Load;
    end
end

for Floor=NStory+1:-1:2
    Story=Floor-1;
    for Axis=NBay+2:NBay+3
        SumLoadMF  = 0.0;
        if Floor~=NStory+1 && Floor~=2
                                           Load_ToT  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TA_MF      + cCL_W * Cladding * (HStory(2))* (Perimeter/nMF);
            for AxisX=1:NBay+1
                if AxisX>1  && AxisX < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Story)+0.5*HStory(Story+1)) * (TAin1); end
                if AxisX==1 || AxisX ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Story)+0.5*HStory(Story+1)) * (TAex1); end
                SumLoadMF  = SumLoadMF + Load;
            end
        elseif Floor==NStory+1
                                           Load_ToT  = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * TA_MF      + cCL_W * Cladding * (0.5*HStory(2)) * (Perimeter/nMF);
            for AxisX=1:NBay+1
                if AxisX>1  && AxisX < NBay+1; Load  = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * TribAreaIn + cCL_W * Cladding * 0.5*HStory(Story) * (TAin1); end
                if AxisX==1 || AxisX ==NBay+1; Load  = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * TribAreaEx + cCL_W * Cladding * 0.5*HStory(Story) * (TAex1); end
                SumLoadMF  = SumLoadMF + Load;
            end
        elseif Floor==2
                                           Load_ToT  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TA_MF      + cCL_W * Cladding * ((HStory(2)*0.5+HStory(1)*0.5)) * (Perimeter/nMF);
            for AxisX=1:NBay+1
                if AxisX>1  && AxisX < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (HStory(2)*0.5+HStory(Story)*0.5) * (TAin1); end
                if AxisX==1 || AxisX ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (HStory(2)*0.5+HStory(Story)*0.5) * (TAex1); end
                SumLoadMF  = SumLoadMF + Load;
            end
        end
        Load_GF=(Load_ToT-SumLoadMF)/2;
        Ws=Ws+Load_GF;
    end
end

%% Mass Calculation

MassTot=0;
for Floor=NStory+1:-1:2
    Story=Floor-1;
    for Axis=1:NBay+3
        if Floor==NStory+1
            Load =  (cDL_M * RoofDL    + cLL_M * RoofLL    + cGL_M * RoofGL)    * TA_MF + cCL_M * Cladding * (HStory(Story)*0.5) * (Perimeter/nMF);
        end
        if Floor==1
            Load =  (cDL_M * TypicalDL + cLL_M * TypicalLL + cGL_M * TypicalGL) * TA_MF + cCL_M * Cladding * ((HStory(Story)*0.5+HStory(Story+1)*0.5)) * (Perimeter/nMF);
        end
        if Floor~=NStory+1 && Floor~=1
            Load =  (cDL_M * TypicalDL + cLL_M * TypicalLL + cGL_M * TypicalGL) * TA_MF + cCL_M * Cladding * (HStory(Story)) * (Perimeter/nMF);
        end
        Mass = Load / g / (NBay+3);
        
        MassTot=MassTot+Mass;
    end
    MassMatrix(Story,1)=MassTot;
end

%% Period Calculation

if FrameType==1
    CREATOR_MODEL_MRF(1,0);
else
   CREATOR_MODEL_CBF(1,0);
end
CREATOR_ANALYSIS(1,0);
! OpenSEES.exe TempModel.tcl
cd(RFpath);
cd('Results');
cd('EigenAnalysis');
fileID = fopen('EigenPeriod.out','r');
A = fscanf(fileID,'%f');
fclose(fileID);
T1_computed = A(1,1);

cd(MainDirectory)
delete ('TempModel.tcl')