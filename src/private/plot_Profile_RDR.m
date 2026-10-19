function plot_Profile_RDR(GMi, GMj)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'CollapseSDR','GM_Start','nRealizations','RFpath','Elevation','HalfElevation','YTickLabel','FloorLink');


[RDR_MF,RDR_EGF,selection]=read_Selected_Profile(RFpath,'RDR',GMi,GMj,GM_Start,nRealizations,FloorLink,100,true);

%% Plot
figure('position',[100 100 350 400],'color','white');
grid on; box on; hold on;
plot_Response_Profiles(RDR_MF,HalfElevation,selection.Partial,selection.Timeout);
if any(selection.Partial), text(.02,.02,'Incomplete: last recorded drift','Units','normalized','FontSize',8); end
set(gca,'XLim',[0 min(1.5*max(1e-6,max(max(RDR_MF))),CollapseSDR*100)]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'FontName','Times','FontSize',14);
ylabel ('Elevation');
if FloorLink==1; xlabel ('\itRDR\rm [% rad]'); else; xlabel ('\itRDR\rm_{MF} [% rad]'); end


if FloorLink~=1
    figure('position',[100 100 350 400],'color','white');
    grid on; box on; hold on;
    plot_Response_Profiles(RDR_EGF,HalfElevation,selection.Partial,selection.Timeout);
    if any(selection.Partial), text(.02,.02,'Incomplete: last recorded drift','Units','normalized','FontSize',8); end
    set(gca,'XLim',[0 min(1.5*max(1e-6,max(max(RDR_EGF))),CollapseSDR*100)]);
    set(gca,'YLim',[0  max(Elevation)]);
    set(gca,'YTick',Elevation);
    set(gca,'YTickLabel',YTickLabel);
    set(gca,'FontName','Times','FontSize',14);
    ylabel ('Elevation');
    xlabel ('\itRDR\rm_{EGF} [% rad]');

end
