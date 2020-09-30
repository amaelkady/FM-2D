function [DataColIndx]=Plot_Local_Get_DataColIndx(Element, PlotType, SpringLoc)

if strcmp(Element,'Column Spring')==1 || strcmp(Element,'Beam Spring')==1
    DataColIndx=3;
elseif strcmp(Element,'Panel Zone Spring')==1
    DataColIndx=3;
elseif strcmp(Element,'Column Elastic Element')==1
    if PlotType==1
        if SpringLoc==1; DataColIndx=2; else; DataColIndx=5; end
    elseif PlotType==2
        if SpringLoc==1; DataColIndx=1; else; DataColIndx=4; end
    elseif PlotType==3
        if SpringLoc==1; DataColIndx=3; else; DataColIndx=6; end
    end
elseif strcmp(Element,'Beam Elastic Element')==1
    if PlotType==1
        if SpringLoc==1; DataColIndx=1; else; DataColIndx=4; end
    elseif PlotType==2
        if SpringLoc==1; DataColIndx=2; else; DataColIndx=5; end
    elseif PlotType==3
        if SpringLoc==1; DataColIndx=3; else; DataColIndx=6; end
    end
elseif strcmp(Element,'Floor Link')==1
    DataColIndx=1;
elseif strcmp(Element,'Brace')==1
    DataColIndx=1;
end