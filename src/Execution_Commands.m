function Execution_Commands(app, FrameType, ExecutionOption, OpenSEESFileName, RFpath, EV, PO, EQ, ELF, CDPO, TTH, PM_Option, BraceLayout)
global MainDirectory ProjectName ProjectPath

cd(RFpath);
mkdir('Results');

% Delete existing analysis folder
try
cd ('Results'); 
if     EV==1;   rmdir 'EigenAnalysis' s; 
elseif PO==1;   rmdir 'Pushover' s;  
elseif ELF==1;  rmdir 'ELF' s; 
elseif CDPO==1; rmdir 'CDPO' s; 
elseif TTH==1;  rmdir 'TTH' s; end
end
cd (MainDirectory);


if ExecutionOption==1
    
    BuildOption=2;
    save(strcat(ProjectPath,ProjectName),'BuildOption','-append')
    load(strcat(ProjectPath,ProjectName),'DiscritizationOption')
    
    delete POmodepattern.out;
    
    if     EV   == 1;  AnalysisTypeID=1; 
    elseif PO   == 1;  AnalysisTypeID=2;
    elseif EQ   == 1;  AnalysisTypeID=3;
    elseif ELF  == 1;  AnalysisTypeID=4;
    elseif CDPO == 1;  AnalysisTypeID=5;
    elseif TTH  == 1;  AnalysisTypeID=6; end

    if FrameType==1
        
        if PM_Option==1
            app.ProgressText.Text='Running Preliminary Eigenvalue Analysis...'; drawnow;
            CREATOR_MODEL_MRF(1,1);
            CREATOR_ANALYSIS (1,1);
            eval(strcat('! OpenSees.exe TempModel.tcl'));
            
            app.ProgressText.Text='Running Preliminary Pushover Analysis'; drawnow;
            CREATOR_MODEL_MRF(2,1);
            CREATOR_ANALYSIS (2,1);
            eval(strcat('! OpenSees.exe TempModelPO.tcl'));
            fclose all;
        end
        
        if EV~=1 && PM_Option~=1
            app.ProgressText.Text='Running Preliminary Eigenvalue Analysis...'; drawnow;
            CREATOR_MODEL_MRF(1,0);
            CREATOR_ANALYSIS(1,0);
            eval(strcat('! OpenSees.exe TempModel.tcl'));
            fclose all;
        end
        
        app.ProgressText.Text='Creating Main tcl File...'; drawnow;
        
        CREATOR_MODEL_MRF(AnalysisTypeID,0);
        CREATOR_ANALYSIS (AnalysisTypeID,0);
        
    elseif FrameType==4
        
        if EV~=1
            app.ProgressText.Text='Running Preliminary Eigenvalue Analysis...'; drawnow;
            
            if DiscritizationOption==1
                CREATOR_MODEL_MRF_RC(1,0);
            else
                CREATOR_MODEL_MRF_RC_Fiber(1,0);
            end
            CREATOR_ANALYSIS(1,0);
            eval(strcat('! OpenSees.exe TempModel.tcl'));
            fclose all;
        end
        
        app.ProgressText.Text='Creating Main tcl File...'; drawnow;
        
        if DiscritizationOption==1
            CREATOR_MODEL_MRF_RC(AnalysisTypeID,0);
        else
            CREATOR_MODEL_MRF_RC_Fiber(AnalysisTypeID,0);
        end

        CREATOR_ANALYSIS (AnalysisTypeID,0);
    else
        
        app.ProgressText.Text='Running Preliminary Eigenvalue Analysis...'; drawnow;
        CREATOR_MODEL_CBF (1,0); 
        CREATOR_ANALYSIS  (1,0);
        eval(strcat('! OpenSees.exe TempModel.tcl'));
        fclose all;

        app.ProgressText.Text='Creating Main tcl File...'; drawnow;
        CREATOR_MODEL_CBF (AnalysisTypeID,0);
        CREATOR_ANALYSIS  (AnalysisTypeID,0);
        
    end
    
    if EV==1
        app.ProgressText.Text='Running Eigenvalue Analysis...'; drawnow;
        %evalc(strcat(['! OpenSEES.exe ', OpenSEESFileName]));
        eval(strcat('! OpenSees.exe TempModel.tcl'));
        Process_EigenAnalysis;
    else
        app.Image.Visible      = 'on';
        Run_OpenSEES (app);
    end
    
    if PM_Option==1
        cd(strcat(RFpath,'\Results'));
        delete('TempPushover')
        cd(MainDirectory)
    end
    
else
    
    app.Image.Visible      = 'on';
    app.ProgressText.Text  = 'Running Preliminary Eigenvalue Analysis...'; drawnow;
    
    if     FrameType==1; CREATOR_MODEL_MRF(1,0);
    elseif FrameType==4; if DiscritizationOption==1; CREATOR_MODEL_MRF_RC(1,0); else; CREATOR_MODEL_MRF_RC_Fiber(1,0); end
    else                 CREATOR_MODEL_CBF(1,0); end
    CREATOR_ANALYSIS (1,0);
    eval(strcat('! OpenSees.exe TempModel.tcl'));
    fclose all;
    
    cd(ProjectPath)
    copyfile(OpenSEESFileName,MainDirectory,'f');
    cd(MainDirectory)

    Run_OpenSEES (app);
end

write2file_ProjectSummary(RFpath);  

% Delete analysis files
fclose all;
delete  LPmode.tcl ...
        TempModel.tcl ...
        TempModelPO.tcl ...
        EigenPeriod.out ...
        POmodepattern.out ...
        CollapsedFrame.txt ...
        CollapseState.txt ...
        GMinfo.txt ...
        GM.txt  ...
        SF.txt;