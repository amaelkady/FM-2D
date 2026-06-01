function [SDR_MF] = get_SDR_Profile()

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName))

v2struct(PROJECT);
v2struct(LAYOUT);
v2struct(ANALYSIS);


if     PO==1;                     SubRFname = 'Pushover';                        
elseif ELF==1;                    SubRFname = 'ELF';                             
elseif EQ==1 && Uncertainty==0;   SubRFname = GM.name{GM_No};                    
elseif EQ==1 && Uncertainty==1;   SubRFname = [GM.name{GM_No},'_',num2str(Ri)];  
elseif CDPO==1;                   SubRFname = 'Pushover';                        
elseif TTH==1;                    SubRFname = 'Tsunami';                         end

%% Go inside the results folder and read results
cd (strcat(RFpath,'\Results\',SubRFname));

% Read SDR Data
if RECORDERS.SDR==1
    for i=1:NStory
        evalc(strcat('x=importdata(','''',FILENAME.SDR,num2str(i),'_MF.out','''',')'));
        SDR_MF(i,1)=x(end,1);
    end
end

cd (MainDirectory)


