function [fig1, ax] = plot_SDR_check()

global ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName),'HBuilding','HStory','Elevation','HalfElevation','YTickLabel','SDR_MF', 'Cd', 'Ie', 'SDR_limit')

%% Plot
fig1=figure('position',[100 100 250 350],'color','white', 'Name','SDR Check','NumberTitle','off');
ax = axes('parent',fig1);
grid on; box on; hold on;
X=abs(SDR_MF(:,1)*100);
Y=HalfElevation;
plot (X, Y,'-ok','LineWidth',1.5);
set(gca,'XLim',[0 1.1*max(max(X*Cd), SDR_limit*100)]);
%set(gca,'YLim',[0  max(Elevation)]);
ylim([0.0-0.2*HStory(1) HBuilding+0.5*HStory(1)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
xlabel ('\itSDR\rm [% rad]');
set(gca,'FontName','Times','FontSize',10);

if Cd~=1
    plot (X*Cd/Ie, Y,'-ob','LineWidth',1.5);
    xline (SDR_limit*100,'--r','LineWidth',1.5);
    legend('elastic','nonlinear (*\itC\rm_d/\itI\rm_e)','SDR limit','fontsize',10)
end

title('SDR Profile Check', 'Color', 'b');

