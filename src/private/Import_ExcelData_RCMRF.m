function Import_ExcelData_RCMRF(ExcelFilePath,ExcelFileName, NStory, NBay,FloorLink)
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

Splice=zeros(NStory,NBay+1);

if  FloorLink ==2
    [num,txt,Data] = xlsread(ExcelFileName,'Fs Profile','B2:B50');
    Fs_Profile=num(1:NStory,1);
else
    Fs_Profile=zeros(NStory,1);
    Fs_Profile(:,1)=1;
end

WBuilding = sum(WBay);
HBuilding = sum(HStory);

% Data-Unit sanity checks
if (Units==1 && max(HStory)<1000) || (Units==2 && min(HStory)>1000)
    warndlg('The story height values do not seem to be consistent with the defined project units. Please check!');
end

% save imported data to project file
save(strcat(ProjectPath,ProjectName),'ExcelFileName','ExcelFilePath','HStory', 'WBay', 'MF_COLUMNS','MF_BEAMS','GF_COLUMNS','GF_BEAMS','WBuilding','HBuilding','Fs_Profile','Splice','-append')
cd (MainDirectory)