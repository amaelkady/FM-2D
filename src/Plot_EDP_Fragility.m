function Plot_EDP_Fragility(GMi, GMj, EDPtype)

global MainDirectory ProjectName ProjectPath
cd (ProjectPath);
load (ProjectName,'CollapseSDR','nRealizations','GM_Start','RFpath');
cd (MainDirectory);

if strcmp(EDPtype,'SDR')==1; filename='Summary Maximum SDR.txt'; xlabelstr='\itSDR\rm_{max} [% rad]'; ylabelstr='P(\itsdr\rm \leq \itSDR\rm_{max})'; unit='% rad'; factor=100; end
if strcmp(EDPtype,'RDR')==1; filename='Summary Maximum RDR.txt'; xlabelstr='\itRDR\rm_{max} [% rad]'; ylabelstr='P(\itrdr\rm \leq \itRDR\rm_{max})'; unit='% rad'; factor=100; end
if strcmp(EDPtype,'PFA')==1; filename='Summary Maximum PFA.txt'; xlabelstr='\itPFA\rm_{max} [g]';     ylabelstr='P(\itpfa\rm \leq \itPFA\rm_{max})'; unit='g';      factor=1;  end

if strcmp(EDPtype,'SDR')==1 || strcmp(EDPtype,'RDR')==1
    EDP_Vector = 0.0:0.001:CollapseSDR*1.1;
else
    IM_Vector = 0.0:0.01:5;
end

cd (RFpath);
cd ('Results');
EDP_data=importdata(filename)*factor;
cd (MainDirectory);

EDP_max = max(EDP_data,[],2);
EDP_max = EDP_max((GMi-GM_Start)*nRealizations+1:(GMj-GMi+1)*nRealizations,1);
EDP_max = sort(EDP_max);
nTotal  = (GMj-GMi+1)*nRealizations;

% Calculate Probability of reaching EDP
for i=1:nTotal
    EmpProbability(i,1)=i/(nTotal+1);
end

%% Plot
% Plot the empirical probability distribution of the EDP maximum values
figure('position',[100 100 350 300],'color','white');
plot (EDP_max,EmpProbability, 'ok','MarkerEdgeColor','k','MarkerFaceColor',[0.6 0.6 0.6]);
set(gca, 'fontname', 'Times', 'fontsize',15)
xlabel (xlabelstr);
ylabel (ylabelstr);
grid on; hold on; box on;

% Plot the Mean Lognormal SDRmax Fragility Curve
Median   = median ((EDP_max)); 
MeanEDP  = mean (log(EDP_max)); 
SigmaEDP = std(log(EDP_max)); 
EDPrange = (0.0:max(EDP_max)*1.2/30:max(EDP_max)*1.2);
CDFProbability = logncdf(EDPrange,MeanEDP,SigmaEDP);
plot(EDPrange,CDFProbability,'-r','linewidth',2);
TitleX{1}=sprintf('%s %5.3f %s', '\it\mu\rm=', exp(MeanEDP),unit);
TitleX{2}=sprintf('%s %5.3f', '\it \sigma\rm =', SigmaEDP);
annotation('textbox',[0.6 0.6 0.5 0.1],'String',TitleX,'fontsize',12,'FitBoxToText','on', 'fontname', 'Times');
legend1=legend ('Empirical distribution','Lognormal CDF');
set(legend1 , 'fontsize',12,'location','southeast');
