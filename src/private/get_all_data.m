function [RESULTS_DATA] = get_all_data (MainDirectory, RFpath, SubRFname)

cd (strcat(RFpath,'\Results\',SubRFname));

folder = pwd;
fileList = dir(fullfile(folder, '*.out'));
fileList = {fileList.name};
fileList_noext = strrep(fileList, '.out', '');


% Initialize an empty structure
RESULTS_DATA = struct();

parfor i = 1:length(fileList)
    % Get the full file path
    filename = char(fileList(i));
    
    % Read the file contents
    fileContents = importdata(filename);
    
    % Store data in a cell varaible
    fileData{i} = fileContents;

end

for i = 1:length(fileList)
    
    % Store data in structure using file name (without extension) as field name
    RESULTS_DATA.(char(fileList_noext(i))) = fileData{i};

end

RESULTS_DATA.SubRFname=SubRFname;

% 
% RootName = 'Time';
% idx = find (contains(fileList,RootName));
% for i = 1:length(idx)
%     % Get the full file path
%     filename = char(fileList(idx(i)));
% 
%     % Read the file contents
%     fileContents = importdata(filename);
% 
%     % Store data in structure using file name (without extension) as field name
% 
%     RESULTS_DATA.(char(fileList_noext(idx(i)))) = fileContents; % Store as cell array of lines
% end
% 
% 
% % Loop through each file
% RootName = 'ColSpring';
% idx = find (contains(fileList,RootName));
% for i = 1:length(idx)
%     % Get the full file path
%     filename = char(fileList(idx(i)));
% 
%     % Read the file contents
%     fileContents = importdata(filename);
% 
%     % Store data in structure using file name (without extension) as field name
% 
%     RESULTS_DATA.(char(fileList_noext(idx(i)))) = fileContents; % Store as cell array of lines
% end
% 
% % Loop through each file
% RootName = 'BeamSpring';
% idx = find (contains(fileList,RootName));
% for i = 1:length(idx)
%     % Get the full file path
%     filename = char(fileList(idx(i)));
% 
%     % Read the file contents
%     fileContents = importdata(filename);
% 
%     % Store data in structure using file name (without extension) as field name
% 
%     RESULTS_DATA.(char(fileList_noext(idx(i)))) = fileContents; % Store as cell array of lines
% end
% 
% 
% % Loop through each file
% RootName = 'PZ';
% idx = find (contains(fileList,RootName));
% for i = 1:length(idx)
%     % Get the full file path
%     filename = char(fileList(idx(i)));
% 
%     % Read the file contents
%     fileContents = importdata(filename);
% 
%     % Store data in structure using file name (without extension) as field name
% 
%     RESULTS_DATA.(char(fileList_noext(idx(i)))) = fileContents; % Store as cell array of lines
% end

cd (MainDirectory);
