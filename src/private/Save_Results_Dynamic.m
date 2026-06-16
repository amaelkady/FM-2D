function save_Results_Dynamic()

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'RFpath','NStory','Parallel','Uncertainty','nRealizations','GM','RECORDERS','FILENAME','g','FloorLink','GM_Start','GM_Last','SF');

clc;

count=0;
for GM_No=GM_Start:GM_Last

    GMdt  = GM.dt  {:,GM_No};
    GMacc = GM.acc {:,GM_No};

    for Ri=1:nRealizations
        clear Eq
        
        count=count+1;
        
        if Uncertainty == 0; subfoldername= GM.name{:,GM_No};       else; subfoldername=[GM.name{:,GM_No},'_',num2str(Ri)]; end
        if Parallel    == 1; subfoldername=[GM.name{:,GM_No},'_1']; end
        
        % Go inside the results folder and read results
        cd (strcat(RFpath,'\Results\',subfoldername));

        %% Read Time Data
        dumVar=importdata('Time.out');
        time=dumVar(:,1);
        
        %% Read SDR data
        if RECORDERS.SDR==1
            for Story=1:NStory
                evalc(['x=importdata(','''',FILENAME.SDR ,num2str(Story),'_MF.out','''',')']);
                SDR_All(count,Story)=max(abs(x(12:end,1)));
                RDR_All(count,Story)=    abs(x(end,1));
                
                if FloorLink==2
                    evalc(['x=importdata(','''',FILENAME.SDR ,num2str(Story),'_EGF.out','''',')']);
                    SDR_All_EGF(count,Story)=max(abs(x(12:end,1)));
                    RDR_All_EGF(count,Story)=    abs(x(end,1));
                end
            end
        end
        
        %% Read Floor Relative Acceleration data
        if RECORDERS.RFA==1
            for Floor=1:NStory+1
                evalc(['MF_RFA{Floor}=importdata(','''',FILENAME.RFA ,num2str(Floor),'_MF.out','''',')/g']);
                if FloorLink==2; evalc(['EGF_RFA{Floor}=importdata(','''',FILENAME.RFA ,num2str(Floor),'_EGF.out','''',')/g']); end
            end
        end
        
        %% Read Floor Relative Velocity data
        if RECORDERS.RFV==1
            for Floor=1:NStory+1
                evalc(['MF_RFV{Floor}=importdata(','''',FILENAME.RFV ,num2str(Floor),'_MF.out','''',')']);
                if FloorLink==2; evalc(['EGF_RFV{Floor}=importdata(','''',FILENAME.RFV ,num2str(Floor),'_EGF.out','''',')']); end
            end
        end
        
        %% Deduce Floor Absolute Acceleration & Velocity
        GMtime = 0:GMdt:(length(GMacc)-1)*GMdt;
        Analysistime=time(12:end,1);
        GMacc_Inter = interp1(GMtime,GMacc, Analysistime);
        GMvel_Inter=cumtrapz(Analysistime,GMacc_Inter*g);
        
        if RECORDERS.RFA==1
            for Floor=1:NStory+1
                x=MF_RFA{Floor}(12:end,1)+ SF * GMacc_Inter(:,1);
                PFA_All(count,Floor)=max(abs(x));
                if FloorLink==2
                    x=EGF_RFA{Floor}(12:end,1)+ SF * GMacc_Inter(:,1);
                    PFA_All_EGF(count,Floor)=max(abs(x));
                end
            end
        end
        
        if RECORDERS.RFV==1
            for Floor=1:NStory+1
                x=MF_RFV{Floor}(12:end,1)+ SF * GMvel_Inter(:,1);
                PFV_All(count,Floor)=max(abs(x));
                if FloorLink==2
                    x=EGF_RFV{Floor}(12:end,1)+ SF * GMvel_Inter(:,1);
                    PFV_All_EGF(count,Floor)=max(abs(x));
                end
            end
        end
        
    end
end

%% Save Processed IDA Data to a Text File in a Different Folder for Each GM
cd (strcat(RFpath,'\Results'));


if RECORDERS.SDR==1
    file1 = fopen('Summary Maximum SDR.txt','wt');
    for i=1:count
        for Story = 1:NStory
            fprintf(file1,'%5.4f\t',SDR_All(i,Story));
        end
        fprintf(file1,'\n');
    end
    fclose(file1);
end

if RECORDERS.SDR==1
    file1 = fopen('Summary Maximum RDR.txt','wt');
    for i=1:count
        for Story = 1:NStory
            fprintf(file1,'%5.4f\t',RDR_All(i,Story));
        end
        fprintf(file1,'\n');
    end
    fclose(file1);
end

if RECORDERS.RFA==1
    file1 = fopen('Summary Maximum PFA.txt','wt');
    for i=1:count
        for Floor = 1:NStory+1
            fprintf(file1,'%5.3f\t',PFA_All(i,Floor));
        end
        fprintf(file1,'\n');
    end
    fclose(file1);
end

if RECORDERS.RFV==1
    file1 = fopen('Summary Maximum PFV.txt','wt');
    for i=1:count
        for Floor = 1:NStory+1
            fprintf(file1,'%5.3f\t',PFV_All(i,Floor));
        end
        fprintf(file1,'\n');
    end
    fclose(file1);
end

if FloorLink==2
    if RECORDERS.SDR==1
        file1 = fopen('Summary Maximum SDR_EGF.txt','wt');
        for i=1:count
            for Story = 1:NStory
                fprintf(file1,'%5.4f\t',SDR_All_EGF(i,Story));
            end
            fprintf(file1,'\n');
        end
        fclose(file1);
    end
    
    if RECORDERS.SDR==1
        file1 = fopen('Summary Maximum RDR_EGF.txt','wt');
        for i=1:count
            for Story = 1:NStory
                fprintf(file1,'%5.4f\t',RDR_All_EGF(i,Story));
            end
            fprintf(file1,'\n');
        end
        fclose(file1);
    end
    
    if RECORDERS.RFA==1
        file1 = fopen('Summary Maximum PFA_EGF.txt','wt');
        for i=1:count
            for Floor = 1:NStory+1
                fprintf(file1,'%5.3f\t',PFA_All_EGF(i,Floor));
            end
            fprintf(file1,'\n');
        end
        fclose(file1);
    end
    
    if RECORDERS.RFV==1
        file1 = fopen('Summary Maximum PFV_EGF.txt','wt');
        for i=1:count
            for Floor = 1:NStory+1
                fprintf(file1,'%5.3f\t',PFV_All_EGF(i,Floor));
            end
            fprintf(file1,'\n');
        end
        fclose(file1);
    end
end

cd (MainDirectory);