function Plot_BSF_vs_RDR(GM_No, Ri)

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName),'FrameType','Ws','HBuilding','RFpath','Recorders','Filename','NStory','NBay','PO','EQ','ELF','CDPO','TTH','GM','Uncertainty')

if PO==1;                     SubRFname = 'Pushover';                        end
if ELF==1;                    SubRFname = 'ELF';                             end
if EQ==1 && Uncertainty==0;   SubRFname = GM.Name{GM_No};                    end
if EQ==1 && Uncertainty==1;   SubRFname = [GM.Name{GM_No},'_',num2str(Ri)];  end
if CDPO==1;                   SubRFname = 'Pushover';                        end
if TTH==1;                    SubRFname = 'Tsunami';                         end

%% Go inside the results folder and read results
cd (strcat(RFpath,'\Results\',SubRFname));

% Read Floor Displacement Data
if Recorders.Disp==1
    Floor=NStory+1;
    evalc(['x=importdata(','''',Filename.Disp,num2str(Floor),'_MF.out','''',')']);
    Disp_MF(:,Floor)=x(10:end,1);
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

%% Plot
figure('position',[100 100 350 250],'color','white');
grid on; box on; hold on;
if PO==1 || ELF==1
    X=abs(Disp_MF(:,end)*100/HBuilding);
    Y=abs(BSF/Ws);
    indx=find(BSF>0.01);
    X(min(indx)-1:end,:)=[];
    Y(min(indx)-1:end,:)=[];
    set(gca,'XLim',[0 1.2*max(abs(X))]);
    set(gca,'YLim',[0 round(1.2*max(abs(Y))*100)/100]);
else
    X=(Disp_MF(:,end)*100/HBuilding);
    Y=(BSF/Ws);    
    set(gca,'XLim',[-1.2*max(abs(X)) 1.2*max(abs(X))]);
    set(gca,'YLim',[-round(1.2*max(abs(Y))*100)/100 round(1.2*max(abs(Y))*100)/100]);
end
plot (X, Y,'-k','LineWidth',2);
set(gca,'FontName','Times','FontSize',14);
xlabel ('Roof Drift Ratio [% rad]');
ylabel ('\itBSF\rm /\itW_s');
if EQ==1
plot ([-max(abs(X))*1.5 max(abs(X))*1.5],[0 0], '-k','linewidth',0.5);
plot ([0 0],[-max(abs(Y))*1.5 max(abs(Y))*1.5], '-k','linewidth',0.5);
end
drawnow