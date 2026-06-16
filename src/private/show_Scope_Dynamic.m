function [FigD]=show_Scope_Dynamic(NumInstability_Flag, Collapse, DATA, nGM_total, GM_No, FigD, Ri)

try
if GM_No==1 && FigD==0 && Ri==1
	FigD=figure('position',[100 500 450 150],'color','white');%,'AutoResizeChildren', 'off');
	
    subplot(1,2,1)
	grid on; box on; hold on;
	set(gca, 'fontname', 'times', 'fontsize',10);
	ylabel ('\itSDR\rm_{max} [rad]');
	xlabel ('GM number');
    xticks(1:max(1,round(nGM_total/5)):nGM_total);
    set(gca,'Xlim',[0.5 nGM_total+0.5])

	subplot(1,2,2)
	grid on; box on; hold on;
	set(gca, 'fontname', 'times', 'fontsize',10);
	ylabel ('\itPFA\rm_{max} [g]');
	xlabel ('GM number');
    xticks(1:max(1,round(nGM_total/5)):nGM_total);
    set(gca,'Xlim',[0.5 nGM_total+0.5])

	if NumInstability_Flag==0
		subplot(1,2,1)
		plot(GM_No,DATA.SDRincrmax,'ok','markerfacecolor','r','markersize',5);
        if Collapse==1; h=text(GM_No,1.1*DATA.SDRincrmax,'Collapse','fontsize',6); set(h,'rotation',90); end
        set(gca,'Ylim',[0  1.5 * DATA.SDRincrmax])
		subplot(1,2,2)
		plot(GM_No,DATA.PFAincrmax,'ok','markerfacecolor','r','markersize',5);
        if Collapse==1; h=text(GM_No,1.1*DATA.PFAincrmax,'Collapse','fontsize',6); set(h,'rotation',90); end
        set(gca,'Ylim',[0  1.5 * DATA.PFAincrmax])
	else
		subplot(1,2,1)
		plot(GM_No,0,'ok','markerfacecolor','b','markersize',5);
		subplot(1,2,2)
		plot(GM_No,0,'ok','markerfacecolor','b','markersize',5);
	end
	drawnow
else
	if NumInstability_Flag==0
		subplot(1,2,1)
		plot(GM_No,DATA.SDRincrmax,'ok','markerfacecolor','r','markersize',5);
        if Collapse==1; h=text(GM_No,1.1*DATA.SDRincrmax,'Collapse','fontsize',6); set(h,'rotation',90); end
        v=ylim;
        set(gca,'Ylim',[0  max(1.5 * DATA.SDRincrmax,v(2))])
		subplot(1,2,2)
		plot(GM_No,DATA.PFAincrmax,'ok','markerfacecolor','r','markersize',5);
        if Collapse==1; h=text(GM_No,1.1*DATA.PFAincrmax,'Collapse','fontsize',6); set(h,'rotation',90); end
        v=ylim;
        set(gca,'Ylim',[0  max(1.5 * DATA.PFAincrmax,v(2))])
	else
		subplot(1,2,1)
		plot(GM_No,0,'ok','markerfacecolor','b','markersize',5);
		subplot(1,2,2)
		plot(GM_No,0,'ok','markerfacecolor','b','markersize',5);
	end
	drawnow
end
end
