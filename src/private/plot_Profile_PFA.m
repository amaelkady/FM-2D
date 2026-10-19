function plot_Profile_PFA(GMi, GMj)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'GM_Start','nRealizations','RFpath','Elevation','YTickLabel','FloorLink','Units');


[PFA_MF,PFA_EGF,selection]=read_Selected_Profile(RFpath,'PFA',GMi,GMj,GM_Start,nRealizations,FloorLink,1,true);

%% Plot
figure('position',[100 100 350 400],'color','white');
grid on; box on; hold on;
plot_Response_Profiles(PFA_MF,Elevation,selection.Partial,selection.Timeout);
set(gca,'XLim',[0 1.5*max(1e-6,max(max(PFA_MF)))]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'FontName','Times','FontSize',14);
ylabel ('Elevation');
if FloorLink==1; xlabel ('\itPFA\rm [g]'); else; xlabel ('\itPFA\rm_{MF} [g]'); end


if FloorLink~=1
    figure('position',[100 100 350 400],'color','white');
    grid on; box on; hold on;
    plot_Response_Profiles(PFA_EGF,Elevation,selection.Partial,selection.Timeout);
    set(gca,'XLim',[0 1.5*max(1e-6,max(max(PFA_EGF)))]);
    set(gca,'YLim',[0  max(Elevation)]);
    set(gca,'YTick',Elevation);
    set(gca,'YTickLabel',YTickLabel);
    set(gca,'FontName','Times','FontSize',14);
    ylabel ('Elevation');
    xlabel ('\itPFA\rm_{EGF} [g]');

end
