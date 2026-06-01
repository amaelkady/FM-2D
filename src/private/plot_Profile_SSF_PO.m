function plot_Profile_SSF_PO(POC)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'NStory','NBay','PO','ELF','EQ','CDPO','TTH','FILENAME','GM','Uncertainty','Parallel','RFpath','Elevation','HalfElevation','YTickLabel');

    if PO==1;                     SubRFname='Pushover';                         
elseif ELF==1;                    SubRFname='ELF';                              
elseif EQ==1 && Uncertainty==0;   if Parallel==0; SubRFname = GM.name{GM_No}; else; SubRFname = [GM.name{GM_No},'_1']; end                  
elseif EQ==1 && Uncertainty==1;   SubRFname= [GM.name{GM_No},'_',num2str(Ri)];  
elseif CDPO==1;                   SubRFname='Pushover';                         
elseif TTH==1;                    SubRFname='Tsunami';                          end
    
% Go inside the results folder and read results
cd(strcat(RFpath,'\Results\', SubRFname));

% Read column data
for Story=1:NStory
    Column_Shear=0;
    for Axis=1:NBay+3
        evalc(['x=importdata(','''',FILENAME.Column,num2str(Story),num2str(Axis),'.out','''',')']);
        if FrameType==2 && Axis<=NBay+1; evalc(['x2=importdata(','''',FILENAME.CGP,num2str(Story),num2str(Axis),'.out','''',')']); else; x2=zeros(size(x,1),1); end
        Column_Shear=Column_Shear+x(12:end,1)+x2(12:end,1);
    end
    SSF_Y(1,Story)=abs(Column_Shear(POC.indxY,1))/Ws;
    SSF_P(1,Story)=abs(Column_Shear(POC.indxP,1))/Ws;
    SSF_Max(1,Story)=abs(Column_Shear(POC.indxMax,1))/Ws;
    fclose all;
end

cd (MainDirectory)


%% Plot
figure('position',[450 100 350 400],'color','white');
grid on; box on; hold on;
plot (SSF_Y(1,:),   HalfElevation,':og','LineWidth',1.5,'DisplayName','@ 1^{st} yield');
plot (SSF_P(1,:),   HalfElevation,'--ob','LineWidth',1.5,'DisplayName','@ plastic');
plot (SSF_Max(1,:), HalfElevation,'-or','LineWidth',1.5,'DisplayName','@ max');

set(gca,'XLim',[0 1.5*max(max(SSF_Max))]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'FontName','Times','FontSize',14);
ylabel ('Elevation');
xlabel ('Story shear force / \itW\rm_s');
set(gca,'XLim',[0 round(1.2*max(abs(SSF_Max))*100)/100]);

legned();