function plot_Profile_PFA(GMi, GMj)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'GM_Start','nRealizations','RFpath','Elevation','YTickLabel','FloorLink','Units');


noGM = GMj-GMi+1;

[PFA_MF,PFA_EGF]=read_Selected_Profile(RFpath,'PFA',GMi,GMj,GM_Start,nRealizations,FloorLink,1);

%% Plot
figure('position',[100 100 350 400],'color','white');
grid on; box on; hold on;
plot ([0 0], [-0.1 -0.1],'-','LineWidth',1,'Color',[0.70 0.70 0.70]);
for GM_No = 1:size(PFA_MF,1)
    if noGM>=3 || nRealizations>1
        plot (PFA_MF(GM_No,:), Elevation,'-','LineWidth',1,'Color',[0.70 0.70 0.70],'HandleVisibility','off');
    elseif noGM==1
        plot (PFA_MF(GM_No,:), Elevation,'-ok','LineWidth',1.5);
    elseif noGM==2
        plot (PFA_MF(GM_No,:), Elevation,'-*b','LineWidth',1.5);
    end
end
if noGM>=3 || nRealizations>1; plot (median(PFA_MF,1), Elevation,'-ok','LineWidth',2,'MarkerFaceColor','r'); end
set(gca,'XLim',[0 1.5*max(max(PFA_MF))]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'FontName','Times','FontSize',14);
ylabel ('Elevation');
if FloorLink==1; xlabel ('\itPFA\rm [g]'); else; xlabel ('\itPFA\rm_{MF} [g]'); end
if noGM>=3 || nRealizations>1; L=legend('individual record/Ri','median'); set(L,'FontSize',12,'Location','northoutside','Orientation','horizontal'); end

if FloorLink~=1
    figure('position',[100 100 350 400],'color','white');
    grid on; box on; hold on;
    plot ([0 0], [-0.1 -0.1],'-','LineWidth',1,'Color',[0.70 0.70 0.70]);
    for GM_No = 1:size(PFA_MF,1)
        if noGM>=3 || nRealizations>1
            plot (PFA_EGF(GM_No,:), Elevation,'-','LineWidth',1,'Color',[0.70 0.70 0.70],'HandleVisibility','off');
        elseif noGM==1
            plot (PFA_EGF(GM_No,:), Elevation,'-ok','LineWidth',1.5);
        elseif noGM==2
            plot (PFA_EGF(GM_No,:), Elevation,'-*b','LineWidth',1.5);
        end
    end
    if noGM>=3 || nRealizations>1; plot (median(PFA_EGF,1), Elevation,'-ok','LineWidth',2,'MarkerFaceColor','r'); end
    set(gca,'XLim',[0 1.5*max(max(PFA_EGF))]);
    set(gca,'YLim',[0  max(Elevation)]);
    set(gca,'YTick',Elevation);
    set(gca,'YTickLabel',YTickLabel);
    set(gca,'FontName','Times','FontSize',14);
    ylabel ('Elevation');
    xlabel ('\itPFA\rm_{EGF} [g]');
    if noGM>=3 || nRealizations>1; L=legend('individual record/Ri','median'); set(L,'FontSize',12,'Location','northoutside','Orientation','horizontal'); end
end
