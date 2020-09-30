function Plot_Collapse_Fragility (GMi, GMj)
global MainDirectory ProjectName ProjectPath

cd (ProjectPath)
load (ProjectName,'CollapseSDR','GM','SA_metric','RFpath','zeta')
cd (MainDirectory)

for GM_No=GMi:GMj
    GMname 	  = GM.Name{GM_No};
    SubRFname = GMname;
    
    % Go inside the results folder and read results
    cd (RFpath)
    cd ('Results')
    cd (SubRFname)
    
    %% Read IDA Data
    x=importdata('IDA SDR.txt');
    CollapseSA(GM_No,1)=x(end,1);
    cd (MainDirectory)
end

CollapseSA=sort (CollapseSA,1);    % Sort the Collapse SA Vector in Asscending Order
N_GM=GMj-GMi+1;

% Calculate Probability of Collapse Given a SA Level
for GM_No=1:N_GM
    EmpProbability(GM_No,1)=GM_No/(N_GM+1);
end

% Plot the Collapse SA Values vs Thier Probability of Collapse
figure('position',[100 100 350 300],'color','white');
plot (CollapseSA,EmpProbability, 'ok','MarkerEdgeColor','k','MarkerFaceColor',[0.6 0.6 0.6]);
set(gca, 'fontname', 'Times', 'fontsize',15)
if SA_metric ==1; xlabel (['\itSa\rm(\itT\rm_1, ',num2str(zeta*100),'%) [g]']); end
if SA_metric ==2; xlabel (['\itSa\rm_{avg}(0.2\itT\rm_1~3\itT\rm_1, ',num2str(zeta*100),'%) [g]']); end
ylabel ('Probabilty of Collapse');
grid on; hold on; box on;

% Plot the Mean Lognormal Collapse Fragility Curve
Median=median ((CollapseSA));                       % Median of Logarithmic SA Collapse Values
MeanSA=mean (log(CollapseSA));                           % Mean   of Logarithmic SA Collapse Values
SigmaSA=std(log(CollapseSA));                            % Standar Deviation of Logarithmic SA Collapse Values
SA = (0.0:0.01:max(CollapseSA)+1.0);
EmpProbability = logncdf(SA,MeanSA,SigmaSA);
plot(SA,EmpProbability,'-r','linewidth',2);
TitleX{1}=sprintf('%s %5.3f %s', '\it\mu\rm=', exp(MeanSA),'g');
TitleX{2}=sprintf('%s %5.3f', '\it \sigma\rm =', SigmaSA);
annotation('textbox',[0.6 0.6 0.5 0.1],'String',TitleX,'fontsize',12,'FitBoxToText','on', 'fontname', 'Times');
legend1=legend ('Collapse intensities','Lognormal CDF');
set(legend1 , 'fontsize',12,'location','southeast');