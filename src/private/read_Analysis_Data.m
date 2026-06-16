function [DATA]= read_Analysis_Data(MainDirectory,RFpath,GM_No,GM,NStory,FILENAME,g,SFcurrent,DATA,RECORDERS, subfoldername)

cd (strcat(RFpath,'\Results\',subfoldername));

% Read Time
DATA.TimeX= importdata('Time.out');

% Read Story Drifts
if RECORDERS.SDR==1
    for i=1:NStory
        FilenameX1=strcat(FILENAME.SDR,num2str(i),'_MF.out');
        DATA.SDR{i} = importdata(FilenameX1);
    end
end

% Read Floor Accelerations
if RECORDERS.RFA==1
    for i=1:NStory+1
        FilenameX2=strcat(FILENAME.RFA,num2str(i),'_MF.out');
        DATA.RFA{i} = importdata(FilenameX2);
    end
end

%% Calculate Absolute Acceleration per Floor
A = importdata(strcat(MainDirectory,'\GM.txt'));
acc = reshape(A.', [], 1);

Time=DATA.TimeX(:,1);
Time2 = 0:GM.dt{:,GM_No}:(length(acc)-1)*GM.dt{:,GM_No};
Eq = [Time2' acc];
DATA.EQ_Inter = interp1(Eq(:,1),Eq(:,2), Time(12:end,1));


for i=1:NStory+1
    sizeRFA(i)=size(DATA.RFA{i},1);
end

for i=1:NStory+1
    % evalc(strcat('DATA.PFA',num2str(i),'= DATA.RFA', num2str(i), '(12:end,1)/g + SFcurrent * DATA.EQ_Inter(:,1)'));
    if sizeRFA(i) == size(DATA.EQ_Inter,1)+11
        DATA.PFA{i} = DATA.RFA{i}(12:end,1)/g + SFcurrent * DATA.EQ_Inter(:,1);
    else
        DATA.PFA{i} = DATA.RFA{i}(12:end,1)/g + SFcurrent * DATA.EQ_Inter(1:sizeRFA(i)-11,1);
    end
end

%%
for i=1:NStory
    SDRincrmaxi(i)=max(abs(DATA.SDR{i}));
    PFAincrmaxi(i)=max(abs(DATA.PFA{i+1}));
end
DATA.SDRincrmax=max(SDRincrmaxi);
DATA.PFAincrmax=max(PFAincrmaxi);

cd (MainDirectory);
