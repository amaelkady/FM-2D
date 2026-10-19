function plot_Profile_SDR(GMi, GMj)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'CollapseSDR','GM_Start','nRealizations','RFpath','Elevation','HalfElevation','YTickLabel','FloorLink');


[SDR_MF,SDR_EGF,selection]=read_Selected_Profile(RFpath,'SDR',GMi,GMj,GM_Start,nRealizations,FloorLink,100,true);

%% Plot
figure('position',[100 100 350 400],'color','white');
grid on; box on; hold on;
plot_Response_Profiles(SDR_MF,HalfElevation,selection.Partial,selection.Timeout);
set(gca,'XLim',[0 min(1.5*max(1e-6,max(max(SDR_MF))),CollapseSDR*100)]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'FontName','Times','FontSize',14);
ylabel ('Elevation');
if FloorLink==1; xlabel ('\itSDR\rm [% rad]'); else; xlabel ('\itSDR\rm_{MF} [% rad]'); end


if FloorLink~=1
    figure('position',[100 100 350 400],'color','white');
    grid on; box on; hold on;
    plot_Response_Profiles(SDR_EGF,HalfElevation,selection.Partial,selection.Timeout);
    set(gca,'XLim',[0 min(1.5*max(1e-6,max(max(SDR_EGF))),CollapseSDR*100)]);
    set(gca,'YLim',[0  max(Elevation)]);
    set(gca,'YTick',Elevation);
    set(gca,'YTickLabel',YTickLabel);
    set(gca,'FontName','Times','FontSize',14);
    ylabel ('Elevation');
    xlabel ('\itSDR\rm_{EGF} [% rad]');

end
