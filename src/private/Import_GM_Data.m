function [GMFolderPath, GMFolderName, GM, nGM]=Import_GM_Data(GMFolderPath)
global MainDirectory
clc

[~,GMFolderName] = fileparts(GMFolderPath);

cd (GMFolderPath)
% If the file "GM Data.txt" exits
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
[~ , ~ , ext ] = fileparts(files(3).name);

fileID = fopen('AllGMinfo.txt','r');    % Open the Text File with the GM info to read data
AllData= textscan (fileID, '%s %f');    % Read the No., Name, No. of Points, dt and PGA of all GMs
fclose (fileID);                        % Close the Text File with the GM info
GM.Name   = AllData {1,1};
GM.dt     = AllData {1,2};

for GM_No=1:nGM
    
    evalc(strcat(['GM.GM',num2str(GM_No),'name 	  = GM.Name{GM_No}']));
    evalc(strcat(['GM.GM',num2str(GM_No),'dt   	  = GM.dt  (GM_No)']));
    
    %% Deduce Floor Absolute Acceleration
    evalc(strcat(['A = importdata([GM.GM',num2str(GM_No),'name ','''',ext,'''','])']));
    L = length(A(:,1));
    CL = length(A(1,:));
    for i = 1:L
        GMArrangement((1+(i-1)*CL):(CL+(i-1)*CL),1) = A(i,:)';
    end
    evalc(strcat(['GM.GM',num2str(GM_No),'npoints = size(GMArrangement,1)']));
    evalc(strcat(['GM.GM',num2str(GM_No),'acc = GMArrangement']));
    evalc(strcat(['GM.pga(GM_No,1)=max(abs(GM.GM',num2str(GM_No),'acc))']));
    evalc(strcat(['GM.npoints(GM_No,1)=size(GM.GM',num2str(GM_No),'acc,1)']));
    evalc(strcat(['GM.duration(GM_No,1)=GM.dt(GM_No,1)*size(GM.GM',num2str(GM_No),'acc,1)']));
    
    clear GMArrangement
    
end

cd (MainDirectory)

fclose all;