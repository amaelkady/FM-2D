function Plot_Profile_SSF(GMi, GMj)

global MainDirectory ProjectName ProjectPath
cd (ProjectPath)
load (ProjectName)
cd (MainDirectory)

noGM = GMj-GMi+1;

for GM_No=GMi:GMj
    
    if PO==1;                     SubRFname='Pushover';                         end
    if ELF==1;                    SubRFname='ELF';                              end
    if EQ==1 && Uncertainty==0;   SubRFname= GM.Name{GM_No};                    end
    if EQ==1 && Uncertainty==1;   SubRFname= [GM.Name{GM_No},'_',num2str(Ri)];  end
    
    % Go inside the results folder and read results
    cd (RFpath)
    cd ('Results')
    cd (SubRFname)
    
    % Read column data
    for Story=1:NStory
        Column_Shear=0;
        for Axis=1:NBay+3
            evalc(['x=importdata(','''',Filename.Column,num2str(Story),num2str(Axis),'.out','''',')']);
            if FrameType==2 && Axis<=NBay+1; evalc(['x2=importdata(','''',Filename.CGP,num2str(Story),num2str(Axis),'.out','''',')']); else; x2=zeros(size(x,1),1); end
            Column_Shear=Column_Shear+x(12:end,1)+x2(12:end,1);
        end
        SSF(GM_No,Story)=max(abs(Column_Shear))/Ws;
        fclose all;
    end
    
    cd (MainDirectory)

end


%% Plot
figure('position',[100 100 350 400],'color','white');
grid on; box on; hold on;
plot ([0 0], [-0.1 -0.1],'-','LineWidth',1,'Color',[0.70 0.70 0.70]);
for GM_No = (GMi-GM_Start)*nRealizations+1:noGM*nRealizations
    if noGM>=3 || nRealizations>1
        plot (SSF(GM_No,:), HalfElevation,'-','LineWidth',1,'Color',[0.70 0.70 0.70],'HandleVisibility','off');
    elseif noGM==1
        plot (SSF(GM_No,:), HalfElevation,'-ok','LineWidth',1.5);
    elseif noGM==2
        plot (SSF(GM_No,:), HalfElevation,'-*b','LineWidth',1.5);
    end
end
if noGM>=3 || nRealizations>1; plot (median(SSF), HalfElevation,'-ok','LineWidth',2,'MarkerFaceColor','r'); end
set(gca,'XLim',[0 1.5*max(max(SSF))]);
set(gca,'YLim',[0  max(Elevation)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'FontName','Times','FontSize',14);
ylabel ('Elevation');
xlabel ('Story shear force / \itW\rm_s');
if noGM>=3 || nRealizations>1; L=legend('individual record/Ri','median'); set(L,'FontSize',12,'Location','northoutside','Orientation','horizontal'); end

