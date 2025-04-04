function build_TCL_file(app)

global  ProjectPath ProjectName

load(strcat(ProjectPath,ProjectName),'OpenSEESFileName','FrameType','EV','PO','EQ','ELF','CDPO','TTH','PM_Option','DiscritizationOption');

BuildOption=2;
save(strcat(ProjectPath,ProjectName),'BuildOption','-append')

if     EV==1;   AnalysisTypeID=1; 
elseif PO==1;   AnalysisTypeID=2; 
elseif EQ==1;   AnalysisTypeID=3; 
elseif ELF==1;  AnalysisTypeID=4; 
elseif CDPO==1; AnalysisTypeID=5;
elseif TTH==1;  AnalysisTypeID=6; end

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
        if DiscritizationOption ==1
            CREATOR_MODEL_MRF_RC(1,0);
        else
            CREATOR_MODEL_MRF_RC_Fiber(1,0);
        end
        CREATOR_ANALYSIS(1,0);
        eval(strcat('! OpenSees.exe TempModel.tcl'));
        fclose all;
    end

    app.ProgressText.Text='Creating Main tcl File...'; drawnow;

    if DiscritizationOption ==1
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

if AnalysisTypeID~=1
    copyfile(OpenSEESFileName,ProjectPath,'f');
    app.ProgressText.Text  = 'Tcl file is created; check project directory!'; drawnow;
else
    app.ProgressText.Text  = 'Build tcl option is only available for pushover and dynamic analysis options!'; drawnow;
end