function plot_Response_Profiles(profiles,elevation,partial,timeout)
% Distinguish stopped runs; compute the median using all available responses.
if nargin<4, timeout=false(size(partial)); end
handles=gobjects(0); labels={};
complete=~partial;
if any(complete)
    h=plot(profiles(complete,:)',elevation,'-','LineWidth',1,'Color',[.65 .65 .65]);
    handles(end+1)=h(1); labels{end+1}='Completed';
end
if any(partial & ~timeout)
    h=plot(profiles(partial & ~timeout,:)',elevation,'--','LineWidth',1.5,'Color',[.8 .3 0]);
    handles(end+1)=h(1); labels{end+1}='Incomplete';
end
if any(timeout)
    h=plot(profiles(timeout,:)',elevation,':','LineWidth',1.5,'Color',[.55 .2 .65]);
    handles(end+1)=h(1); labels{end+1}='Timeout';
end
if size(profiles,1)>=3
    handles(end+1)=plot(median(profiles,1),elevation,'-ok','LineWidth',2,'MarkerFaceColor','r');
    labels{end+1}='Median (all available)';
end
legend(handles,labels,'FontSize',10,'Location','northoutside');
end
