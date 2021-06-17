function [FigI]=Show_Scope_IDA(AnalysisCount,SAcurrent,NumInstability_Flag,SDRincrmax,PFAincrmax,PFA_last_NC,CollapseSDR,FigI)

if AnalysisCount==1
    FigI=figure('position',[100 100 500 200],'color','white','AutoResizeChildren', 'off');
    
    subplot(1,2,1)
    plot([0],[0],'ok','markerfacecolor','r','markersize',5);
    grid on; box on; hold on;
    set(gca, 'fontname', 'times', 'fontsize',12);
    xlabel ('\itSDR\rm_{max} [rad]');
    ylabel ('IM [g]');
    set(gca,'Xlim',[0 0.10])
    set(gca,'Ylim',[0 1.0])
    
    subplot(1,2,2)
    plot([0],[0],'ok','markerfacecolor','r','markersize',5);
    grid on; box on; hold on;
    set(gca, 'fontname', 'times', 'fontsize',12);
    xlabel ('\itPFA\rm_{max} [g]');
    ylabel ('IM [g]');
    set(gca,'Xlim',[0 1.0])
    set(gca,'Ylim',[0 1.0])
    
    if NumInstability_Flag==0
        subplot(1,2,1)
        plot(SDRincrmax,SAcurrent,'ok','markerfacecolor','r','markersize',5);
        subplot(1,2,2)
        plot(PFAincrmax,SAcurrent,'ok','markerfacecolor','r','markersize',5);
    else
        subplot(1,2,1)
        plot([0 0.15],[SAcurrent SAcurrent],'--r')
        subplot(1,2,2)
        plot([0    5],[SAcurrent SAcurrent],'--r')
    end
    drawnow
else
    if NumInstability_Flag==0
        subplot(1,2,1)
        plot(SDRincrmax,SAcurrent,'ok','markerfacecolor','r','markersize',5);
        subplot(1,2,2)
        plot(PFAincrmax,SAcurrent,'ok','markerfacecolor','r','markersize',5);
    else
        subplot(1,2,1)
        plot([0 0.15],[SAcurrent SAcurrent],'--r')
        subplot(1,2,2)
        plot([0    5],[SAcurrent SAcurrent],'--r')
    end
    drawnow
end

subplot(1,2,1)
v=ylim;
set(gca,'Ylim',[0  max(1.5 * SAcurrent,v(2))])
v=xlim;
set(gca,'Xlim',[0  min(CollapseSDR,max(1.5 * SDRincrmax,v(2)))])
subplot(1,2,2)
v=ylim;
set(gca,'Ylim',[0  max(1.5 * SAcurrent,v(2))])
v=xlim;
set(gca,'Xlim',[0  max(1.5 * PFA_last_NC,v(2))])
