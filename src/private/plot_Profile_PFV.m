function plot_Profile_PFV(GMi, GMj)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'GM_Start','nRealizations','RFpath','Elevation','YTickLabel','FloorLink','Units');


if Units==1; unit='[mm/sec]'; end
if Units==2; unit='[in/sec]'; end

[PFV_MF,PFV_EGF,selection]=read_Selected_Profile(RFpath,'PFV',GMi,GMj,GM_Start,nRealizations,FloorLink,1,true);

%% Plot
figure('position',[100 100 350 400],'color','white');
grid on; box on; hold on;
plot_Response_Profiles(PFV_MF,Elevation,selection.Partial,selection.Timeout);
set(gca,'XLim',[0 1.5*max(1e-6,max(max(PFV_MF)))]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'FontName','Times','FontSize',14);
ylabel ('Elevation');
if FloorLink==1; xlabel (['\itPFV\rm ',unit]); else; xlabel (['\itPFV\rm_{MF} ',unit]); end


if FloorLink~=1
    figure('position',[100 100 350 400],'color','white');
    grid on; box on; hold on;
    plot_Response_Profiles(PFV_EGF,Elevation,selection.Partial,selection.Timeout);
    set(gca,'XLim',[0 1.5*max(1e-6,max(max(PFV_EGF)))]);
    set(gca,'YLim',[0  max(Elevation)]);
    set(gca,'YTick',Elevation);
    set(gca,'YTickLabel',YTickLabel);
    set(gca,'FontName','Times','FontSize',14);
    ylabel ('Elevation');
    xlabel (['\itPFV\rm_{EGF} ',unit]);

end
