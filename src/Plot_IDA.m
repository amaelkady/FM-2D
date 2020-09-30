function Plot_IDA (GMi, GMj, EDPtype)
global MainDirectory ProjectName ProjectPath

cd (ProjectPath)
load (ProjectName,'CollapseSDR','GM','SA_metric','RFpath','zeta')
cd (MainDirectory)

if strcmp(EDPtype,'SDR')==1; filename='IDA SDR.txt'; xlabelstr='\itSDR\rm_{max} [% rad]'; end
if strcmp(EDPtype,'RDR')==1; filename='IDA RDR.txt'; xlabelstr='\itRDR\rm_{max} [% rad]'; end
if strcmp(EDPtype,'PFA')==1; filename='IDA PFA.txt'; xlabelstr='\itPFA\rm_{max} [g]';     end

if strcmp(EDPtype,'SDR')==1 || strcmp(EDPtype,'RDR')==1
    EDP_Vector = 0.0:0.001:CollapseSDR*1.1;
else
    IM_Vector = 0.0:0.01:5;
end

figure('position',[100 100 350 300],'color','white');
hold on; grid on; box on;

noGM = GMj-GMi+1;

for GM_No=GMi:GMj
    
    % Go inside the results folder and read results
    cd (RFpath)
    cd ('Results')
    cd (GM.Name{GM_No})
    
    %% Read IDA Data
    x=importdata(filename);
    IM=x(:,1);
    EDPdata=max(x(:,2:end),[],2);
    IMmax(GM_No)=x(end,1);
    MAXedp(GM_No)=max(EDPdata);
    

    
    if strcmp(EDPtype,'SDR')==1 || strcmp(EDPtype,'RDR')==1
        for i=1:length(EDP_Vector)
            for j=1:size(IM,1)-1
                if EDP_Vector(i)>EDPdata(j,1) && EDP_Vector(i)<=EDPdata(j+1,1)
                    IM_Interp (GM_No,i)=IM(j,1)+(EDP_Vector(i)-EDPdata(j,1))*(IM(j+1,1)-IM(j,1))/(EDPdata(j+1,1)-EDPdata(j,1));
                    break;
                end
            end
        end
    else
        IM=[IM; 5];
        EDPdata=[EDPdata; max(EDPdata)];
        for i=1:length(IM_Vector)
            for j=1:size(IM,1)-1
                if IM_Vector(i)>IM(j,1) && IM_Vector(i)<=IM(j+1,1)
                    EDP_Interp (GM_No,i)=EDPdata(j,1)+(IM_Vector(i)-IM(j,1))*(EDPdata(j+1,1)-EDPdata(j,1))/(IM(j+1,1)-IM(j,1));
                    break;
                end
            end
        end
    end
    
    if GM_No==1; plot (EDPdata, IM,'-','LineWidth',1,'Color',[0.7 0.7 0.7],'HandleVisibility','on'); end
    if GM_No>1;  plot (EDPdata, IM,'-','LineWidth',1,'Color',[0.7 0.7 0.7],'HandleVisibility','off'); end
end


if strcmp(EDPtype,'SDR')==1 || strcmp(EDPtype,'RDR')==1
    Median50_EDP  =  median(IM_Interp);
    if noGM>=3; plot(EDP_Vector,Median50_EDP, '-r' , 'linewidth',2.6); end
    
    set(gca,'FontName','Times','FontSize',15);
    xlabel (xlabelstr);
    set(gca,'XLim',[0 CollapseSDR]);
    set(gca,'YLim',[0 1.1*max(IMmax)]);
    if SA_metric ==1; ylabel (['\itSa\rm(\itT\rm_1, ',num2str(zeta*100),'%) [g]']); end
    if SA_metric ==2; ylabel (['\itSa\rm_{avg}(0.2\itT\rm_1~3\itT\rm_1, ',num2str(zeta*100),'%) [g]']); end
    legend('individual record','median')
    if noGM>=3; L=legend('individual record','median'); set(L,'FontSize',12,'Location','northoutside','Orientation','horizontal'); end
else
    Median50_EDP  =  median(EDP_Interp);
    if noGM>=3; plot(Median50_EDP,IM_Vector, '-r' , 'linewidth',2.6); end    
    
    set(gca,'FontName','Times','FontSize',16);
    xlabel (xlabelstr);
    set(gca,'XLim',[0 max(MAXedp)*1.3]);
    set(gca,'YLim',[0 1.3*max(IMmax)]);
    if SA_metric ==1; ylabel (['\itSa\rm(\itT\rm_1, ',num2str(zeta*100),'%) [g]']); end
    if SA_metric ==2; ylabel (['\itSa\rm_{avg}(0.2\itT\rm_1~3\itT\rm_1, ',num2str(zeta*100),'%) [g]']); end
    legend('individual record','median')
    if noGM>=3; L=legend('individual record','median'); set(L,'FontSize',12,'Location','northoutside','Orientation','horizontal'); end
end
cd (MainDirectory)
