function [fig1, ax]=plot_MRF_with_labels(labelflag, fontsize, labelsize)

arguments
    labelflag (1,1) double = 1
    fontsize  (1,1) double = 16;
    labelsize (1,1) double = 9;
end

clc;

global ProjectName ProjectPath
load(strcat(ProjectPath,ProjectName))


a=0; b=0; c=0;

[Column_Index, Beam_Index, Brace_Index, XSecID] = Get_Section_Database_Index(FrameType, NStory, NBay, MF_COLUMNS, MF_BEAMS, BRACES, Units);
[GridX, GridY, AXIS, Elevation, HalfElevation, XTickLabel, YTickLabel] = Get_Grid (NStory, NBay,HStory, WBay);


for Story=1:NStory
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,Axis};
        [SecData]=Load_SecData (Section, Units);
        Column_Data.d(Story,Axis)=SecData.d(Column_Index(Story,Axis));
    end
end


for Floor=2:NStory+1
    Fi=Floor-1;
    for Bay=1:NBay
        Section=MF_BEAMS{Fi,Bay};
        [SecData]=Load_SecData (Section, Units);
        Beam_Data.d(Fi,Bay)=SecData.d(Beam_Index(Fi,Bay));
    end
end


fig1=figure('position',[100 100 max(500,500*HBuilding/HBuilding) 500],'color','white');
ax = axes('parent',fig1);
grid on; hold on; box on;
xlim([0.0-0.5*WBay(1)   GridX(end-2)+0.5*WBay(1)]);
ylim([0.0-0.2*HStory(1) HBuilding+0.5*HStory(1)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'XTick',AXIS(1:end-2));
set(gca,'XTickLabel',XTickLabel);
% ylabel('Floor');
xlabel('Axis');
set(gca,'GridLineStyle','-.');
set(gca,'GridColor',[0.0 0.0 0.0]);

% Plot Column Elements
for Story=1:NStory
    Fi=Story; Fj=Story+1; Fjb=min(NStory,Story+1);
    for Axis=1:NBay+1
        plot([GridX(Axis) GridX(Axis)],[GridY(Fi)+Beam_Data.d(Fi,1)/2 GridY(Fj)-Beam_Data.d(Fjb,1)/2],'-k');
    end
end
drawnow;

% Plot Splice Points
for Story=1:NStory
    if Splice(Story,1)
        Fi=Story;
        for Axis=1:NBay+1
            if SpliceConnection==1; plot([GridX(Axis) GridX(Axis)],[GridY(Fi)+HStory(Story,1)*Splice(Story,2) GridY(Fi)+HStory(Story,1)*Splice(Story,2)],'-ok','MarkerSize',3); end
            if SpliceConnection==2; plot([GridX(Axis) GridX(Axis)],[GridY(Fi)+HStory(Story,1)*Splice(Story,2) GridY(Fi)+HStory(Story,1)*Splice(Story,2)],'-k','Marker','square','MarkerSize',3); end
        end
    end
end
drawnow;

% Plot Beam Elements
for Floor=2:NStory+1
    Story=Floor-1;
    for Bay=1:NBay
        Axisi=Bay; Axisj=Bay+1;
        plot([GridX(Axisi)+Column_Data.d(Story,Axisi)/2 GridX(Axisj)-Column_Data.d(Story,Axisj)/2],  [GridY(Floor) GridY(Floor)],'-k');
    end
end
drawnow;

% Plot PZ Elements
for Floor=2:NStory+1
    Story=Floor-1;
    Fi=Floor-1;
    for Axis=1:NBay+1
        Bay=min(Axis, NBay);
        plot([GridX(Axis)-Column_Data.d(Story,Axis)/2 GridX(Axis)+Column_Data.d(Story,Axis)/2],[GridY(Floor)+Beam_Data.d(Fi,Bay)/2 GridY(Floor)+Beam_Data.d(Fi,Bay)/2],'-k');  % top horizontal element
        plot([GridX(Axis)+Column_Data.d(Story,Axis)/2 GridX(Axis)+Column_Data.d(Story,Axis)/2],[GridY(Floor)+Beam_Data.d(Fi,Bay)/2 GridY(Floor)-Beam_Data.d(Fi,Bay)/2],'-k');  % right vertical element
        plot([GridX(Axis)+Column_Data.d(Story,Axis)/2 GridX(Axis)-Column_Data.d(Story,Axis)/2],[GridY(Floor)-Beam_Data.d(Fi,Bay)/2 GridY(Floor)-Beam_Data.d(Fi,Bay)/2],'-k');  % bottom horizontal element
        plot([GridX(Axis)-Column_Data.d(Story,Axis)/2 GridX(Axis)-Column_Data.d(Story,Axis)/2],[GridY(Floor)-Beam_Data.d(Fi,Bay)/2 GridY(Floor)+Beam_Data.d(Fi,Bay)/2],'-k');  % left vertical element
    end
end
drawnow;


% Plot Column Supports
for Axis=1:NBay+1
    if Support==1
        rectangle('Position',[GridX(Axis)-0.25*HStory(1) -0.08*HStory(1) 0.5*HStory(1) 0.08*HStory(1)],'FaceColor',[0.5 0.5 0.5]);
    else
        patch([GridX(Axis) GridX(Axis)-0.2*HStory(1) GridX(Axis)+0.2*HStory(1)] , [0.0 -0.08*HStory(1) -0.08*HStory(1)],[0.5 0.5 0.5]);
    end
end

if FrameType==2
    % Plot Braces
    for Story=1:NStory
        Fi=Story; Fj=Story+1;
        Axis=1;
        if BraceLayout==1
            if rem(Story,2)~=0
                plot(app.axes1,[ GridX(Axis)    (GridX(Axis)+GridX(Axis+1))/2],[GridY(Fi) GridY(Fj)],'-k');
                plot(app.axes1,[ GridX(Axis+1)  (GridX(Axis)+GridX(Axis+1))/2],[GridY(Fi) GridY(Fj)],'-k');
            else
                plot(app.axes1,[(GridX(Axis)+GridX(Axis+1))/2 GridX(Axis)]  ,[GridY(Fi) GridY(Fj)],'-k');
                plot(app.axes1,[(GridX(Axis)+GridX(Axis+1))/2 GridX(Axis+1)],[GridY(Fi) GridY(Fj)],'-k');
            end
        else
            plot(app.axes1,[ GridX(Axis)    (GridX(Axis)+GridX(Axis+1))/2],[GridY(Fi) GridY(Fj)],'-k');
            plot(app.axes1,[ GridX(Axis+1)  (GridX(Axis)+GridX(Axis+1))/2],[GridY(Fi) GridY(Fj)],'-k');
        end
    end
end

if labelflag==1
%% Plot Section Labels

% Column labels
for Story=1:NStory
    Fi=Story; Fj=Story+1; Fjb=min(NStory,Story+1);
    signalt=-1; if NStory>=12 && mod(Story,2)==0; signalt=1;  end
    for Axis=1:NBay+1
        text(GridX(Axis)+signalt*1.5*Column_Data.d(Story,Axis),  GridY(Fi)+0.2*HStory(Story), MF_COLUMNS{Story,Axis}, 'Rotation',90, 'fontsize',max(7,labelsize*4/NStory));
    end
end

% Beam labels
for Floor=2:NStory+1
    Story=Floor-1;
    for Bay=1:NBay
        Axisi=Bay; Axisj=Bay+1;
        text(GridX(Axisi)+0.35*WBay(Bay,1),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), MF_BEAMS{Floor-1,Bay}, 'fontsize', labelsize);
    end
