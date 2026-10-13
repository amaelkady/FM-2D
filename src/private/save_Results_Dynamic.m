function save_Results_Dynamic()

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'RFpath','NStory','Parallel','Uncertainty','nRealizations','GM','RECORDERS','FILENAME','g','FloorLink','GM_Start','GM_Last','SF','TargetSA','Dynamic_TargetSF','Dynamic_TargetSA');

clc;

count=0;
seenRunIds=strings(0,1);
for GM_No=GM_Start:GM_Last

    GMdt  = GM.dt  {:,GM_No};
    GMacc = GM.acc {:,GM_No};

    for Ri=1:nRealizations
        clear Eq
        
        %% Compute GM scale factor
        if Dynamic_TargetSF==1
            SF_GM=SF;
        elseif Dynamic_TargetSA==1
            SF_GM=TargetSA/GM.sa{:,GM_No};                                                                 % Calculate Current Scale Factor for Current SA
        else
            SF_GM=SF;                                                                 % Calculate Current Scale Factor for Current SA
        end
                
        count=count+1;
        
        if Uncertainty == 0; subfoldername= GM.name{:,GM_No};       else; subfoldername=[GM.name{:,GM_No},'_',num2str(Ri)]; end
        if Parallel==1 && Uncertainty==0; subfoldername=[GM.name{:,GM_No},'_1']; end
        
        % Go inside the results folder and read results
        cd (strcat(RFpath,'\Results\',subfoldername));

        metadata=load('RunResult.mat','RunResult');
        RunResult=metadata.RunResult;
        if ~ismember(RunResult.State,["COMPLETED","COLLAPSE"])
            error('FM2D:InvalidSummaryRun','Cannot summarize a failed or incomplete run.');
        end
        if Parallel==1 && Uncertainty==1
            if ~isfield(RunResult,'Job') || RunResult.Job.GM_No~=GM_No || RunResult.Job.Ri~=Ri || ...
                    any(seenRunIds==string(RunResult.RunId))
                error('FM2D:DuplicateSummaryRun','Expected a unique run for GM %d, realization %d.',GM_No,Ri);
            end
            seenRunIds(end+1,1)=string(RunResult.RunId);
            SF_GM=RunResult.Job.SF;
        end
        RunStates(count)=string(RunResult.State);
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
        
        % Collapse output is truncated; its final drift is not a residual drift.
        if RunResult.State=="COLLAPSE" && RECORDERS.SDR==1
            RDR_All(count,:)=NaN;
            if FloorLink==2, RDR_All_EGF(count,:)=NaN; end
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
        Analysistime=time(12:end,1);
        [GMacc_Inter,GMvel_Inter]=get_GM_Kinematics(GMacc,GMdt,Analysistime,g);
        
        if RECORDERS.RFA==1
            for Floor=1:NStory+1
                x=MF_RFA{Floor}(12:end,1)+ SF_GM * GMacc_Inter(:,1);
                PFA_All(count,Floor)=max(abs(x));
                if FloorLink==2
                    x=EGF_RFA{Floor}(12:end,1)+ SF_GM * GMacc_Inter(:,1);
                    PFA_All_EGF(count,Floor)=max(abs(x));
                end
            end
        end
        
        if RECORDERS.RFV==1
            for Floor=1:NStory+1
                x=MF_RFV{Floor}(12:end,1)+ SF_GM * GMvel_Inter(:,1);
                PFV_All(count,Floor)=max(abs(x));
                if FloorLink==2
                    x=EGF_RFV{Floor}(12:end,1)+ SF_GM * GMvel_Inter(:,1);
                    PFV_All_EGF(count,Floor)=max(abs(x));
                end
            end
        end
        
    end
end

%% Save Processed IDA Data to a Text File in a Different Folder for Each GM
cd (strcat(RFpath,'\Results'));


fstatus=fopen('Summary Run Status.txt','wt');
if fstatus<0, error('FM2D:FileError','Cannot write run-status summary.'); end
fprintf(fstatus,'%s\n',RunStates);
fclose(fstatus);

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