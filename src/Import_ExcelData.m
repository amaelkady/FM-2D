function PROPERTY=import_ExcelData(FrameType, ExcelFilePath, ExcelFileName, NStory, NBay, FloorLink, MFconnection, GFX)
global  MainDirectory Units

cd(ExcelFilePath)

[num,~,~] = xlsread(ExcelFileName,'H_story','B2:B100');
HStory=num(1:NStory,1);

[num,~,~] = xlsread(ExcelFileName,'W_bay','B2:B100');
WBay=num(1:NBay,1);

[~,~,Data] = xlsread(ExcelFileName,'MF Columns','B2:K100');
MF_COLUMNS=Data(1:NStory,1:NBay+1);

[~,~,Data] = xlsread(ExcelFileName,'MF Beams','B2:K100');
MF_BEAMS=Data(1:NStory,1:NBay);

[~,~,Data] = xlsread(ExcelFileName,'GFS Columns','B2:B100');
GF_COLUMNS=Data(1:NStory,1);

[~,~,Data] = xlsread(ExcelFileName,'GFS Beams','B2:B100');
GF_BEAMS=Data(1:NStory,1);

[num,~,~] = xlsread(ExcelFileName,'Doubler Plates','B2:K100');
Doubler=num(1:NStory,1:NBay+1);

[num,~,~] = xlsread(ExcelFileName,'Column Splice','B2:C100');
Splice=num(1:NStory,:);

if  FloorLink ==2
    [num,~,~] = xlsread(ExcelFileName,'Fs Profile','B2:B50');
    Fs_Profile=num(1:NStory,1);
else
    Fs_Profile=zeros(NStory,1);
    Fs_Profile(:,1)=1;
end


if FrameType==2 || FrameType==3
    [~,~,Data] = xlsread(ExcelFileName,'Braces','B2:U50');
    BRACES=Data(1:NStory,1:NBay);
    
    [num,~,~] = xlsread(ExcelFileName,'CGP t_plate','B2:U50');
    CGP_tp=num(1:NStory,1:NBay);
    
    [num,~,~] = xlsread(ExcelFileName,'MGP t_plate','B2:U50');
    MGP_tp=num(1:NStory,1:NBay);
    
    [num,~,~] = xlsread(ExcelFileName,'CGP L123','B2:U50');
    CGP_L123=num(1:NStory,1:3);
    
    [num,~,~] = xlsread(ExcelFileName,'MGP L123','B2:U50');
    MGP_L123=num(1:NStory,1:3);
    
    [num,~,~] = xlsread(ExcelFileName,'MGP W_plate','B2:U50');
    MGP_W=num(1:NStory,1:NBay);
    
    [num,~,~] = xlsread(ExcelFileName,'MGP L_offset','B2:U50');
    MGP_RigidOffset=num(1:NStory,1:NBay);

    [num,~,~] = xlsread(ExcelFileName,'CGP L_offset','B2:U50');
    CGP_RigidOffset=num(1:NStory,1:NBay);
    
    [num,~,~] = xlsread(ExcelFileName,'L_brace','B2:U50');
    Brace_L=num(1:NStory,1:NBay);
    
    [num,~,~] = xlsread(ExcelFileName,'MGP L_connection','B2:U50');
    MGP_Lc=num(1:NStory,1:NBay);
    
    [num,~,~] = xlsread(ExcelFileName,'CGP L_connection','B2:U50');
    CGP_Lc=num(1:NStory,1:NBay);
else
    BRACES=NaN; CGP_tp=NaN; MGP_tp=NaN; CGP_L123=NaN; MGP_L123=NaN; MGP_W=NaN; MGP_RigidOffset=NaN; CGP_RigidOffset=NaN; Brace_L=NaN; MGP_Lc=NaN; CGP_Lc=NaN;
end

if FrameType==3
    [~,~,Data] = xlsread(ExcelFileName,'MF SL','B2:U50');
    MF_SL=Data(1:NStory,1:NBay);
else
    MF_SL=NaN;
end

if GFX == 1
    [~,~,Data] = xlsread(ExcelFileName,'GFS Connection','B2:B100');
    CONNECTIONS=Data(1:NStory,1);
else
    CONNECTIONS=NaN;
end

if MFconnection == 3
    [~,~,Data] = xlsread(ExcelFileName,'MF EEPC','B2:K100');
    MF_EEPCs=Data(1:NStory,1:NBay);
else
    MF_EEPCs=NaN;
end

cd(MainDirectory)

WBuilding = sum(WBay);
HBuilding = sum(HStory);

x=sum(~cellfun('isempty',strfind(MF_COLUMNS,'BU')),"all");
y=sum(~cellfun('isempty',strfind(MF_BEAMS,'BU')),"all");

SecData_BU.d=0;
count=1;
if x~=0 || y~=0
    for i=1:size(MF_COLUMNS,1)
        for j=1:size(MF_COLUMNS,2)
            Section=MF_COLUMNS{i,j};
            if ~contains(Section, 'BU')==0
                [SecData_BU]=get_BU_section_data(Section, SecData_BU, count);
                count=count+1;
            end
        end
    end
    for i=1:size(MF_BEAMS,1)
        for j=1:size(MF_BEAMS,2)
            Section=MF_BEAMS{i,j};
            if ~contains(Section, 'BU')==0
                [SecData_BU]=get_BU_section_data(Section, SecData_BU, count);
                count=count+1;
            end
        end
    end
else
    SecData_BU=0;
end

cd(MainDirectory)

for i=1:size(MF_COLUMNS,1)
    for j=1:size(MF_COLUMNS,2)
        Section=MF_COLUMNS{i,j};
        [SecDataC]=load_SecData (Section,Units);
        SecData_Columns{i,j}=SecDataC;
    end
end

for i=1:size(MF_BEAMS,1)
    for j=1:size(MF_BEAMS,2)
        Section=MF_BEAMS{i,j};
        [SecDataB]=load_SecData (Section,Units);
        SecData_Beams{i,j}=SecDataB;
    end
end

PROPERTY = v2struct (HStory, WBay, MF_COLUMNS, MF_BEAMS, GF_COLUMNS, GF_BEAMS, Doubler, Splice, Fs_Profile, SecData_BU, WBuilding, HBuilding, BRACES, CGP_tp, MGP_tp, CGP_L123, MGP_L123, MGP_W, MGP_RigidOffset, CGP_RigidOffset, Brace_L, MGP_Lc, CGP_Lc, MF_SL, CONNECTIONS, MF_EEPCs, SecData_Columns, SecData_Beams);

% Data-Unit sanity checks
if (Units==1 && max(HStory)<1000) || (Units==2 && min(HStory)>1000)
    warndlg('The story height values do not seem to be consistent with the defined project units. Please check!');
end


