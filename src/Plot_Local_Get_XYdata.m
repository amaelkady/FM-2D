function [X, Y]=Plot_Local_Get_XYdata(Element, PlotType, Story, Floor, Axis, Bay, yRootName, xRootName, Sub_RootName, DataColIndx, RFpath, SubRFname, Brace_Data, HStory)
global MainDirectory

cd(RFpath);
cd('Results');
cd(SubRFname);

if strcmp(Element,'Column Spring')==1
    evalc(['F_Data=importdata(','''',yRootName,num2str(Floor),num2str(Axis),Sub_RootName,'_F.out','''',')']);
    evalc(['D_Data=importdata(','''',xRootName,num2str(Floor),num2str(Axis),Sub_RootName,'_D.out','''',')']);
    X=D_Data(:,3)*100;
    Y=F_Data(:,DataColIndx);
elseif strcmp(Element,'Beam Spring')==1
    evalc(['F_Data=importdata(','''',yRootName,num2str(Floor+1),num2str(Axis),Sub_RootName,'_F.out','''',')']);
    evalc(['D_Data=importdata(','''',xRootName,num2str(Floor+1),num2str(Axis),Sub_RootName,'_D.out','''',')']);
    X=D_Data(:,3)*100;
    Y=F_Data(:,DataColIndx);
elseif strcmp(Element,'Panel Zone Spring')==1
    evalc(['F_Data=importdata(','''',yRootName,num2str(Floor+1),num2str(Axis),Sub_RootName,'_F.out','''',')']);
    evalc(['D_Data=importdata(','''',xRootName,num2str(Floor+1),num2str(Axis),Sub_RootName,'_D.out','''',')']);
    X=D_Data(:,1)*100;
    Y=F_Data(:,DataColIndx);
elseif strcmp(Element,'Column Elastic Element')==1
    evalc(['F_Data=importdata(','''',yRootName,num2str(Story),num2str(Axis),Sub_RootName,'.out','''',')']);
    evalc(['D_Data=importdata(','''',xRootName,'.out','''',')']);
    X=D_Data(:,1)*100;
    Y=F_Data(:,DataColIndx);
elseif strcmp(Element,'Beam Elastic Element')==1
    evalc(['F_Data=importdata(','''',yRootName,num2str(Floor+1),num2str(Bay),Sub_RootName,'.out','''',')']);
    evalc(['D_Data=importdata(','''',xRootName,'.out','''',')']);
    X=D_Data(:,1)/HStory(1)*100;
    Y=F_Data(:,DataColIndx);
elseif strcmp(Element,'Floor Link')==1
    evalc(['F_Data=importdata(','''',yRootName,num2str(Floor+1),Sub_RootName,'_F.out','''',')']);
    if PlotType==1
        evalc(['D_Data=importdata(','''',xRootName,'1_MF.out','''',')']);
        X=D_Data(:,1)*100;
    else
        evalc(['D_Data=importdata(','''',xRootName,num2str(Floor+1),'_D.out','''',')']);
        X=D_Data(:,1);
    end
    Y=F_Data(:,DataColIndx);
elseif strcmp(Element,'Brace')==1
    evalc(['F_Data=importdata(','''',yRootName,num2str(Story),num2str(Bay),Sub_RootName,'_F.out','''',')']);
    if PlotType==1
        evalc(['D_Data=importdata(','''',xRootName,num2str(Story),'_MF.out','''',')']);
        X=D_Data(:,1)/HStory(Story)*100;
        Y=F_Data(:,DataColIndx);
    elseif PlotType==2
        evalc(['D_Data=importdata(','''',xRootName,'1_MF.out','''',')']);
        X=D_Data(:,1)/HStory(1)*100;
        Y=F_Data(:,DataColIndx);
    elseif PlotType==3
        evalc(['D_Data=importdata(','''',xRootName,num2str(Story),num2str(Bay),Sub_RootName,'_D.out','''',')']);
        X=D_Data(:,1);
        Y=F_Data(:,DataColIndx);
    elseif PlotType==4
        evalc(['D_Data=importdata(','''',xRootName,num2str(Story),num2str(Bay),Sub_RootName,'_D.out','''',')']);
        X=D_Data(:,1);
        Y=F_Data(:,DataColIndx)/Brace_Data.Py(Story,Bay);
    end
end

cd(MainDirectory)
