function save_Results_Dynamic()

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'RFpath','NStory','Parallel','Uncertainty','nRealizations','GM','RECORDERS','FILENAME','g','FloorLink','GM_Start','GM_Last','SF','TargetSA','Dynamic_TargetSF','Dynamic_TargetSA');

clc;

count=0;
seenRunIds=strings(0,1);
RunGM=[]; RunRi=[]; RunReached=[]; RunTarget=[];
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
        if ~ismember(RunResult.State,["COMPLETED","COLLAPSE","NONCONVERGED"])
            error('FM2D:InvalidSummaryRun','Cannot summarize a failed or incomplete run.');
        end
        if RunResult.State=="NONCONVERGED" && (~all(isfield(RunResult,{'Stage','Reached','Target'})) || RunResult.Stage~="DYNAMIC" || ...
                ~isfinite(RunResult.Reached) || ~isfinite(RunResult.Target) || ...
                RunResult.Reached<=0 || RunResult.Reached>=RunResult.Target)
            error('FM2D:InvalidSummaryRun','Invalid partial dynamic outcome.');
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
        RunGM(count)=GM_No; RunRi(count)=Ri;
        RunReached(count)=NaN; RunTarget(count)=NaN;
        if isfield(RunResult,'Reached'), RunReached(count)=RunResult.Reached; end
        if isfield(RunResult,'Target'), RunTarget(count)=RunResult.Target; end
        %% Read Time Data
        dumVar=importdata('Time.out');
        time=dumVar(:,1);
        
        %% Read SDR data
        if RECORDERS.SDR==1
            for Story=1:NStory
                x=importdata([FILENAME.SDR,num2str(Story),'_MF.out']);
                SDR_All(count,Story)=max(abs(x(12:end,1)));
                RDR_All(count,Story)=    abs(x(end,1));
                
                if FloorLink==2
                    x=importdata([FILENAME.SDR,num2str(Story),'_EGF.out']);
                    SDR_All_EGF(count,Story)=max(abs(x(12:end,1)));
                    RDR_All_EGF(count,Story)=    abs(x(end,1));
                end
            end
        end
        
        % Collapse output is truncated; its final drift is not a residual drift.
        if ismember(RunResult.State,["COLLAPSE","NONCONVERGED"]) && RECORDERS.SDR==1
            RDR_All(count,:)=NaN;
            if FloorLink==2, RDR_All_EGF(count,:)=NaN; end
        end
        %% Read Floor Relative Acceleration data
        if RECORDERS.RFA==1
            for Floor=1:NStory+1
                MF_RFA{Floor}=importdata([FILENAME.RFA,num2str(Floor),'_MF.out'])/g;
                if FloorLink==2, EGF_RFA{Floor}=importdata([FILENAME.RFA,num2str(Floor),'_EGF.out'])/g; end
            end
        end
        
        %% Read Floor Relative Velocity data
        if RECORDERS.RFV==1
            for Floor=1:NStory+1
                MF_RFV{Floor}=importdata([FILENAME.RFV,num2str(Floor),'_MF.out']);
                if FloorLink==2, EGF_RFV{Floor}=importdata([FILENAME.RFV,num2str(Floor),'_EGF.out']); end
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

% Truncated histories provide lower-bound peaks, never completed-run maxima
% or residual drifts. Preserve row alignment and save their peaks separately.
partial=RunStates=="NONCONVERGED";
if RECORDERS.SDR==1
    SDR_All=save_Partial_Peaks(SDR_All,partial,'SDR');
    if FloorLink==2, SDR_All_EGF=save_Partial_Peaks(SDR_All_EGF,partial,'SDR_EGF'); end
end
if RECORDERS.RFA==1
    PFA_All=save_Partial_Peaks(PFA_All,partial,'PFA');
    if FloorLink==2, PFA_All_EGF=save_Partial_Peaks(PFA_All_EGF,partial,'PFA_EGF'); end
end
if RECORDERS.RFV==1
    PFV_All=save_Partial_Peaks(PFV_All,partial,'PFV');
    if FloorLink==2, PFV_All_EGF=save_Partial_Peaks(PFV_All_EGF,partial,'PFV_EGF'); end
end
RunOutcomes=table(RunGM(:),RunRi(:),RunStates(:),RunReached(:),RunTarget(:), ...
    'VariableNames',{'GM_No','Realization','State','Reached_s','Target_s'});
writetable(RunOutcomes,'Summary Run Outcomes.csv');

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
end

function values=save_Partial_Peaks(values,partial,name)
% Keep partial maxima in explicitly named files, with other rows left empty.
filename=['Summary Partial Maximum ' name '.txt'];
if ~any(partial)
    if isfile(filename), delete(filename); end
    return
end
lowerBounds=NaN(size(values)); lowerBounds(partial,:)=values(partial,:);
writematrix(lowerBounds,filename,'Delimiter','tab');
values(partial,:)=NaN;
end
