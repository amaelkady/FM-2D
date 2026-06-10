function initialize_Project()
global MainDirectory ProjectName ProjectPath Units FrameType BuildingDescription resource_root

if Units==1; g = 9810.0; end % mm/sec2
if Units==2; g = 386.1;  end % in/sec2

xx=ProjectName;
xx=xx(1:end-4);
xx= xx(~isspace(xx)); % remove spaces from project name to get opensees file name
OpenSEESFileName = [xx,'.tcl'];
clear xx;

PROJECT.Version             = 5.2606;
PROJECT.MainDirectory       = MainDirectory;
PROJECT.ProjectPath         = ProjectPath;
PROJECT.ProjectName         = ProjectName;
PROJECT.OpenSEESFileName    = OpenSEESFileName;
PROJECT.Units               = Units;
PROJECT.FrameType           = FrameType;
PROJECT.BuildingDescription = BuildingDescription;
PROJECT.resource_root       = resource_root;

STATUS.Model        = 0;
STATUS.Build        = 0;
STATUS.Analysis     = 0;
STATUS.Run          = 0;
STATUS.Sigma        = 0;

BuildOption         = 1;
ExecutionOption     = 1;

ANALYSIS.g                   = g;
ANALYSIS.Uncertainty         = 0;
ANALYSIS.nRealizations       = 1;

ANALYSIS.EV                  = 1;
ANALYSIS.PO                  = 0;
ANALYSIS.ELF                 = 0;
ANALYSIS.Dynamic_TargetSF    = 0;
ANALYSIS.Dynamic_TargetSA    = 0;
ANALYSIS.EQ                  = 0;
ANALYSIS.CDPO                = 0;
ANALYSIS.TTH                 = 0;

ANALYSIS.Animation           = 0;
ANALYSIS.MaxRunTime          = 0;
ANALYSIS.ShowOpenseesStatus  = 0;

ANALYSIS.ModePO              = 1;
ANALYSIS.DriftPO             = 0.1;
ANALYSIS.DampModeI           = 1;
ANALYSIS.DampModeJ           = 1;
ANALYSIS.zeta                = 0.02;
ANALYSIS.zetaSA              = 0.05;
ANALYSIS.GM                  = 0;
ANALYSIS.TFreeVibration      = 0;
ANALYSIS.dtstep              = 0;
ANALYSIS.CollapseSDR         = 0.2;
ANALYSIS.dinundation         = 0;
ANALYSIS.Drag_Coeff          = 1.2;
ANALYSIS.ro_water            = 1.2;   
ANALYSIS.CDPOpattern         = 1;
ANALYSIS.Parallel            = 0;
ANALYSIS.nCores              = 1;

LAYOUT.BraceLayout           = 0;

PROPERTY.BRACES              = 0;
PROPERTY.MGP_W               = 0;
PROPERTY.EBF_W               = 0;
PROPERTY.MF_SL               = 0;
PROPERTY.CGP_RigidOffset     = 0;
PROPERTY.MGP_RigidOffset     = 0;

LOAD.cLoad                   = 1;
LOAD.LoadApplyOption         = 1;

CONNECTION.MFconnection        = 1;
CONNECTION.MidSpanConstraint   = 1;
CONNECTION.a                   = 0;
CONNECTION.b                   = 0;
CONNECTION.c                   = 0;
CONNECTION.SupportGFS          = 2;
CONNECTION.Kshearstatus        = 0;
CONNECTION.MFconnectionEven    = 1;
CONNECTION.MFconnectionOdd     = 1;   

MATERIAL.Ec                  = 0;    
MATERIAL.Er                  = 0;   
MATERIAL.fc                  = 0;
MATERIAL.fyR                 = 0;
MATERIAL.fyBrace             = 0;
MATERIAL.fyGP                = 0;
MATERIAL.muC                 = 0;
MATERIAL.muR                 = 0;
    
MODEL.DiscritizationOption = 1;

RECORDERS.Time          = 0;
RECORDERS.Disp          = 0;
RECORDERS.SDR           = 0;
RECORDERS.Column        = 0;
RECORDERS.ColSpring     = 0;
RECORDERS.Beam          = 0;
RECORDERS.BeamSpring    = 0;
RECORDERS.PZ            = 0;
RECORDERS.RFA           = 0;
RECORDERS.FloorLink     = 0;
RECORDERS.EGFconnection = 0;
RECORDERS.Brace         = 0;
RECORDERS.CGP           = 0;
RECORDERS.Support       = 0;
RECORDERS.RFV           = 0;
RECORDERS.EigenModes    = 1;
RECORDERS.EigenVectors  = 1;

FILENAME.Disp           = 'Disp';
FILENAME.SDR            = 'SDR';
FILENAME.Column         = 'Column';
FILENAME.ColSpring      = 'ColSpring';
FILENAME.Beam           = 'Beam';
FILENAME.BeamSpring     = 'BeamSpring';
FILENAME.PZ             = 'PZ';
FILENAME.RFA            = 'RFA';
FILENAME.RFV            = 'RFV';
FILENAME.FloorLink      = 'FloorLink';
FILENAME.Brace          = 'Brace';
FILENAME.CGP            = 'CGP';
FILENAME.Support        = 'Support';
FILENAME.EGFconnection  = 'EGFconnection';

SIGMA.IMKcol(1:9)       = 1.e-9;
SIGMA.IMKbeam(1:9)      = 1.e-9;
SIGMA.Pinching4(1:9)    = 1.e-9;
SIGMA.PZ (1:4)          = 1.e-9;
SIGMA.fy                = 1.e-9;
SIGMA.fyB               = 1.e-9;
SIGMA.fyG               = 1.e-9;
SIGMA.zeta              = 1.e-9;
SIGMA.GI                = 1.e-9;

clear MainDirectory ProjectName ProjectPath Units FrameType BuildingDescription OpenSEESFileName g

% save the initialized data in the project *.mat file
save(strcat(PROJECT.ProjectPath,PROJECT.ProjectName), '-regexp', '^(?!(event|app)$).','-v7.3','-nocompression');
