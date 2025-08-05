function [SDRmax_profile]=ReadnGet_SDRmax(GM_No,Ri)

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName),'RFpath','GM','Filename','Uncertainty','NStory')

if Uncertainty==0;subfoldername=GM.Name{GM_No}; else; subfoldername=[GM.Name{GM_No},'_',num2str(Ri)]; end

% Go inside the results folder and read results
cd (RFpath)
cd ('Results')
cd (subfoldername)

% Read SDR data
for Story=1:NStory
    evalc(['MF_SDR' ,num2str(Story),'=importdata(','''',Filename.SDR,num2str(Story),'_MF.out','''',')']);
end

cd (MainDirectory)

% Get maximum absolute SDR data
for Story=1:NStory
    evalc(['x=MF_SDR',num2str(Story), '(12:end,1)']);
    SDRmax_profile(1,Story)=max(abs(x));
end

