function [DATA]= Read_Analysis_Data(MainDirectory,RFpath,GM_No,GM,NStory,Filename,g,SFcurrent,DATA,Recorders, subfoldername)

cd (RFpath);                 % Go Inside the 'Results' Folder 
cd ('Results');
cd (subfoldername);              % Go Inside the  Current GM Folder

% Read Time
DATA.TimeX= importdata('Time.out');

% Read Story Drifts
if Recorders.SDR==1
for i=1:NStory
	FilenameX1=strcat(Filename.SDR,num2str(i),'_MF.out');
	evalc(strcat('DATA.SDR',num2str(i),' = importdata(''',FilenameX1,''')'));
end
end

% Read Floor Accelerations      
if Recorders.RFA==1
for i=1:NStory+1
	FilenameX2=strcat(Filename.RFA,num2str(i),'_MF.out');
	evalc(strcat('DATA.RFA',num2str(i),' = importdata(''',FilenameX2,''')'));
end
end

%% Calculate Absolute Acceleration per Floor
cd (MainDirectory);      
A = importdata(['GM.txt']);
L = length(A(:,1));
CL = length(A(1,:));
for i = 1:L
   GMArrangement((1+(i-1)*CL):(CL+(i-1)*CL),1) = A(i,:)';
end
evalc(strcat('Time=DATA.TimeX(:,1)'));
Time2 = 0:GM.dt(GM_No):(length(GMArrangement)-1)*GM.dt(GM_No);
Eq (:,1) = Time2;
Eq (:,2) = GMArrangement;
DATA.EQ_Inter = interp1(Eq(:,1),Eq(:,2), Time(12:end,1));
    
for i=1:NStory+1
	evalc(strcat('DATA.PFA',num2str(i),'= DATA.RFA', num2str(i), '(12:end,1)/g + SFcurrent * DATA.EQ_Inter(:,1)'));
end

%%
for i=1:NStory
    evalc(strcat('SDRincrmaxi(i)=max(abs(DATA.SDR',num2str(i),'))'));
    evalc(strcat('PFAincrmaxi(i)=max(abs(DATA.PFA',num2str(i+1),'))'));
end
DATA.SDRincrmax=max(SDRincrmaxi);
DATA.PFAincrmax=max(PFAincrmaxi);
                    
cd (MainDirectory);
