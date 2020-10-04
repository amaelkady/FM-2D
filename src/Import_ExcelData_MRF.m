function Import_ExcelData_MRF(ExcelFilePath,ExcelFileName, NStory, NBay,FloorLink)
global MainDirectory ProjectPath ProjectName

cd(ExcelFilePath)

[num,txt,Data] = xlsread(ExcelFileName,'H_story','B2:B100');
HStory=num(1:NStory,1);

[num,txt,Data] = xlsread(ExcelFileName,'W_bay','B2:B100');
WBay=num(1:NBay,1);

[num,txt,Data] = xlsread(ExcelFileName,'MF Columns','B2:K100');
MF_COLUMNS=Data(1:NStory,1:NBay+1);

[num,txt,Data] = xlsread(ExcelFileName,'MF Beams','B2:K100');
MF_BEAMS=Data(1:NStory,1:NBay);

[num,txt,Data] = xlsread(ExcelFileName,'GFS Columns','B2:B100');
GF_COLUMNS=Data(1:NStory,1);

[num,txt,Data] = xlsread(ExcelFileName,'GFS Beams','B2:B100');
GF_BEAMS=Data(1:NStory,1);

[num,txt,Data] = xlsread(ExcelFileName,'Doubler Plates','B2:K100');
Doubler=num(1:NStory,1:NBay+1);

[num,txt,Data] = xlsread(ExcelFileName,'Column Splice','B2:C100');
Splice=num(1:NStory,:);

if  FloorLink ==2
    [num,txt,Data] = xlsread(ExcelFileName,'Fs Profile','B2:B50');
    Fs_Profile=num(1:NStory,1);
else
    Fs_Profile=zeros(NStory,1);
    Fs_Profile(:,1)=1;
end

WBuilding = sum(WBay);
HBuilding = sum(HStory);

% save imported data to project file
cd (ProjectPath)
save(ProjectName,'ExcelFileName','ExcelFilePath','HStory', 'WBay', 'MF_COLUMNS','MF_BEAMS','GF_COLUMNS','GF_BEAMS','Doubler','Splice','WBuilding','HBuilding','Fs_Profile','-append')
cd (MainDirectory)