function Import_ExcelData_CBF(ExcelFilePath,ExcelFileName, NStory, NBay,FloorLink)
global MainDirectory ProjectPath ProjectName

cd(ExcelFilePath)

[num,txt,Data] = xlsread(ExcelFileName,'H_story','B2:B50');
HStory=num(1:NStory,1);

[num,txt,Data] = xlsread(ExcelFileName,'W_bay','B2:U2');
num=num';
WBay=num(1:NBay,1);

[num,txt,Data] = xlsread(ExcelFileName,'MF Columns','B2:U50');
MF_COLUMNS=Data(1:NStory,1:NBay+1);

[num,txt,Data] = xlsread(ExcelFileName,'MF Beams','B2:U50');
MF_BEAMS=Data(1:NStory,1:NBay);

[num,txt,Data] = xlsread(ExcelFileName,'Braces','B2:U50');
BRACES=Data(1:NStory,1:NBay);

[num,txt,Data] = xlsread(ExcelFileName,'GFS Columns','B2:B50');
GF_COLUMNS=Data(1:NStory,1);

[num,txt,Data] = xlsread(ExcelFileName,'GFS Beams','B2:B50');
GF_BEAMS=Data(1:NStory,1);

[num,txt,Data] = xlsread(ExcelFileName,'Doubler Plates','B2:U50');
Doubler=num(1:NStory,1:NBay+1);

[num,txt,Data] = xlsread(ExcelFileName,'Column Splice','B2:C50');
Splice=num(1:NStory,1:2);

[num,txt,Data] = xlsread(ExcelFileName,'CGP t_plate','B2:U50');
CGP_tp=num(1:NStory,1:NBay);

[num,txt,Data] = xlsread(ExcelFileName,'MGP t_plate','B2:U50');
MGP_tp=num(1:NStory,1:NBay);

[num,txt,Data] = xlsread(ExcelFileName,'CGP L123','B2:U50');
CGP_L123=num(1:NStory,1:3);

[num,txt,Data] = xlsread(ExcelFileName,'MGP L123','B2:U50');
MGP_L123=num(1:NStory,1:3);

[num,txt,Data] = xlsread(ExcelFileName,'MGP W_plate','B2:U50');
MGP_W=num(1:NStory,1:NBay);

[num,txt,Data] = xlsread(ExcelFileName,'MGP L_offset','B2:U50');
MGP_RigidOffset=num(1:NStory,1:NBay);

[num,txt,Data] = xlsread(ExcelFileName,'CGP L_offset','B2:U50');
CGP_RigidOffset=num(1:NStory,1:NBay);

[num,txt,Data] = xlsread(ExcelFileName,'L_brace','B2:U50');
Brace_L=num(1:NStory,1:NBay);

[num,txt,Data] = xlsread(ExcelFileName,'MGP L_connection','B2:U50');
MGP_Lc=num(1:NStory,1:NBay);

[num,txt,Data] = xlsread(ExcelFileName,'CGP L_connection','B2:U50');
CGP_Lc=num(1:NStory,1:NBay);

if FloorLink==2
    [num,txt,Data] = xlsread(ExcelFileName,'Fs Profile','B2:B50');
    Fs_Profile=num(1:NStory,1);
else
    Fs_Profile=zeros(NStory,1);
    Fs_Profile(:,1)=1;
end

WBuilding = sum(WBay);
HBuilding = sum(HStory);

% Save imported data to project file
cd (ProjectPath)
save(ProjectName,'ExcelFileName','ExcelFilePath','HStory', 'WBay', 'MF_COLUMNS','MF_BEAMS','GF_COLUMNS','GF_BEAMS','Doubler','Splice','WBuilding','HBuilding','CGP_tp','MGP_tp','BRACES', 'CGP_L123', 'MGP_L123', 'MGP_W','MGP_RigidOffset','CGP_RigidOffset','MGP_Lc','CGP_Lc','Brace_L','Fs_Profile','-append')
cd (MainDirectory)