end
drawnow;

elseif labelflag==2

    % SCWB
    for Floor=2:NStory+1
        for Axis=1:NBay+1
            val=round(CHECKS(Floor-1,Axis).VALUE.SCWB*100)/100;
            if val<1; color='r'; else; color=[0.24 0.42 0]; end
            text(GridX(Axis)-3*Column_Data.d(Floor-1,Axis),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
        end
    end
        
    title('SCWB', 'Color', 'b');

elseif labelflag==3

    % Pcolumn check
    for Story=1:NStory
        Fi=Story; Fj=Story+1; Fjb=min(NStory,Story+1);
        signalt=-1; if NStory>=12 && mod(Story,2)==0; signalt=1;  end
        for Axis=1:NBay+1
            val=round(CHECKS(Story,Axis).VALUE.Ratio_Pcolumn*100)/100;
            if val>1; color='r'; else; color=[0.24 0.42 0]; end
            text(GridX(Axis)+signalt*1.5*Column_Data.d(Story,Axis),  GridY(Fi)+0.3*HStory(Story), num2str(val), 'Rotation',90, 'fontsize',max(8,(labelsize+1)*4/NStory), 'Color', color);
        end
    end

    title('Column Axial Capacity', 'Color', 'b');

elseif labelflag==4

    % PMcolumn check
    for Story=1:NStory
        Fi=Story; Fj=Story+1; Fjb=min(NStory,Story+1);
        signalt=-1; if NStory>=12 && mod(Story,2)==0; signalt=1;  end
        for Axis=1:NBay+1
            val=round(CHECKS(Story,Axis).VALUE.Ratio_PMcolumn*100)/100;
            if val>1; color='r'; else; color=[0.24 0.42 0]; end
            text(GridX(Axis)+signalt*1.5*Column_Data.d(Story,Axis),  GridY(Fi)+0.3*HStory(Story), num2str(val), 'Rotation',90, 'fontsize',max(8,(labelsize+1)*4/NStory), 'Color', color);
        end
    end

    title('Column P-M Check', 'Color', 'b');

    if PMoption == 0; set(gca, 'Color', [0.8 0.8 0.8]); end
    
elseif labelflag==5

    % Column L/ry
    for Story=1:NStory
        for Axis=1:NBay+1
            Fi=Story; Fj=Story+1; Fjb=min(NStory,Story+1);
            signalt=-1; if NStory>=12 && mod(Story,2)==0; signalt=1;  end
            val1=round(CHECKS(Story,Axis).VALUE.Lry);
            val2=round(CHECKS(Story,Axis).VALUE.Ratio_Lry*100)/100;
            str2=strcat("(",num2str(val2),")");
            if val2>1; color='r'; else; color=[0.24 0.42 0]; end
            text(GridX(Axis)+signalt*1.5*Column_Data.d(Story,Axis),  GridY(Fi)+0.35*HStory(Story), num2str(val1), 'Rotation',90, 'fontsize',max(7,labelsize*4/NStory), 'Color', 'k');
            text(GridX(Axis)-signalt*1.5*Column_Data.d(Story,Axis),  GridY(Fi)+0.35*HStory(Story), str2, 'Rotation',90, 'fontsize',max(7,labelsize*4/NStory), 'Color', color);
        end
    end

    title('Column \itL\rm/\itr\rmy Check', 'Color', 'b');

    if ConnectionBracing == 1; set(gca, 'Color', [0.8 0.8 0.8]); end

elseif labelflag==6

    % Column ductility
    for Story=1:NStory
        for Axis=1:NBay+1
            Fi=Story; Fj=Story+1; Fjb=min(NStory,Story+1);
            signalt=-1; if NStory>=12 && mod(Story,2)==0; signalt=1;  end
            val =      CHECKS(Story,Axis).LOGIC.Class_Column;
            val2=round(CHECKS(Story,Axis).VALUE.Column_htw*10)/10;
            val3=round(CHECKS(Story,Axis).VALUE.Column_bftf*10)/10;
            val4=round(CHECKS(Story,Axis).VALUE.Ratio_Column_htw*10)/10;
            val5=round(CHECKS(Story,Axis).VALUE.Ratio_Column_bftf*10)/10;
            str1=strcat("(",num2str(val2),",",num2str(val3),")");
            str2=strcat("(",num2str(val4),",",num2str(val5),")");
            if val==0; color='r'; else; color=[0.24 0.42 0]; end
            text(GridX(Axis)+signalt*1.5*Column_Data.d(Story,Axis),  GridY(Fi)+0.2*HStory(Story), str1, 'Rotation',90, 'fontsize',max(7,labelsize*4/NStory), 'Color', 'k');
            text(GridX(Axis)-signalt*1.5*Column_Data.d(Story,Axis),  GridY(Fi)+0.2*HStory(Story), str2, 'Rotation',90, 'fontsize',max(7,labelsize*4/NStory), 'Color', color);
        end
    end
    
    % Beam ductility
    for Floor=2:NStory+1
        for Bay=1:NBay
            Axisi=Bay; Axisj=Bay+1;
            val =      CHECKS(Floor-1,Bay).LOGIC.Class_Beam;
            val2=round(CHECKS(Floor-1,Bay).VALUE.Beam_htw*10)/10;
            val3=round(CHECKS(Floor-1,Bay).VALUE.Beam_bftf*10)/10;
            val4=round(CHECKS(Floor-1,Bay).VALUE.Ratio_Beam_htw*10)/10;
            val5=round(CHECKS(Floor-1,Bay).VALUE.Ratio_Beam_bftf*10)/10;
            str1=strcat("(",num2str(val2),",",num2str(val3),")");
            str2=strcat("(",num2str(val4),",",num2str(val5),")");
            if val==0; color='r'; else; color=[0.24 0.42 0]; end
            text(GridX(Axisi)+0.35*WBay(Bay,1),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), str1, 'fontsize', labelsize, 'Color', 'k');
            text(GridX(Axisi)+0.35*WBay(Bay,1),  GridY(Floor)-Beam_Data.d(Floor-1,Bay), str2, 'fontsize', labelsize, 'Color', color);
        end
    end
    drawnow;

    title('Ductility Check', 'Color', 'b');

