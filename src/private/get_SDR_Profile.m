function [SDR_MF] = get_SDR_Profile()

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName),'RFpath','Recorders','Filename','NStory','PO','EQ','ELF','CDPO','TTH','GM','Uncertainty')

if PO==1;                     SubRFname = 'Pushover';                        end
if ELF==1;                    SubRFname = 'ELF';                             end
if EQ==1 && Uncertainty==0;   SubRFname = GM.Name{GM_No};                    end
if EQ==1 && Uncertainty==1;   SubRFname = [GM.Name{GM_No},'_',num2str(Ri)];  end
if CDPO==1;                   SubRFname = 'Pushover';                        end
if TTH==1;                    SubRFname = 'Tsunami';                         end

%% Go inside the results folder and read results
cd (strcat(RFpath,'\Results\',SubRFname));

% Read SDR Data
if Recorders.SDR==1
    for i=1:NStory
        evalc(strcat('x=importdata(','''',Filename.SDR,num2str(i),'_MF.out','''',')'));
        SDR_MF(i,1)=x(end,1);
    end
end

cd (MainDirectory)


