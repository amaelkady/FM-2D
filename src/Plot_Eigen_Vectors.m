function Plot_Eigen_Vectors()

global MainDirectory ProjectName ProjectPath
clc
cd (ProjectPath)
load (ProjectName,'Ws','RFpath','NStory','HStory','Elevation','YTickLabel')
cd (MainDirectory)


%% Go inside the results folder and read results
cd (RFpath)
cd ('Results')
cd ('EigenAnalysis')

%% Read Eigen Vector Data
for Story=1:NStory
    evalc(strcat('x=importdata(','''','EigenVectorsMode',num2str(Story),'.out','''',')'));
    Eigen_Vectors(Story,:)=[0 x(1,:)];
end

x=importdata('EigenPeriod.out');
Eigen_Period=x';

cd (MainDirectory)

%% Plot
figure('position',[100 100 550 400],'color','white');
grid on; box on; hold on;
for Story=1:min(5,NStory)
    if Story==1; plot (Eigen_Vectors(Story,:), Elevation,'-k','linewidth',2);  end
    if Story==2; plot (Eigen_Vectors(Story,:), Elevation,'--b','linewidth',1.5); end
    if Story==3; plot (Eigen_Vectors(Story,:), Elevation,':r','linewidth',1.5);  end
    if Story==4; plot (Eigen_Vectors(Story,:), Elevation,'-.g','linewidth',1); end
    if Story>4;  plot (Eigen_Vectors(Story,:), Elevation,'linewidth',0.5,'Color',[0.65 0.65 0.65]); end
    legendlabel{Story}=['Mode #',num2str(Story),'=',num2str(Eigen_Period(Story)),'sec'];
end
set(gca,'XLim',[-1.5*max(max(abs(Eigen_Vectors))) 1.5*max(max(abs(Eigen_Vectors)))]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
xlabel ('Lateral DoF');
ylabel ('Elevation');
set(gca,'FontName','Times','FontSize',14);
plot ([0 0],[0 max(Elevation)], '-k','linewidth',0.5);
h=legend(legendlabel);
set(h,'FontName','Times','FontSize',12,'Location','East Outside')