function [T]=get_T1()

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName),'RFpath')

cd(strcat(RFpath,'\Results\EigenAnalysis'));
fileID = fopen('EigenPeriod.out','r');
A = fscanf(fileID,'%f');
fclose(fileID);

for i=1:size(A,1)
    evalc(['T.T', num2str(i),'= A(',num2str(i),',1)']);
end

cd(MainDirectory)