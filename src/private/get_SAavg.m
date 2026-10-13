function [Period, MaxAA, SAavg]=get_SAavg(app)
cla(app.axes1)
app.axes1.FontName = 'Times';
app.axes1.FontSize = 17;

global ProjectPath ProjectName
load(strcat(ProjectPath,ProjectName),'ANALYSIS')
GM=ANALYSIS.GM;

g=1;

zeta=app.T1.Value;

GM_No=app.GMpopup.Value;
app.text26.Tooltip='Period-range start';
app.text25.Tooltip='Period-range end';

[~,GAx,dt]=get_GM_Record(GM,GM_No);

To=app.edit8.Value;
Tend =app.edit7.Value;
validateattributes(To,{'numeric'},{'real','finite','scalar','nonnegative'});
validateattributes(Tend,{'numeric'},{'real','finite','scalar','>',To});
validateattributes(zeta,{'numeric'},{'real','finite','scalar','nonnegative'});

% Compute and plot elastic response spectrum
Period=(0:0.05:10)';
MaxAA=zeros(size(Period));
MaxAA(1)=max(abs(GAx)); % Zero-period ordinate is PGA.
for countT=2:numel(Period)
    MaxAA(countT)=get_SA_SDoF(Period(countT),dt,zeta,GAx,g)/g;
end

plot(app.axes1,Period,MaxAA/g,'-r','linewidth',1.5)
app.axes1.XLabel.String='Period [sec]';
app.axes1.YLabel.String='Max. Abs. Acceleration [g]';
app.axes1.XLabel.FontName='Times';
app.axes1.YLabel.FontName='Times';

scatter(app.axes1,To,interp1(Period,MaxAA,To)/g,'ok','markerfacecolor','g')
scatter(app.axes1,Tend,interp1(Period,MaxAA,Tend)/g,'ok','markerfacecolor','g')

%% Plot Origin Lines
plot(app.axes1,[To To],[0 interp1(Period,MaxAA,To)/g],'--k')
plot(app.axes1,[Tend Tend],[0 interp1(Period,MaxAA,Tend)/g],'--k')
app.axes1.YLim=[0 max(1e-6,max(MaxAA)*1.1/g)];
app.axes1.XLim=[0 max(0.05,min(10,Tend*2))];

% Compute SAavg
Sa_PRODUCT=1;
periods=linspace(To,Tend,21);
nsample=numel(periods);
for Ti=periods
    if Ti==0
        Sa_Ti=max(abs(GAx));
    else
        Sa_Ti=get_SA_SDoF(Ti,dt,zeta,GAx,g)/g;
    end
    Sa_PRODUCT=Sa_PRODUCT*Sa_Ti^(1/nsample);
end
SAavg=(Sa_PRODUCT)/g;

text(app.axes1,To+(Tend-To)/3,0.25*max(MaxAA)/g,[' Sa_{avg}=',num2str(round(SAavg*100)/100),' g'], 'fontname', 'Courier', 'fontsize',12,'fontweight','bold')

end
