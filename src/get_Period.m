function [T1_computed] = get_Period()

clc;

global MainDirectory ProjectName ProjectPath
load(strcat(ProjectPath,ProjectName), 'FrameType' ,'DiscritizationOption','RFpath')

%% Period Calculation

if FrameType==1
    CREATOR_MODEL_MRF(1,0);
elseif FrameType==4
    if DiscritizationOption==1
        CREATOR_MODEL_MRF_RC(1,0);
    else
        CREATOR_MODEL_MRF_RC_Fiber(1,0);
    end
else
   CREATOR_MODEL_CBF(1,0);
end
CREATOR_ANALYSIS(1,0);

! OpenSEES.exe TempModel.tcl

cd(strcat(RFpath,'\Results\EigenAnalysis'));
fileID = fopen('EigenPeriod.out','r');
A = fscanf(fileID,'%f');
fclose(fileID);

T1_computed = A(1,1);

cd(MainDirectory)
delete ('TempModel.tcl')