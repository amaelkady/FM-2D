function Plot_SDR_Profile()

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName),'FrameType','RFpath','Recorders','Filename','NStory','PO','EQ','ELF','CDPO','TTH','GM','FrameType','Uncertainty')

if PO==1;                     SubRFname = 'Pushover';                        end
if ELF==1;                    SubRFname = 'ELF';                             end
if EQ==1 && Uncertainty==0;   SubRFname = GM.Name{GM_No};                    end
if EQ==1 && Uncertainty==1;   SubRFname = [GM.Name{GM_No},'_',num2str(Ri)];  end
if CDPO==1;                   SubRFname = 'Pushover';                        end
if TTH==1;                    SubRFname = 'Tsunami';                         end

%% Go inside the results folder and read results
cd (strcat(RFpath,'\Results\',SubRFname));

% Read SDR Data
if Recorders.SDR==1
    for i=1:NStory
        evalc(strcat('x=importdata(','''',Filename.SDR,num2str(i),'_MF.out','''',')'));
        SDR_MF(i,1)=x(end,1);
    end
end

cd (MainDirectory)


%% Plot
figure('position',[100 100 350 250],'color','white');
grid on; box on; hold on;
if PO==1 || ELF==1
    X=abs(SDR_MF(:,1)*100);
    Y=HalfElevation;
    plot (X, Y,'-ok','LineWidth',1.5);
    set(gca,'XLim',[0 1.5*max(max(RDR_MF))]);
    set(gca,'YLim',[0  max(Elevation)]);
    set(gca,'YTick',Elevation);
    set(gca,'YTickLabel',YTickLabel);
    xlabel ('\itSDR\rm [% rad]');
    ylabel ('Elevation');
    set(gca,'FontName','Times','FontSize',14);
end

drawnow