function [PFAmax_profile]=readnGet_PFAmax(GM_No,Ri)

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName))

v2struct(PROJECT);
v2struct(LAYOUT);
v2struct(CONNECTION);
v2struct(ANALYSIS);

if Uncertainty==0;subfoldername=GM.name{GM_No}; else; subfoldername=[GM.name{GM_No},'_',num2str(Ri)]; end

GMdt   	  = GM.dt  (GM_No);
evalc(strcat(['GMacc=GM.GM',num2str(GM_No),'acc']));

% Go inside the results folder and read data
cd (strcat(RFpath,'\Results\',subfoldername));

% Read Time Data
dumVar=importdata('Time.out');
time=dumVar(:,1);

% Read RFA data
for Floor=1:NStory+1
    evalc(['MF_RFA' ,num2str(Floor),'=importdata(','''',FILENAME.RFA,num2str(Floor),'_MF.out','''',')/g']);
end

cd (MainDirectory)

% Get maxmimum absolute floor acceleration
GMtime = 0:GMdt:(length(GMacc)-1)*GMdt;
Analysistime=time(12:end,1);
GMacc_Inter = interp1(GMtime,GMacc, Analysistime);

for Floor=1:NStory+1
    evalc(['x=MF_RFA',num2str(Floor), '(12:end,1)+ SF * GMacc_Inter(:,1)']);
    PFAmax_profile(1,Floor)=max(abs(x));
end

