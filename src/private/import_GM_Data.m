function [GMFolderPath, GMFolderName, GM, nGM]=import_GM_Data(GMFolderPath)
global MainDirectory

[~,GMFolderName] = fileparts(GMFolderPath);

cd (GMFolderPath)

if exist ('AllGMinfo.txt')==0
    d=errordlg('The file "AllGMinfo.txt" is not found in the selected folder!','Error','modal');
    waitfor(d);
    return
end

GM_Data=importdata('AllGMinfo.txt'); % Read the file data

if isa(GM_Data,'double')==1
    if size(GM_Data,2) ~=2
        d=errordlg('The file "AllGMinfo.txt" must contain 2 columns of data {NAME   dT}!','Error','modal');
        waitfor(d);
        return
    end
    nGM=size(GM_Data,1);
else
    if size(GM_Data.textdata,2) ~=1 && size(GM_Data.data,2) ~=1
        d=errordlg('The file "AllGMinfo.txt" must contain 2 columns of data {NAME   dT}!','Error','modal');
        waitfor(d);
        return
    end
    nGM=size(GM_Data.data,1);
end

files=dir;
[~ , ~ , ext] = fileparts(files(3).name);

fileID = fopen('AllGMinfo.txt','r');    % Open the Text File with the GM info to read data
AllData= textscan (fileID, '%s %f');    % Read the No., Name, No. of Points, dt and PGA of all GMs
fclose (fileID);                        % Close the Text File with the GM info
GM.Name   = AllData {1,1};
GM.Dt     = AllData {1,2};

for GM_No=1:nGM
    
    GM.filename{:,GM_No}=strcat(GM.Name{GM_No},ext);

    %% Deduce Floor Absolute Acceleration
    A  = importdata(GM.filename{:,GM_No});
    acc = reshape(A.', [], 1);
    
    GM.name    {:,GM_No} = GM.Name{GM_No};
    GM.dt      {:,GM_No} = GM.Dt(GM_No);
    GM.npoints {:,GM_No} = size(acc,1);
    GM.acc     {:,GM_No} = acc;
    GM.pga     {:,GM_No} = max(abs(GM.acc{:,GM_No}));
    GM.duration{:,GM_No} = GM.dt{:,GM_No}*GM.npoints{:,GM_No};
    
end

GM = rmfield(GM, 'Name');
GM = rmfield(GM, 'Dt');
 
cd (MainDirectory)

fclose all;