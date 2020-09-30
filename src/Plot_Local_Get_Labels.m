function [XLabel, YLabel]=Plot_Local_Get_Labels(Element, PlotType, Units)

if Units==1
    Dunit='[mm]';
    Funit='[kN]';
    Munit='[kN.mm]';
else
    Dunit='[in]';
    Funit='[kip]';
    Munit='[kip.in]';
end

if strcmp(Element,'Column Spring')==1 || strcmp(Element,'Beam Spring')==1
    XLabel='\theta [% rad]';
    YLabel=['Moment ',Munit];
elseif strcmp(Element,'Panel Zone Spring')==1
    XLabel='\gamma [% rad]';
    YLabel=['Moment ',Munit];
elseif strcmp(Element,'Column Elastic Element')==1
    XLabel='\itSDR\rm_1 [% rad]';
    if PlotType==1
        YLabel=['Axial Force ',Funit];
    elseif PlotType==2
        YLabel=['Shear Force ',Funit];
    elseif PlotType==3
        YLabel=['Moment ',Munit];
    end
elseif strcmp(Element,'Beam Elastic Element')==1
    XLabel='\itSDR\rm_1 [% rad]';
    if PlotType==1
        YLabel=['Axial Force ',Funit];
    elseif PlotType==2
        YLabel=['Shear Force ',Funit];
    elseif PlotType==3
        YLabel=['Moment ',Munit];
    end
elseif strcmp(Element,'Floor Link')==1
    if PlotType==1
        XLabel='\itSDR\rm_1 [% rad]';
    else
        XLabel=['\delta_{axial} ',Dunit];
    end
    YLabel=['Axial Force ',Funit];
elseif strcmp(Element,'Brace')==1
    if PlotType==1
        XLabel='\itSDR\rm_i [% rad]';
        YLabel=['Axial Force ',Funit];
    elseif PlotType==2
        XLabel='SDR_1 [% rad]';
        YLabel=['Axial Force ',Funit];
    elseif PlotType==3
        XLabel=['\delta_{axial} ',Dunit];
        YLabel=['Axial Force ',Funit];
    elseif PlotType==4
        XLabel=['\delta_{axial} ',Dunit];
        YLabel='Axial Force [1/P_y]';
    end
end