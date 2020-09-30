function Plot_EDP_vs_Realization(GMi, GMj, EDPtype)

global MainDirectory ProjectName ProjectPath
cd (ProjectPath)
load (ProjectName,'nRealizations','RFpath')
cd (MainDirectory)

nGM=GMj-GMi+1;

cd(RFpath);
cd('Results');
if strcmp(EDPtype,'SDR')==1; [EDPmax_profile]=importdata('Summary Maximum SDR.txt'); ylabelstr='\itSDR\rm_{max} [% rad]';  unit='% rad'; factor=100; end
if strcmp(EDPtype,'RDR')==1; [EDPmax_profile]=importdata('Summary Maximum RDR.txt'); ylabelstr='\itRDR\rm_{max} [% rad]';  unit='% rad'; factor=100; end
if strcmp(EDPtype,'PFA')==1; [EDPmax_profile]=importdata('Summary Maximum PFA.txt'); ylabelstr='\itPFA\rm_{max} [g]';      unit='g';     factor=1;  end
EDP_vector_all=max(EDPmax_profile,[],2)*factor;
cd (MainDirectory)

figure('position',[100 100 450 250],'color','white');
grid on; hold on; box on;
set(gca, 'fontname', 'Times', 'fontsize',15);
plot (1:nRealizations*nGM,EDP_vector_all, 'ok','MarkerEdgeColor','r','MarkerFaceColor',[1 0 0],'MarkerSize',3,'HandleVisibility','off');
xlabel ('Realization');
ylabel (ylabelstr);
set(gca,'Ylim',[0 1.2*max(EDP_vector_all)]);
set(gca,'Xlim',[0.5 nRealizations*nGM+0.5]);
drawnow;

MeanEDP    = mean(EDP_vector_all); 
SigmalnEDP = std(log(EDP_vector_all)); 
plot([0.5 nRealizations*nGM+0.5],[MeanEDP MeanEDP],'--b','linewidth',1)
TitleX=sprintf('%s %5.3f %s %s %5.3f', '\it\mu\rm=', MeanEDP,unit, 'and \it \sigma\rm =', SigmalnEDP);
legend1=legend (TitleX);
set(legend1, 'fontsize',12,'location','southeast');

% MeanlnEDP  = mean(log(EDP_vector_all)); 
% figure('position',[100 100 250 250],'color','white');
% grid on; hold on; box on;
% set(gca, 'fontname', 'Times', 'fontsize',15)
% x=0:1.5*max(EDP_vector_all)/50:1.5*max(EDP_vector_all);
% y=lognpdf(x,MeanlnEDP,SigmalnEDP);
% plot(y,x);
% plot([0 max(y)*1.5],[MeanEDP MeanEDP],'--b','linewidth',1)
% xlabel ('PDF');
% ylabel (ylabelstr);