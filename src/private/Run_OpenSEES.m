%##########################################################################################################
%##########################################################################################################
%##########################################################################################################
%#
%#  Executes Analysis Procedures (e.g., Pushover, Response-History and IDA) in OpenSEES
%#  and Processes the Analysis Output
%#
%# Written by: Ahmed Elkady, University of Southampton, UK
%#
%##########################################################################################################
%##########################################################################################################
%##########################################################################################################

function Run_OpenSEES (app)

clc; fclose('all');

global MainDirectory ProjectName ProjectPath
load(strcat(ProjectPath,ProjectName));

OpenSEESFileNameX=[' ',OpenSEESFileName];

cd (MainDirectory);

%##########################################################################################################
%##########################################################################################################
%##########################################################################################################
%##########################################################################################################
%##########################################################################################################
%##########################################################################################################
%##########################################################################################################
%##########################################################################################################

if IDA == 1 || Dynamic_TargetSF==1 || Dynamic_TargetSA==1

    count=0;
    
    %% LOOP OVER GMs
    for GM_No = GM_Start : GM_Last

            count=count+1;
            timeGM=tic;
            
        for Ri = 1 : nRealizations
        
            tic;
            RunTime=0;
            
            %% DELETE RESULTS SUBFOLDER BEFORE RUN
            try
            cd (strcat(RFpath,'\Results'));
            evalc(['rmdir  ','''',GM.Name{GM_No},'''',' s'])
            end
            cd (MainDirectory);

            app.ProgressText.Text=['Running Dynamic Analysis: GM #',num2str(GM_No)]; drawnow;
            
            %% CLEAR IDA STORAGE VECTORS AND INITIALIZE VARIABLES EACH NEW GM
            clear DATA IncrDATA; fclose('all');
            
            SF1_History 		  = zeros(20000,3);
            DATA.SA_last_NC 	  = 0;
            DATA.SDR_last_NC 	  = 0;
            DATA.PFA_last_NC 	  = 0;
            DATA.IDASlope_last_NC = 1;
            DATA.SDRincrmax 	  = 0;
            DATA.PFAincrmax 	  = 0;
            IncrNo 				  = 2;
            SAstep 				  = SA_Step;
            SAcurrent 			  = SAstep;
            IncrDATA.SA(1) 		  = 0;
            AnalysisCount 		  = 0;
            ALL_ANALYSED_SAs(1)   = 0;
            FigI 				  = 0;
            FigD 				  = 0;
            Collapse_Flag 		  = 0;
            Collapse 			  = 0;
            nGM_total             = GM_Last - GM_Start + 1;
            
            %% WRITE THE GM ACCELERATION DATA IT IN A TEXT FILE 'GM.txt'
            fileID = fopen('GM.txt', 'wt');
            evalc(strcat(['acc=GM.GM',num2str(GM_No),'acc']));
            fprintf(fileID,'%.5f\n', acc);
            fclose(fileID);
            
            %% GET CURRENT GM DATA AND WRITE IT IN A TEXT FILE 'GMinfo.txt'
            if Uncertainty==0;subfoldername=GM.Name{GM_No}; else; subfoldername=[GM.Name{GM_No},'_',num2str(Ri)]; end
            fileID=fopen('GMinfo.txt','wt');
            fprintf(fileID,'%d\n%s\n%d\n%f\n%s', GM_No, GM.Name{GM_No}, GM.npoints(GM_No), GM.dt(GM_No),subfoldername);
            
            %% GET IM FOR SCALING
            [GM] = Get_IM (T1, GM, acc, GM.dt(GM_No), g, zetaSA, SA_metric, coeff_T_lower, coeff_T_upper);
            
            %% IDA MAIN LOOP
            while SAcurrent < 10.0                                                                                  % Run as long as Collapse is not reached (Arbitrary High Value Since Algorithm Stops at Collapse)
                
                clc; fclose('all');

                AnalysisCount=AnalysisCount+1;                                                                      % Count the number of analysis cycles for one GM/realization (used to stop infinite loops)

                [SAprerunstatus,indx]=ismember(SAcurrent,ALL_ANALYSED_SAs);

                if SAprerunstatus==1
                    SAcurrent=mean([ALL_ANALYSED_SAs(indx) ALL_ANALYSED_SAs(min(indx+1,AnalysisCount-1))]);
                end
                
                %% Compute GM scale factor
                if Dynamic_TargetSF==1
                    SFcurrent=SF;
                    SAcurrent=SFcurrent*GM.GMpsaT1;
                elseif Dynamic_TargetSA==1
                    SFcurrent=TargetSA/GM.GMpsaT1;                                                                 % Calculate Current Scale Factor for Current SA
                else
                    SFcurrent=SAcurrent/GM.GMpsaT1;                                                                 % Calculate Current Scale Factor for Current SA
                end
                
                %% Show run info message on main console
                if     IDA==1;                   app.ProgressText.Text=['Running Dynamic Analysis: GM #',num2str(GM_No), ' at Incr #',num2str(IncrNo-1),', SF=',num2str(round(SFcurrent*10)/10)]; drawnow;
                elseif IDA~=1 && Uncertainty==0; app.ProgressText.Text=['Running Dynamic Analysis: GM #',num2str(GM_No), ' at SF=',num2str(round(SFcurrent*10)/10)]; drawnow;
                elseif IDA~=1 && Uncertainty==1; app.ProgressText.Text=['Running Dynamic Analysis: GM #',num2str(GM_No), ' at R= #',num2str(Ri),', SF=',num2str(round(SFcurrent*10)/10)]; drawnow; end
                
                fileID3=fopen('CollapseState.txt','wt');     														% Create/Open and Clear contents of CollapseState.txt file each increment
                fileID4=fopen('SF.txt','wt');                														% Create/Open and Clear contents of SF.txt file each increment
                fprintf(fileID4,'%f',SFcurrent);             														% Write value of the Scale Factor of the current GM to SF.txt file
                
                ALL_ANALYSED_SAs(AnalysisCount)=SAcurrent;                                                          % Saves all the analyzed SA values during IDA (helps avoid repeatition of analysis during the collapse point trace)
                ALL_ANALYSED_SAs=sort(ALL_ANALYSED_SAs);
                
                Show_Status_Dynamic(GM_No, GM, SAstep, SAcurrent, SFcurrent, DATA.SDRincrmax, DATA.PFAincrmax, DATA.SA_last_NC, DATA.SDR_last_NC, DATA.PFA_last_NC , RunTime, Collapse_Flag, SA_metric, IDA)
                
                %% RUN OPENSEES MODEL
                [RunTime]=Run_exe(OpenSEESFileNameX,ShowOpenseesStatus);
                
                %% READ OPENSEES OUTPUT FILES
                [DATA] = Read_Analysis_Data (MainDirectory,RFpath,GM_No,GM,NStory,Filename,g,SFcurrent,DATA,Recorders, subfoldername);
                
                %% CHECK IF NUMERICAL INSTABILITY OCCURED
                if DATA.SDRincrmax > 0.5 || DATA.PFAincrmax > 20; NumInstability_Flag = 1; else; NumInstability_Flag = 0; end
                
                %% CHECK IF COLLAPSE OCCURED AND IF IT DID, TRACE COLLAPSE POINT
                fileID 	 = 	  fopen('CollapseState.txt','r');                                      					% Open 'CollapseState.txt'
                Collapse = textread('CollapseState.txt','%d');                              						% Read Value of Collapse Index (reads 1 in case of collapse)
                if isempty(Collapse); Collapse=0; end
                
                %% In case of Collapse
                if Collapse == 1  && DATA.SDRincrmax > 0.15  %&& DATA.SDRincrmax < 1.0 && DATA.PFAincrmax < 10

                    %% Collapse point tracing
                    if AnalysisCount~=1
                        SAcurrent = max(DATA.SA_last_NC+0.01, SAcurrent - 0.5 * SAstep);             				% Roll back 1/2 step
                        SAstep    = max(0.02, 0.5 * SAstep);                                    					% Modify step size to 1/2 of previous step
                    else
                        SAcurrent=SAcurrent/3;
                        SAstep=SAstep/3;
                    end

                    Collapse_Flag = 999;                                                    						% Set collapse flag
                
                %% In case of No Collapse
                else                                                                        						
                    
                    if ShowScope==1
                        if    IDA==1; [FigI] = Show_Scope_IDA      (AnalysisCount,SAcurrent,NumInstability_Flag,DATA.SDRincrmax,DATA.PFAincrmax,DATA.PFA_last_NC,CollapseSDR,FigI);
                        else;         [FigD] = Show_Scope_Dynamic  (NumInstability_Flag,Collapse,DATA.SDRincrmax,DATA.PFAincrmax,nGM_total,count,FigD,Ri); 
                        end
                    end

                    % Compute the slope of the IDA curve
                    IDA_Slope = (DATA.SDRincrmax - DATA.SDR_last_NC) / (SAcurrent - DATA.SA_last_NC);
                    
                    %% When there is no numerical instability
                    if NumInstability_Flag == 0
                        [IncrDATA] = Save_Increment_Data (NStory,IncrNo, SAcurrent,DATA,IncrDATA,Recorders);
                        if IncrNo<=2; IDASlope_Ratio=1; IDASlope_0=SAcurrent/DATA.SDRincrmax; else; IDASlope_Ratio=abs((SAcurrent-DATA.SA_last_NC)/(DATA.SDRincrmax-DATA.SDR_last_NC))/IDASlope_0; end % added 08/2019
                        DATA.IDASlope_last_NC=abs((SAcurrent-DATA.SA_last_NC)/(DATA.SDRincrmax-DATA.SDR_last_NC));                                                          % added 08/2019
                        
                        DATA.SA_last_NC  = SAcurrent;
                        DATA.SDR_last_NC = DATA.SDRincrmax;
                        DATA.PFA_last_NC = DATA.PFAincrmax;
                        
                        %% Collapse point tracing
                        if AdaptiveTimeStep==1 && Collapse_Flag ~= 999                                          
                            SAstep     = max(min(IDASlope_Ratio*SAstep,SAstep),SAstepmin+0.01);                 % Compute SA step depending on IDA slope
                            SAcurrent  = SAcurrent + SAstep;                                                    % Compute new SA level
                        else
                            if DATA.SDR_last_NC < 0.05
                                SAcurrent  = SAcurrent + SAstep;                                    		    % Move to Next SA level by 1 Step
                            else
                                SAcurrent  = SAcurrent + 0.5* SAstep;                                    		% Move to Next SA level by 0.5 Step
                            end
                        end

                        IncrNo     = IncrNo    + 1;                                         					% Increase Counter for IDA Vectors IncrNos
                        
                        % Exit loop criteria
                        if SAstep <= SAstepmin; break; end                                                      % If the current SA step is smaller than the specified minimum

                    %% When there is numerical instability
                    else

                        if AnalysisCount~=1
                            if Collapse_Flag == 999
                                SAcurrent = max(DATA.SA_last_NC+0.01, SAcurrent - 0.01);
                            else
                                SAcurrent = DATA.SA_last_NC + 0.01;
                            end
                        else
                            SAcurrent = SAcurrent/3;
                            SAstep    = SAstep/3; 
                        end

                    end
                end
                
                %% EXIT LOOP CRITERIA
                if IDA==1 

                    if Collapse ~= 1  && IDA_Slope > IDAslopeLimit;                             break; end  % If IDA slope limit is reached
                    if Collapse ~= 1  && DATA.SDR_last_NC > CollapseSDR;                        break; end  % If collapse SDR limit is reached
                    if DATA.SDR_last_NC>0.1 && RunTime>0.50*60*60;                              break; end  % If SDR is larger than 10% but run time exceeds 1 hour (this is a fail safe)
                    if Collapse ~= 1 &&  AnalysisCount~=1 && SAcurrent==DATA.SA_last_NC+0.01;   break; end  % If the tracing algorithm rolled back to last NC point
                   %if Collapse == 1  && AnalysisCount>10;                                      break; end  % If number of analysis runs exceeds 10 (implies an infinite loop)
                
                elseif Dynamic_TargetSA==1 || Dynamic_TargetSF==1
                
                    if Collapse_Flag==999 || IncrNo>=3 || toc(timeGM)/60>MaxRunTime;            break; end  % If collapse occurs or re-run increments >=3 or GM run time exceeds maximum specified runtime
                
                end

                if RunTime>1.0*60*60;                                                           break; end  % If run time exceeds 1 hour (this is a fail safe)
            end
            
            %% Save IDA data summary
            if IDA==1; Save_Results_IDA(MainDirectory,RFpath,GM_No,GM,NStory,IncrNo,IncrDATA,Delete_Flag,Recorders); end
            
            %% Close the scope figure at end of each GM
            if ShowScope==1 && IDA==1;   close (FigI); end
        end
    end
    
    %% Save dynamic data summary
    if Dynamic_TargetSF==1 || Dynamic_TargetSA==1
        app.ProgressText.Text='Saving Summary Data'; drawnow;
        Save_Results_Dynamic;
    end
    

%##########################################################################
%##########################################################################
%##########################################################################
%##########################################################################
%##########################################################################
%##########################################################################
%##########################################################################
%##########################################################################

elseif PO == 1 || ELF==1
    
    tic;
    
    if PO==1;  app.ProgressText.Text='Running Pushover Analysis...'; drawnow; end
    if ELF==1; app.ProgressText.Text='Running ELF Analysis...';      drawnow; end
    
    % RUN OPENSEES MODEL
    [~]=Run_exe(OpenSEESFileNameX,ShowOpenseesStatus);
    
elseif TTH==1

    app.ProgressText.Text='Saving Summary Data'; drawnow;
    Save_Results_TTH;

end

%##########################################################################
%################################%#########################################
%################################%#########################################
%##########################################################################
%##########################################################################
%##########################################################################
%##########################################################################

cd (MainDirectory)
fclose all;