function [Pred]=Get_Col_Axial_Force(PM_Option)
global MainDirectory ProjectName ProjectPath
cd(ProjectPath)
load (ProjectName,'Filename','RFpath','NStory','NBay','TypicalDL','TypicalLL','TypicalGL','RoofDL','RoofLL','RoofGL','Cladding','HStory','TAex1','TAin1','TribAreaIn','TribAreaEx','cDL_W','cLL_W','cCL_W','cGL_W','Pscale')
cd(MainDirectory)

% For PM_Option=1
%   the columns Mp capacity will be reduced baced on an axial load
%   Pred equal to the gravity load plus half of the net overturning axial
%   load based on pushover analysis

% For PM_Option=2
%   the columns Mp capacity will be reduced baced on an axial load
%   Pred equal to the gravity load multiplied by an amplification
%   coefficient defined by the user

if PM_Option==1
    % Go Inside the TempFolder and Read Column Elements Force Data
    cd(RFpath)
    cd('Results')
    cd('TempPushover')
    for Story=1:NStory
        for Axis=1:NBay+1
            evalc(['xFile=','''',Filename.Column,num2str(Story),num2str(Axis),'''']);
            evalc([xFile,'=importdata(','''',xFile,'.out','''',')']);
            evalc(['Col_P',num2str(Story),num2str(Axis),'=',xFile,'(:,5)']);
            evalc(['Pg(Story,Axis)=abs(Col_P',num2str(Story),num2str(Axis),'(11,1))']); % gravity load measured at step 11 (last step of the gravity analysis)
            evalc(['Ppo_max(Story,Axis)=max(abs(Col_P',num2str(Story),num2str(Axis),'(11:end,1))']); % maximum axial load in pushover
            evalc(['Pot(Story,Axis)=Ppo_max(Story,Axis)-Col_P',num2str(Story),num2str(Axis),'(11,1)))']); % axial load due to overturning
            Pred(Story,Axis)=Pg(Story,Axis)+Pot(Story,Axis)*0.5;
        end
    end
    cd(ProjectPath)
    save (ProjectName,'Pg','Ppo_max','Pot','Pred','-append');
    cd(MainDirectory)
else
    % Get columns gravity load
    Pfloor=zeros(NStory,NBay+1);
    for Axis=1:NBay+1
        Bay=max(1,Axis-1);
        for Floor=NStory+1:-1:2
            Story=Floor-1;
            if Floor~=NStory+1
                if Axis>1  && Axis < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Story)+0.5*HStory(Story+1)) * (TAin1); end
                if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Story)+0.5*HStory(Story+1)) * (TAex1); end
            elseif Floor==NStory+1
                if Axis>1  && Axis < NBay+1; Load  = (cDL_W * RoofDL	+ cLL_W * RoofLL    + cGL_W * RoofGL)    * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Story)) * (TAin1); end
                if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * RoofDL    + cLL_W * RoofLL    + cGL_W * RoofGL)    * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Story)) * (TAex1); end
            end
            Pfloor(Story,Axis)=Load;
            
            Pg(Story,Axis)=sum(Pfloor(Story+1:end,Axis))+Load;
        end
    end
    
    Pred=Pg*Pscale;
    
    cd(ProjectPath)
    save (ProjectName,'Pg','Pred','-append');
    cd(MainDirectory)
end