elseif labelflag==7 && MFconnection==0
    
    % Mr beam RBS check
    for Floor=2:NStory+1
        for Bay=1:NBay
            Axisi=Bay; Axisj=Bay+1;
            val=round(CHECKS(Floor-1,Axisj).VALUE.Ratio_MbeamRBS*100)/100;
            if val>1; color='r'; else; color=[0.24 0.42 0]; end
            text(GridX(Axisi)+0.35*WBay(Bay,1),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
        end
    end

    title('Beam Flexure Capacity at RBS', 'Color', 'b');

elseif labelflag==8
    
    % Mr beam check
    for Floor=2:NStory+1
        for Bay=1:NBay
            Axisi=Bay; Axisj=Bay+1;
            if MFconnection==0; val=round(CHECKS(Floor-1,Axisj).VALUE.Ratio_Mbeam*100)/100; end
            if MFconnection~=0; val=round(CHECKS(Floor-1,Axisj).VALUE.Ratio_MbeamRBS*100)/100; end
            if val>1; color='r'; else; color=[0.24 0.42 0]; end
            text(GridX(Axisi)+0.35*WBay(Bay,1),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
        end
    end

    if MFconnection==1
        title('Beam Flexure Capacity at Column Face', 'Color', 'b');
    else
        title('Beam Flexure Capacity', 'Color', 'b');
    end

elseif labelflag==9

    % Vr beam check
    for Floor=2:NStory+1
        for Bay=1:NBay
            Axisi=Bay; Axisj=Bay+1;
            val=round(CHECKS(Floor-1,Axisj).VALUE.Ratio_Vbeam*100)/100;
            if val>1; color='r'; else; color=[0.24 0.42 0]; end
            text(GridX(Axisi)+0.35*WBay(Bay,1),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
        end
    end

    title('Beam Shear Capacity', 'Color', 'b');

elseif labelflag==10

    % Panel Zone Shear
    for Floor=2:NStory+1
        for Axis=1:NBay+1
            val=round(CHECKS(Floor-1,Axis).VALUE.Ratio_PZshear*100)/100;
            if val>1; color='r'; else; color=[0.24 0.42 0]; end
            text(GridX(Axis)-3*Column_Data.d(Floor-1,Axis),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
        end
    end
        
    title('Panel Zone Shear', 'Color', 'b');

elseif labelflag==11

    % Drift & Stability Check
    for Floor=2:NStory+1
        if mod(NBay,2)~=0; Bay=ceil(NBay/2); else Bay=floor(NBay/2); end
        Axisi=Bay;
        val1 =  SDR_MF(Floor-1,1)*Cd/Ie;
        val2 =  stability_coeff(Floor-1,1);
        if val1>SDR_limit; color='r'; else; color=[0.24 0.42 0]; end
        text(GridX(Axisi)+0.30*WBay(Bay,1),  (GridY(Floor)+GridY(Floor-1))/2, strcat(num2str(round(val1*10000)/100),"%"), 'fontsize', labelsize, 'Color', color);
        text(GridX(Axisi)+0.10*WBay(Bay,1),  (GridY(Floor)+GridY(Floor-1))/2-1.5*Beam_Data.d(Floor-1,Bay), strcat("(\theta=",num2str(round(val2*1000)/1000),")"), 'fontsize', labelsize, 'Color', color);
    end

    drawnow;

    title('Drift & Stability Check', 'Color', 'b');


elseif labelflag==12

    [Vcapacity] = compute_MRF_shear_capacity ();

    % Demand vs Capacity Shear Force
    NormVal=Ws_MF;
    grid on; hold on; box on;
    plot(Vx/NormVal,Height,'--or','LineWidth',1.5)
    plot(Vcapacity/NormVal,Height,'--ob','LineWidth',1.5)
    xlabel('\itV\rm_x / \itW\rm_s')
    ylabel('Elevation')
    ylim([0 HBuilding]);
    xlim([0 max(Vcapacity)/NormVal*1.1]);
    set(gca,'YTick',Height);
    set(gca,'YTickLabel',YTickLabel);
    set(gca, 'fontname', 'times', 'fontsize',12);

    drawnow;

    title('Demand vs Capacity Shear Force', 'Color', 'b');

end

set(gca, 'fontname', 'times', 'fontsize',fontsize);