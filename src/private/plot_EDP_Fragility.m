function plot_EDP_Fragility(GMi, GMj, EDPtype)
% Rank and fit all available responses, including marked stopped runs.
global MainDirectory
load(fullfile(MainDirectory,'temp_unpacked.mat'),'GM_Start','RFpath','nRealizations');

switch EDPtype
    case 'SDR'
        xlabelstr='\itSDR\rm_{max} [% rad]'; ylabelstr='P(\itsdr\rm \leq \itSDR\rm_{max})'; unit='% rad'; factor=100;
    case 'RDR'
        xlabelstr='\itRDR\rm_{max} [% rad]'; ylabelstr='P(\itrdr\rm \leq \itRDR\rm_{max})'; unit='% rad'; factor=100;
    case 'PFA'
        xlabelstr='\itPFA\rm_{max} [g]'; ylabelstr='P(\itpfa\rm \leq \itPFA\rm_{max})'; unit='g'; factor=1;
    otherwise
        error('FM2D:UnsupportedEDP','Unsupported fragility response: %s.',EDPtype);
end
[profiles,~,selection]=read_Selected_Profile(RFpath,EDPtype,GMi,GMj,GM_Start,nRealizations,1,factor,true);
EDP_max=max(profiles,[],2);
complete=~selection.Partial;
if any(EDP_max<0), error('FM2D:InvalidEDP','EDP maxima must be nonnegative.'); end
[ordered,order]=sort(EDP_max);
nTotal=numel(ordered); EmpProbability=(1:nTotal)'/(nTotal+1);
probability=zeros(nTotal,1); probability(order)=EmpProbability;

%% Empirical points retain valid zeros; logarithmic fitting requires positives
figure('position',[100 100 350 300],'color','white');
handles=gobjects(0); labels={};
if any(complete)
    handles(end+1)=plot(EDP_max(complete),probability(complete),'ok','MarkerEdgeColor','k','MarkerFaceColor',[.6 .6 .6],'LineStyle','none');
    labels{end+1}='Completed responses';
end
grid on; hold on; box on;
set(gca,'fontname','Times','fontsize',15);
xlabel(xlabelstr); ylabel(ylabelstr);
upper=max(1e-6,1.2*max(EDP_max)); xlim([0 upper]); ylim([0 1]);
incomplete=selection.Partial & ~selection.Timeout;
if any(incomplete)
    handles(end+1)=plot(EDP_max(incomplete),probability(incomplete),'>','Color',[.8 .3 0],'MarkerFaceColor','none','MarkerSize',8,'LineStyle','none');
    labels{end+1}='Incomplete';
end
if any(selection.Timeout)
    handles(end+1)=plot(EDP_max(selection.Timeout),probability(selection.Timeout),'s','Color',[.55 .2 .65],'MarkerFaceColor','none','MarkerSize',7,'LineStyle','none');
    labels{end+1}='Timeout';
end
positive=EDP_max(EDP_max>0);
fitLabel=sprintf('Fit samples: %d / %d selected',numel(positive),selection.Total);
if numel(positive)>=2 && numel(unique(positive))>=2
    MeanEDP=mean(log(positive)); SigmaEDP=std(log(positive));
    EDPrange=linspace(0,upper,301);
    CDFProbability=.5*erfc(-(log(EDPrange)-MeanEDP)/(sqrt(2)*SigmaEDP));
    fitted=plot(EDPrange,CDFProbability,'-r','linewidth',2);
    details={sprintf('Median = %.3f %s',exp(MeanEDP),unit),sprintf('Log std = %.3f',SigmaEDP),fitLabel};
    handles(end+1)=fitted; labels{end+1}='Lognormal CDF (all available)';
else
    details={'No lognormal fit', 'Need two distinct positive samples',fitLabel};

end
if any(selection.Partial)
    details{end+1}=sprintf('Includes %d incomplete + %d timeout',nnz(incomplete),nnz(selection.Timeout));
    if strcmp(EDPtype,'RDR'), details{end+1}='Incomplete: last recorded drift';
    else, details{end+1}='Incomplete: available peak response'; end
end
legend(handles,labels,'FontSize',10,'Location','southeast');
text(.04,.96,details,'Units','normalized','VerticalAlignment','top','FontSize',10,'Interpreter','none');
if selection.Included<selection.Total
    title(sprintf('%d / %d available results',selection.Included,selection.Total),'FontSize',11);
end
end
