function [PFAmax_profile]=ReadnGet_PFAmax(GM_No,Ri)

global MainDirectory ProjectName ProjectPath
cd (ProjectPath)
load (ProjectName,'RFpath','GM','Filename','Uncertainty','NStory','FloorLink','SF','g')
cd (MainDirectory)

if Uncertainty==0;subfoldername=GM.Name{GM_No}; else; subfoldername=[GM.Name{GM_No},'_',num2str(Ri)]; end

GMdt   	  = GM.dt  (GM_No);
evalc(strcat(['GMacc=GM.GM',num2str(GM_No),'acc']));

% Go inside the results folder and read data
cd (RFpath)
cd ('Results')
cd (subfoldername)

% Read Time Data
dumVar=importdata('Time.out');
time=dumVar(:,1);

% Read RFA data
for Floor=1:NStory+1
    evalc(['MF_RFA' ,num2str(Floor),'=importdata(','''',Filename.RFA,num2str(Floor),'_MF.out','''',')/g']);
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

