function [Pr, Vr, Mr]=get_Column_Forces()

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName),'Filename','RFpath','NStory','NBay')

% Go Inside the TempFolder and Read Column Elements Force Data
cd(strcat(RFpath,'\Results\ELF'));

% Get beam moment
Pr=zeros(NStory,NBay+1);
Vr.Bottom=zeros(NStory,NBay+1);
Vr.Top   =zeros(NStory,NBay+1);
Mr.Bottom=zeros(NStory,NBay+1);
Mr.Top   =zeros(NStory,NBay+1);
for Floor=2:NStory+1
    for Axis=1:NBay+1
        evalc(['xFile=','''',Filename.Column,num2str(Floor-1),num2str(Axis),'''']);
        evalc([xFile,'=importdata(','''',xFile,'.out','''',')']);

        evalc(['Column_P=',xFile,'(end,2)']);
        evalc(['Pr(Floor-1,Axis)=max(abs(Column_P))']);


        evalc(['Column_V=',xFile,'(end,1)']);
        evalc(['Vr.Bottom(Floor-1,Axis)=max(abs(Column_V))']);
        evalc(['Column_V=',xFile,'(end,4)']);
        evalc(['Vr.Top(Floor-1,Axis)=max(abs(Column_V))']);

        evalc(['Column_M=',xFile,'(end,3)']);
        evalc(['Mr.Bottom(Floor-1,Axis)=max(abs(Column_M))']);
        evalc(['Column_M=',xFile,'(end,6)']);
        evalc(['Mr.Top(Floor-1,Axis)=max(abs(Column_M))']);
    end
end

cd(MainDirectory)
