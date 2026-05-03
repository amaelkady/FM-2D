function [X,Y, POC]=Plot_BSF_vs_SDR1(GM_No, Ri, plotstatus)

arguments
    GM_No      (1,1) {mustBePositive, mustBeInteger}
    Ri         (1,1)
    plotstatus (1,1) {mustBeInteger} = 1 
end

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName),'FrameType','Ws','RFpath','Recorders','Filename','NBay','PO','EQ','ELF','CDPO','TTH','GM','FrameType','Uncertainty','Parallel')


    if PO==1;                     SubRFname = 'Pushover';                        
elseif ELF==1;                    SubRFname = 'ELF';                             
elseif EQ==1 && Uncertainty==0;   if Parallel==0; SubRFname = GM.name{GM_No}; else; SubRFname = [GM.name{GM_No},'_1']; end                  
elseif EQ==1 && Uncertainty==1;   SubRFname = [GM.name{GM_No},'_',num2str(Ri)];  
elseif CDPO==1;                   SubRFname = 'Pushover';                        
elseif TTH==1;                    SubRFname = 'Tsunami';                         end

%% Go inside the results folder and read results
cd (strcat(RFpath,'\Results\',SubRFname));

% Read SDR Data
if Recorders.SDR==1
    evalc(strcat('x=importdata(','''',Filename.SDR,'1_MF.out','''',')'));
    SDR_MF(:,1)=x(10:end,1);
end

% Read Base Shear Force Data
if Recorders.Support==1 % Compute BSF based on support reaction
    BSF=0;
    for Axis=1:NBay+3	
        evalc(['x=importdata(','''',Filename.Support,num2str(Axis),'.out','''',')']);
        Column_Shear(:,Axis)=x(10:end,1);
    end
elseif Recorders.Column==1 % Compute BSF based on column (and CGP) forces
    BSF=0;
    for Axis=1:NBay+3	
        evalc(['x=importdata(','''',Filename.Column,'1',num2str(Axis),'.out','''',')']);
        if FrameType~=1 && Axis<=NBay+1; evalc(['x2=importdata(','''',Filename.CGP,'1',num2str(Axis),'.out','''',')']); else; x2=zeros(size(x,1),1); end
        Column_Shear(:,Axis)=x(10:end,1)+x2(10:end,1);
    end
end

cd (MainDirectory)

% Calculate Base Shear Force History
BSF=sum(Column_Shear,2);

if PO==1 || ELF==1
    try
        % get pushover curve key parameters
        X=abs(SDR_MF(:,1));
        Y=abs(BSF);
        indx=find(BSF>0.01);
        X(min(indx)-1:end,:)=[];
        Y(min(indx)-1:end,:)=[];
        Data = [X Y];
        [POC.Ke, POC.Ks, POC.Vy, POC.Vp, POC.Vmax] = get_backbone_markers(Data);
        POC.indxY   = find(Data(:,2)==POC.Vy);
        POC.indxP   = min(find(Data(:,2)>=POC.Vp));
        POC.indxMax = find(Data(:,2)==POC.Vmax);
    catch 
    
    end
end

%% Plot
if plotstatus==1

    figure('position',[100 100 350 250],'color','white');
    grid on; box on; hold on;
    if PO==1 || ELF==1
        X=abs(SDR_MF(:,1)*100);
        Y=abs(BSF/Ws);
        indx=find(BSF>0.01);
        X(min(indx)-1:end,:)=[];
        Y(min(indx)-1:end,:)=[];
        set(gca,'XLim',[0 1.2*max(abs(X))]);
        set(gca,'YLim',[0 round(1.2*max(abs(Y))*100)/100]);
    else
        X=(SDR_MF(:,1)*100);
        Y=(BSF/Ws);    
        set(gca,'XLim',[-1.2*max(abs(X)) 1.2*max(abs(X))]);
        set(gca,'YLim',[-round(1.2*max(abs(Y))*100)/100 round(1.2*max(abs(Y))*100)/100]);
    end
    
    plot (X, Y,'-k','LineWidth',1.5);
    set(gca,'FontName','Times','FontSize',14);
    xlabel ('\itSDR\rm_1 [% rad]');
    ylabel ('\itBSF\rm /\itW_s');
    if PO==1 || ELF==1
        str{1}=['K_{e} = ', num2str(round(POC.Ke))];
        str{2}=['V_{y} = ', num2str(round(POC.Vy))];
        str{3}=['V_{p} = ', num2str(round(POC.Vp))];
        str{4}=['V_{max} = ', num2str(round(POC.Vmax))];
        text(0.8*max(abs(X)), 0.7*round(1.2*max(abs(Y))*100)/100,  str)
    elseif EQ==1
        plot ([-max(abs(X))*1.5 max(abs(X))*1.5],[0 0], '-k','linewidth',0.5);
        plot ([0 0],[-max(abs(Y))*1.5 max(abs(Y))*1.5], '-k','linewidth',0.5);
    end
    drawnow

else

    if PO==1 || ELF==1
        X=abs(SDR_MF(:,1)*100);
        [~,indxMax]=max(abs(BSF));
        if BSF(indxMax)<0; Y=(-BSF/Ws); else; Y=(BSF/Ws); end 
    else
        X=(SDR_MF(:,1)*100);
        Y=(BSF/Ws);    
    end

end