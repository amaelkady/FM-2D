function plot_MRF_load_case_demands(fontsize, labelsize, Column, Beam, FigureName)

arguments
    fontsize  (1,1) double = 16;
    labelsize (1,1) double = 9;
    Column          struct = 1;
    Beam            struct = 1;
    FigureName      string = 'Load Case';
end

global Units

if Units==1
    unitstr     = ' Units: kN and kN.m';
    convUnit_M  = 1/1000; % from kN.mm to kN.m
else
    unitstr     = ' Units: kips and kip.ft';
    convUnit_M  = 1/12; % from kip.in to kip.ft
end


global ProjectName ProjectPath
load(strcat(ProjectPath,ProjectName))

[Column_Data, Beam_Data, Brace_Data]=Get_Member_Data(NStory, NBay, FrameType, MF_COLUMNS, MF_BEAMS, BRACES, Units, fy);

fig1=figure('position',[100 100 1000 600],'color','white', 'Name',strcat (FigureName,unitstr),'NumberTitle','off');

for Story=1:NStory
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,Axis};
        [SecData]=Load_SecData (Section, Units);
        idx=min(find(contains(SecData.Name,Section)));
        Column_Data.d(Story,Axis)=SecData.d(idx);
    end
end


for Floor=2:NStory+1
    Fi=Floor-1;
    for Bay=1:NBay
        Section=MF_BEAMS{Fi,Bay};
        [SecData]=Load_SecData (Section, Units);
        idx=min(find(contains(SecData.Name,Section)));
        Beam_Data.d(Fi,Bay)=SecData.d(idx);
    end
end

% --------------------------------------------------------------------------------------------------------
% --------------------------------------------------------------------------------------------------------
% Demands
% --------------------------------------------------------------------------------------------------------
% --------------------------------------------------------------------------------------------------------

% Column Pr
subplot(2,3,1);
plot_MRF();
title('Column Axial Load', 'Color', 'b');

for Floor=2:NStory+1
    for Axis=1:NBay+1
        color='b';
        val=round(Column.Pr(Floor-1,Axis));
        text(GridX(Axis)-3*Column_Data.d(Floor-1,Axis),  GridY(Floor-1)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
    end
end


% Column Vr
subplot(2,3,2);
plot_MRF();
title('Column Shear', 'Color', 'b');

for Floor=2:NStory+1
    Story=Floor-1;
    for Axis=1:NBay+1
        color='b';
        val=round(Column.Vr.Bottom(Floor-1,Axis));
        text(GridX(Axis)-3*Column_Data.d(Story,Axis),  GridY(Floor-1)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
        val=round(Column.Vr.Top(Floor-1,Axis));
        text(GridX(Axis)-3*Column_Data.d(Story,Axis),  GridY(Floor)  -Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
    end
end


% Column Mr
subplot(2,3,3);
plot_MRF();
title('Column Moment', 'Color', 'b');

for Floor=2:NStory+1
    Story=Floor-1;
    for Axis=1:NBay+1
        color='b';
        val=round(Column.Mr.Bottom(Floor-1,Axis)*convUnit_M);
        text(GridX(Axis)-4*Column_Data.d(Story,Axis),  GridY(Floor-1)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
        val=round(Column.Mr.Top(Floor-1,Axis)*convUnit_M);
        text(GridX(Axis)-4*Column_Data.d(Story,Axis),  GridY(Floor)  -Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
    end
end


% Vr beam RBS
subplot(2,3,4);
plot_MRF();
title('Beam Shear at RBS', 'Color', 'b');

for Floor=2:NStory+1
    Story=Floor-1;
    for Bay=1:NBay
        Axisi=Bay; Axisj=Bay+1;
        color='b';
        val=round(Beam.Vr.Left(Floor-1,Bay));
        text(GridX(Axisi)+1*Column_Data.d(Story,Axis),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
        val=round(Beam.Vr.Right(Floor-1,Bay));
        text(GridX(Axisj)-3*Column_Data.d(Story,Axis),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize+1, 'Color', color);
    end
end


% Mr beam RBS
subplot(2,3,5);
plot_MRF();
title('Beam Moment at RBS', 'Color', 'b');

for Floor=2:NStory+1
    Story=Floor-1;
    for Bay=1:NBay
        Axisi=Bay; Axisj=Bay+1;
        color='b';
        val=round(Beam.Mr.Left(Floor-1,Bay)*convUnit_M);
        text(GridX(Axisi)+1*Column_Data.d(Story,Axis),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize, 'Color', color);
        val=round(Beam.Mr.Right(Floor-1,Bay)*convUnit_M);
        text(GridX(Axisj)-3*Column_Data.d(Story,Axis),  GridY(Floor)+Beam_Data.d(Floor-1,Bay), num2str(val), 'fontsize', labelsize, 'Color', color);
    end
end



tightfig;

end

function plot_MRF()
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



grid on; hold on; box on;
xlim([0.0-0.5*WBay(1)   GridX(end-2)+0.5*WBay(1)]);
ylim([0.0-0.2*HStory(1) HBuilding+0.5*HStory(1)]);
set(gca,'YTick',Elevation);
set(gca,'YTickLabel',YTickLabel);
set(gca,'XTick',AXIS(1:end-2));
set(gca,'XTickLabel',XTickLabel);
xlabel('Axis');
set(gca,'GridLineStyle','-.');
set(gca,'GridColor',[0.0 0.0 0.0]);
set(gca, 'fontname', 'times', 'fontsize',10);

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
        for Axis=1:NBay+3
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


end