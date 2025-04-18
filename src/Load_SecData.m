function [SecData]=Load_SecData (Section, Units)
global ProjectPath  ProjectName

if isempty(strfind(Section, 'BU'))==0

    load(strcat(ProjectPath,ProjectName),'SecData_BU')
    
    SecData = SecData_BU;

else

    if isempty(strfind(Section, 'W'))==0
    	load ('AISC_WF_Sec_Database.mat');
    elseif isempty(strfind(Section, 'HSS'))==0
    	load ('HSS_Sec_Database.mat');
    elseif isempty(strfind(Section, 'IP'))==0 || isempty(strfind(Section, 'HE'))==0 || isempty(strfind(Section, 'HD'))==0 || isempty(strfind(Section, 'UB'))==0 || isempty(strfind(Section, 'UC'))==0
    	load ('EURO_I_Sec_Database.mat');
    end

    if Units==1
        SecData.d    = SecData.d*25.4^1;
        SecData.tw   = SecData.tw*25.4^1;
        SecData.bf   = SecData.bf*25.4^1;
        SecData.tf   = SecData.tf*25.4^1;
        SecData.rx   = SecData.rx*25.4^1;
        SecData.ry   = SecData.ry*25.4^1;
        SecData.Area = SecData.Area*25.4^2;
        SecData.Sx   = SecData.Sx*25.4^3;
        SecData.Sy   = SecData.Sy*25.4^3;
        SecData.Zx   = SecData.Zx*25.4^3;
        SecData.Zy   = SecData.Zy*25.4^3;
        SecData.Ix   = SecData.Ix*25.4^4;
        SecData.Iy   = SecData.Iy*25.4^4;
        
        if isempty(strfind(Section, 'HSS'))~=0
            SecData.r    = SecData.r*25.4^1;
            SecData.J    = SecData.J*25.4^4;
            SecData.Cw   = SecData.Cw*25.4^6;
        end

        SecData.W    = SecData.Area*(1*1000)*7850/1000^3; % weight in kg/m
        %SecData.Iw=SecData.Iw*25.4^6;
        %SecData.It=SecData.It*25.4^4;

        if isempty(strfind(Section, 'HSS'))==0
            SecData.h=SecData.h*25.4^1;
            SecData.t=SecData.t*25.4^1;
        end
    else
        SecData.W=SecData.Area*(1*12)*490/12^3; % weight in lb/ft
    end

    % SecData.bf_tf = SecData.bf./(2*SecData.tf);
    % SecData.h_tw  = (SecData.h-2*SecData.tf-2*SecData.r)./SecData.tw;

end
