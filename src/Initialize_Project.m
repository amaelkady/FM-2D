function Initialize_Project(MainDirectory, ProjectPath, ProjectName, Units, FrameType, BuildingDescription)

if Units==1; g = 9810.0; end % mm/sec2
if Units==2; g = 386.1;  end % in/sec2

xx=ProjectName;
xx=xx(1:end-4);
xx= xx(~isspace(xx)); % remove spaces from project name to get opensees file name
OpenSEESFileName = [xx,'.tcl'];

BuildOption         = 2;
ExecutionOption     = 1;
Uncertainty         = 0;

EV                  = 1;
PO                  = 0;
ELF                 = 0;
Dynamic_TargetSF    = 0;
Dynamic_TargetSA    = 0;
EQ                  = 0;

Animation           = 0;
MaxRunTime          = 0;
ShowOpenseesStatus  = 0;

Modelstatus         = 0;
Definestatus        = 0;
Analysisstatus      = 0;
Runstatus           = 0;
Sigmastatus         = 0;

ModePO              = 1;
DriftPO             = 0.1;
DampModeI           = 1;
DampModeJ           = 1;
zeta                = 0.02;
BraceLayout         = 0;
BRACES              = 0;
MGP_W               = 0;
EBF_W               = 0;
MF_SL               = 0;
CGP_RigidOffset     = 0;
MGP_RigidOffset     = 0;
MFconnection        = 0;
MidSpanConstraint   = 0;
fyBrace             = 0;
fyGP                = 0;
a                   = 0;
b                   = 0;
c                   = 0;

GM                  = 0;

Recorders.Time          = 0;
Recorders.Disp          = 0;
Recorders.SDR           = 0;
Recorders.Column        = 0;
Recorders.ColSpring     = 0;
Recorders.Beam          = 0;
Recorders.BeamSpring    = 0;
Recorders.PZ            = 0;
Recorders.RFA           = 0;
Recorders.FloorLink     = 0;
Recorders.EGFconnection = 0;
Recorders.Brace         = 0;
Recorders.CGP           = 0;
Recorders.Support       = 0;
Recorders.RFV           = 0;
Recorders.EigenModes    = 1;
Recorders.EigenVectors  = 1;

Filename.Disp           = 'Disp';
Filename.SDR            = 'SDR';
Filename.Column         = 'Column';
Filename.ColSpring      = 'ColSpring';
Filename.Beam           = 'Beam';
Filename.BeamSpring     = 'BeamSpring';
Filename.PZ             = 'PZ';
Filename.RFA            = 'RFA';
Filename.RFV            = 'RFV';
Filename.FloorLink      = 'FloorLink';
Filename.Brace          = 'Brace';
Filename.CGP            = 'CGP';
Filename.Support        = 'Support';

nRealizations           = 1;
Sigma.IMKcol(1:9)       = 1.e-9;
Sigma.IMKbeam(1:9)      = 1.e-9;
Sigma.Pinching4(1:9)    = 1.e-9;
Sigma.PZ (1:4)          = 1.e-9;
Sigma.fy                = 1.e-9;
Sigma.fyB               = 1.e-9;
Sigma.fyG               = 1.e-9;
Sigma.zeta              = 1.e-9;
Sigma.GI                = 1.e-9;

% save the initialized data in the project *.mat file
cd(ProjectPath)
save(ProjectName, '-regexp', '^(?!(event|app)$).')
cd(MainDirectory)