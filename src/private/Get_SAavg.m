function [Period, MaxAA, SAavg]=Get_SAavg(app)
cla(app.axes1)
app.axes1.FontName = 'Times';
app.axes1.FontSize = 17;

global ProjectPath ProjectName
load(strcat(ProjectPath,ProjectName),'GM','TFreeVibration')

g=1;

zeta=app.T1.Value;

GM_No=app.GMpopup.Value;
app.text26.Tooltip='Period-range start';
app.text25.Tooltip='Period-range end';

GMTime=GM.dt{:,GM_No}:GM.dt{:,GM_No}:GM.duration{:,GM_No}; GMTime=GMTime';
Duration=GM.duration{:,GM_No};

MainGMTime=Duration-TFreeVibration;
for i=1:size(GMTime,1)
    if GMTime(i,1)>=MainGMTime
        idexMainGM=i;
        break
    end
end

GAx = GM.acc{:, GM_No}(1:idexMainGM);
dt=GM.dt{:, GM_No};

To=app.edit8.Value;
Tend =app.edit7.Value;

% Compute and plot elastic response spectrum
countT=1;
for TT=0:0.05:10
    if TT==0; TT=0.001; end
    GMpsaTi = cent_diff(GAx, TT, dt, zeta, g)/g;
    if isinf(GMpsaTi)==1; GMpsaTi=max(abs(GAx)); end
    Period(countT,1)=TT;
    MaxAA(countT,1)=max(abs(GMpsaTi));
    countT=countT+1;
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
app.axes1.YLim=[0 max(MaxAA)*1.1/g];
app.axes1.XLim=[0 min(10,round(Tend*2))];

% Compute SAavg
Sa_PRODUCT=1;
nsample=0;
sampleStep=(Tend-To)/20;
for Ti=To:sampleStep:Tend
    nsample=nsample+1;
end
for Ti=To:sampleStep:Tend
    Sa_Ti = cent_diff(GAx, Ti, dt, zeta, g)/g;
    Sa_PRODUCT=Sa_PRODUCT*Sa_Ti^(1/nsample);
end
SAavg=(Sa_PRODUCT)/g;

text(app.axes1,To+(Tend-To)/3,0.25*max(MaxAA)/g,[' Sa_{avg}=',num2str(round(SAavg*100)/100),' g'], 'fontname', 'Courier', 'fontsize',12,'fontweight','bold')

end