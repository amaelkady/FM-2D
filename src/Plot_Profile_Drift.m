function Plot_Profile_Drift()
global MainDirectory ProjectName ProjectPath
cd (ProjectPath)
load (ProjectName)
cd (MainDirectory)

if PO==1;   SubRFname='Pushover';   end
if ELF==1;  SubRFname='ELF';        end

% Go inside the results folder and read results
cd (RFpath)
cd ('Results')
cd (SubRFname)


%% Read Floor Displacement Data
if Recorders.Disp==1
    for Floor=2:NStory+1
        evalc(['x=importdata(','''',Filename.Disp,num2str(Floor),'_MF.out','''',')']);
        Disp_MF(:,Floor)=x(:,1);
    end
end
RoofDisp=Disp_MF(:,end);

%% Plot
figure('position',[100 100 350 350],'color','white');
grid on; box on; hold on;
if PO==1; DriftIncr=min(max(RoofDisp),DriftPO*HBuilding/6); else; DriftIncr=abs(RoofDisp(end,1)); end
DriftIncrX=DriftIncr;
for i=1:size(RoofDisp,1)
    if abs(RoofDisp(i,1)) >= DriftIncrX
        plot (Disp_MF(i,:)*100/HBuilding, Elevation,'--ok','LineWidth',1,'MarkerFaceColor','r');
        DriftIncrX=DriftIncrX+DriftIncr;
    end
end
set(gca,'FontName','Times','FontSize',14);
xlabel ('\it\delta\rm_{floor}/\itH\rm_{building} [%]');
ylabel ('Floor level');
set(gca,'XLim',[0 1.2*max(max(abs(Disp_MF*100/HBuilding)))]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);

cd (MainDirectory)
