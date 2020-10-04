function write2file_ProjectSummary(RFpath)            
global MainDirectory

[SummaryText]=Get_Project_Summary;

cd(RFpath)
cd('Results')

fileID = fopen('Project Definitions.txt','w');
            
[rows,cols]=size(SummaryText);

for c=1:cols
    fprintf(fileID,'%s\n',string(SummaryText(1,c)));
end

fclose(fileID);
cd(MainDirectory)
