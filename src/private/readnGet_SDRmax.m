function [SDRmax_profile]=readnGet_SDRmax(GM_No,Ri)

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName))
v2struct(PROJECT);
v2struct(LAYOUT);
v2struct(CONNECTION);
v2struct(ANALYSIS);

if Uncertainty==0;subfoldername=GM.name{GM_No}; else; subfoldername=[GM.name{GM_No},'_',num2str(Ri)]; end

% Go inside the results folder and read results
cd (strcat(RFpath,'\Results\',subfoldername));

% Read SDR data
for Story=1:NStory
    evalc(['MF_SDR' ,num2str(Story),'=importdata(','''',FILENAME.SDR,num2str(Story),'_MF.out','''',')']);
end

cd (MainDirectory)

% Get maximum absolute SDR data
for Story=1:NStory
    evalc(['x=MF_SDR',num2str(Story), '(12:end,1)']);
    SDRmax_profile(1,Story)=max(abs(x));
end

