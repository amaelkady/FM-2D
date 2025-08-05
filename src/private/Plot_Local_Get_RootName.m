function [yRootName, xRootName, Sub_RootName]=Plot_Local_Get_RootName(Element, PlotType, Floor, Axis, SpringLoc, Filename)
global FrameType NStory NBay

if strcmp(Element,'Column Spring')==1
    yRootName=Filename.ColSpring;
    xRootName=Filename.ColSpring;
    if SpringLoc==1; Sub_RootName='T';  else; Sub_RootName='B'; end
    if Floor==NStory+1; Sub_RootName='B';  end
elseif strcmp(Element,'Beam Spring')==1
    yRootName=Filename.BeamSpring;
    xRootName=Filename.BeamSpring;
    if SpringLoc==1; Sub_RootName='L'; else; Sub_RootName='R'; end
    if Axis==1; Sub_RootName='R'; elseif Axis==NBay+1; Sub_RootName='L'; end
elseif strcmp(Element,'Panel Zone Spring')==1
    yRootName=Filename.PZ;
    xRootName=Filename.PZ;
    Sub_RootName='';
elseif strcmp(Element,'Column Elastic Element')==1
    yRootName=Filename.Column;
    xRootName=[Filename.SDR,'1_MF'];
    Sub_RootName='';
elseif strcmp(Element,'Beam Elastic Element')==1
    yRootName=Filename.Beam;
    xRootName=[Filename.SDR,'1_MF'];
    if FrameType==1
        Sub_RootName='';
    elseif FrameType==2 && rem(Floor,2)~=0
        if SpringLoc==1; Sub_RootName='L';  else; Sub_RootName='R'; end
    end
elseif strcmp(Element,'Floor Link')==1
    yRootName=Filename.FloorLink;
    if PlotType==1; xRootName=Filename.SDR;
    else;           xRootName=Filename.FloorLink;
    end
    Sub_RootName='';
elseif strcmp(Element,'Brace')==1
    yRootName=Filename.Brace;
    if     PlotType==1; xRootName=Filename.SDR;
    elseif PlotType==2; xRootName=Filename.SDR;
    elseif PlotType==3; xRootName=Filename.Brace;
    elseif PlotType==4; xRootName=Filename.Brace;
    end
    if SpringLoc==1; Sub_RootName='L';  else; Sub_RootName='R'; end
elseif strcmp(Element,'EGF Connection')==1
    yRootName=Filename.EGFconnection;
    xRootName=Filename.EGFconnection;
    if Axis==1; Sub_RootName='R'; else; Sub_RootName='L'; end
end