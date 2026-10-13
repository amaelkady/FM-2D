function plot_Profile_PFV(GMi, GMj)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'GM_Start','nRealizations','RFpath','Elevation','YTickLabel','FloorLink','Units');


if Units==1; unit='[mm/sec]'; end
if Units==2; unit='[in/sec]'; end

noGM = GMj-GMi+1;

[PFV_MF,PFV_EGF]=read_Selected_Profile(RFpath,'PFV',GMi,GMj,GM_Start,nRealizations,FloorLink,1);

%% Plot
figure('position',[100 100 350 400],'color','white');
grid on; box on; hold on;
plot ([0 0], [-0.1 -0.1],'-','LineWidth',1,'Color',[0.70 0.70 0.70]); 
for GM_No = 1:size(PFV_MF,1)
    if noGM>=3 || nRealizations>1
        plot (PFV_MF(GM_No,:), Elevation,'-','LineWidth',1,'Color',[0.7 0.7 0.7],'HandleVisibility','off');
    elseif noGM==1
        plot (PFV_MF(GM_No,:), Elevation,'-ok','LineWidth',1.5);
    elseif noGM==2
        plot (PFV_MF(GM_No,:), Elevation,'-*b','LineWidth',1.5);
    end
end
if noGM>=3 || nRealizations>1; plot (median(PFV_MF,1), Elevation,'-ok','LineWidth',2,'MarkerFaceColor','r'); end
set(gca,'XLim',[0 1.5*max(max(PFV_MF))]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'FontName','Times','FontSize',14);
ylabel ('Elevation');
if FloorLink==1; xlabel (['\itPFV\rm ',unit]); else; xlabel (['\itPFV\rm_{MF} ',unit]); end
if noGM>=3 || nRealizations>1; L=legend('individual record/Ri','median'); set(L,'FontSize',12,'Location','northoutside','Orientation','horizontal'); end  

if FloorLink~=1
    figure('position',[100 100 350 400],'color','white');
    grid on; box on; hold on;
	plot ([0 0], [-0.1 -0.1],'-','LineWidth',1,'Color',[0.70 0.70 0.70]); 
    for GM_No = 1:size(PFV_MF,1)
        if noGM>=3 || nRealizations>1
            plot (PFV_EGF(GM_No,:), Elevation,'-','LineWidth',1,'Color',[0.7 0.7 0.7],'HandleVisibility','off');
        elseif noGM==1
            plot (PFV_EGF(GM_No,:), Elevation,'-ok','LineWidth',1.5);
        elseif noGM==2
            plot (PFV_EGF(GM_No,:), Elevation,'-*b','LineWidth',1.5);
        end
    end
    if noGM>=3 || nRealizations>1; plot (median(PFV_EGF,1), Elevation,'-ok','LineWidth',2,'MarkerFaceColor','r'); end
    set(gca,'XLim',[0 1.5*max(max(PFV_EGF))]);
    set(gca,'YLim',[0  max(Elevation)]);
    set(gca,'YTick',Elevation);
    set(gca,'YTickLabel',YTickLabel);
    set(gca,'FontName','Times','FontSize',14);
    ylabel ('Elevation');
    xlabel (['\itPFV\rm_{EGF} ',unit]);
    if noGM>=3 || nRealizations>1; L=legend('individual record/Ri','median'); set(L,'FontSize',12,'Location','northoutside','Orientation','horizontal'); end  
end
