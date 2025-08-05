function [X, Y]=get_local_XYdata(RESULTS, Element, PlotType, Story, Floor, Axis, Bay, yRootName, xRootName, Sub_RootName, DataColIndx, Brace_Data, HStory)
global NBay Units


if Units==1
    if DataColIndx==3 || DataColIndx==6; convfactor=1/1000; else; convfactor=1; end
else
    convfactor=1;
end

if strcmp(Element,'Column Spring')==1
    evalc(['F_Data=','''',yRootName,num2str(Floor),num2str(Axis),Sub_RootName,'_F','''']);
    evalc(['D_Data=','''',xRootName,num2str(Floor),num2str(Axis),Sub_RootName,'_D','''']);
    X=RESULTS.(D_Data)(:,3)*100;
    Y=RESULTS.(F_Data)(:,DataColIndx)*convfactor;
elseif strcmp(Element,'Beam Spring')==1
    evalc(['F_Data=','''',yRootName,num2str(Floor+1),num2str(Axis),Sub_RootName,'_F','''']);
    evalc(['D_Data=','''',xRootName,num2str(Floor+1),num2str(Axis),Sub_RootName,'_D','''']);
    X=RESULTS.(D_Data)(:,3)*100;
    Y=RESULTS.(F_Data)(:,DataColIndx)*convfactor;
elseif strcmp(Element,'EGF Connection')==1
    evalc(['F_Data=','''',yRootName,num2str(Floor+1),num2str(NBay+1+Axis),Sub_RootName,'_F','''']);
    evalc(['D_Data=','''',xRootName,num2str(Floor+1),num2str(NBay+1+Axis),Sub_RootName,'_D','''']);
    X=RESULTS.(D_Data)(:,3)*100;
    Y=RESULTS.(F_Data)(:,DataColIndx)*convfactor;
elseif strcmp(Element,'Panel Zone Spring')==1
    evalc(['F_Data=','''',yRootName,num2str(Floor+1),num2str(Axis),Sub_RootName,'_F','''']);
    evalc(['D_Data=','''',xRootName,num2str(Floor+1),num2str(Axis),Sub_RootName,'_D','''']);
    X=RESULTS.(D_Data)(:,1)*100;
    Y=RESULTS.(F_Data)(:,DataColIndx)*convfactor;
elseif strcmp(Element,'Column Elastic Element')==1
    evalc(['F_Data=','''',yRootName,num2str(Story),num2str(Axis),Sub_RootName,'','''']);
    evalc(['D_Data=','''',xRootName,'','''']);
    X=RESULTS.(D_Data)(:,1)*100;
    Y=RESULTS.(F_Data)(:,DataColIndx);
elseif strcmp(Element,'Beam Elastic Element')==1
    evalc(['F_Data=','''',yRootName,num2str(Floor+1),num2str(Bay),Sub_RootName,'','''']);
    evalc(['D_Data=','''',xRootName,'','''']);
    X=RESULTS.(D_Data)(:,1)*100;
    Y=RESULTS.(F_Data)(:,DataColIndx);
elseif strcmp(Element,'Floor Link')==1
    evalc(['F_Data=','''',yRootName,num2str(Floor+1),Sub_RootName,'_F','''']);
    if PlotType==1
        evalc(['D_Data=','''',xRootName,'1_MF','''']);
        X=RESULTS.(D_Data)(:,1)*100;
    else
        evalc(['D_Data=','''',xRootName,num2str(Floor+1),'_D','''']);
        X=RESULTS.(D_Data)(:,1);
    end
    Y=RESULTS.(F_Data)(:,DataColIndx);
elseif strcmp(Element,'Brace')==1
    evalc(['F_Data=','''',yRootName,num2str(Story),num2str(Bay),Sub_RootName,'_F','''']);
    if PlotType==1
        evalc(['D_Data=','''',xRootName,num2str(Story),'_MF','''']);
        X=RESULTS.(D_Data)(:,1)/HStory(Story)*100;
        Y=RESULTS.(F_Data)(:,DataColIndx);
    elseif PlotType==2
        evalc(['D_Data=','''',xRootName,'1_MF','''']);
        X=RESULTS.(D_Data)(:,1)/HStory(1)*100;
        Y=RESULTS.(F_Data)(:,DataColIndx);
    elseif PlotType==3
        evalc(['D_Data=','''',xRootName,num2str(Story),num2str(Bay),Sub_RootName,'_D','''']);
        X=RESULTS.(D_Data)(:,1);
        Y=RESULTS.(F_Data)(:,DataColIndx);
    elseif PlotType==4
        evalc(['D_Data=','''',xRootName,num2str(Story),num2str(Bay),Sub_RootName,'_D','''']);
        X=RESULTS.(D_Data)(:,1);
        Y=RESULTS.(F_Data)(:,DataColIndx)/Brace_Data.Py(Story,Bay);
    end
end
