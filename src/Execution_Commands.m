function Execution_Commands(app, FrameType, ExecutionOption, RFpath, EV, PO, EQ, ELF, PM_Option, BraceLayout)
global MainDirectory ProjectName ProjectPath

if ExecutionOption==1
    
    BuildOption=2;
    cd (ProjectPath)
    save(ProjectName,'BuildOption','-append')
    cd (MainDirectory)
    
    if EV==1;   AnalysisTypeID=1; end
    if PO==1;   AnalysisTypeID=2; end
    if EQ==1;   AnalysisTypeID=3; end
    if ELF==1;  AnalysisTypeID=4; end
    
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
        
    else
        
        app.ProgressText.Text='Running Preliminary Eigenvalue Analysis...'; drawnow;
        if BraceLayout==1;  CREATOR_MODEL_CBF_XBRACING(1,0);  end
        if BraceLayout==2;  CREATOR_MODEL_CBF_CHEVRON (1,0);  end
                            CREATOR_ANALYSIS          (1,0);
        eval(strcat('! OpenSees.exe TempModel.tcl'));
        fclose all;

        app.ProgressText.Text='Creating Main tcl File...'; drawnow;
        if BraceLayout==1;   CREATOR_MODEL_CBF_XBRACING(AnalysisTypeID,0); end
        if BraceLayout==2;   CREATOR_MODEL_CBF_CHEVRON(AnalysisTypeID,0);  end
        CREATOR_ANALYSIS(AnalysisTypeID,0);
        
    end
    
    if EV==1
        app.ProgressText.Text='Running Eigenvalue Analysis...'; drawnow;
        evalc(strcat(['! OpenSEES.exe ', OpenSEESFileName]));
        Process_EigenAnalysis;
    else
        app.Image.Visible      = 'on';
        Run_OpenSEES (app);
    end
    
    if PM_Option==1
        cd(RFpath)
        cd('Results')
        delete('TempPushover')
        cd(MainDirectory)
    end
else
    
    app.Image.Visible      = 'on';
    app.ProgressText.Text  = 'Running Preliminary Eigenvalue Analysis...'; drawnow;
    
    CREATOR_MODEL_MRF(1,0);
    CREATOR_ANALYSIS (1,0);
    eval(strcat('! OpenSees.exe TempModel.tcl'));
    fclose all;
    
    Run_OpenSEES (app);
end

% Delete analysis files
fclose all;
delete ('LPmode.tcl');
delete ('TempModel.tcl');
delete ('TempModelPO.tcl');
delete ('EigenPeriod.out');
delete ('POmodepattern.out');
delete ('CollapsedFrame.txt');
delete ('CollapseState.txt');
delete ('GMinfo.txt');
delete ('GM.txt');
delete ('SF.txt');