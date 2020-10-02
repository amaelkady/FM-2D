function Plot_Profile_RDR(GMi, GMj)

global MainDirectory ProjectName ProjectPath
cd (ProjectPath)
load (ProjectName)
cd (MainDirectory)

noGM = GMj-GMi+1;

% Go inside the results folder and read the summary results
cd (RFpath);
cd ('Results');
RDR_MF=importdata('Summary Maximum RDR.txt')*100;
cd (MainDirectory);

%% Plot
figure('position',[100 100 350 400],'color','white');
grid on; box on; hold on;
plot ([0 0], [-0.1 -0.1],'-','LineWidth',1,'Color',[0.70 0.70 0.70]); 
for GM_No = (GMi-GM_Start)*nRealizations+1:noGM*nRealizations
    if noGM>=3 || nRealizations>1
        plot (RDR_MF(GM_No,:), HalfElevation,'-','LineWidth',1,'Color',[0.70 0.70 0.70],'HandleVisibility','off');
    elseif noGM==1
        plot (RDR_MF(GM_No,:), HalfElevation,'-ok','LineWidth',1.5);
    elseif noGM==2
        plot (RDR_MF(GM_No,:), HalfElevation,'-*b','LineWidth',1.5);
    end
end
if noGM>=3 || nRealizations>1; plot (median(RDR_MF), HalfElevation,'-ok','LineWidth',2,'MarkerFaceColor','r'); end
set(gca,'XLim',[0 1.5*max(max(RDR_MF))]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'FontName','Times','FontSize',14);
ylabel ('Elevation');
if FloorLink==1; xlabel ('\itRDR\rm [% rad]'); else; xlabel ('\itRDR\rm_{MF} [% rad]'); end
if noGM>=3 || nRealizations>1; L=legend('individual record/Ri','median'); set(L,'FontSize',12,'Location','northoutside','Orientation','horizontal'); end  

if FloorLink~=1
    figure('position',[100 100 350 400],'color','white');
    grid on; box on; hold on;
	plot ([0 0], [-0.1 -0.1],'-','LineWidth',1,'Color',[0.70 0.70 0.70]); 
    for GM_No = (GMi-GM_Start)*nRealizations+1:noGM*nRealizations
        if noGM>=3 || nRealizations>1
            plot (RDR_EGF(GM_No,:), HalfElevation,'-','LineWidth',1,'Color',[0.70 0.70 0.70],'HandleVisibility','off');
        elseif noGM==1
            plot (RDR_EGF(GM_No,:), HalfElevation,'-ok','LineWidth',1.5);
        elseif noGM==2
            plot (RDR_EGF(GM_No,:), HalfElevation,'-*b','LineWidth',1.5);
        end
    end
    if noGM>=3 || nRealizations>1; plot (median(RDR_EGF), HalfElevation,'-ok','LineWidth',2,'MarkerFaceColor','r'); end
    set(gca,'XLim',[0 1.5*max(max(RDR_EGF))]);
    set(gca,'YLim',[0  max(Elevation)]);
    set(gca,'YTick',Elevation);
    set(gca,'YTickLabel',YTickLabel);
    set(gca,'FontName','Times','FontSize',14);
    ylabel ('Elevation');
    xlabel ('\itRDR\rm_{EGF} [% rad]');
    if noGM>=3 || nRealizations>1; L=legend('individual record/Ri','median'); set(L,'FontSize',12,'Location','northoutside','Orientation','horizontal'); end  
end
