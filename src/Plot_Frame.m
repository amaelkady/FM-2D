function Plot_Frame(app)
global MainDirectory ProjectName ProjectPath
clc;
cd(ProjectPath)
load(ProjectName)
cd(MainDirectory)

a=0; b=0; c=0;

[Column_Index, Beam_Index, Brace_Index, XSecID] = Get_Section_Database_Index(FrameType, NStory, NBay, MF_COLUMNS, MF_BEAMS, BRACES, Units);
[GridX, GridY, AXIS, Elevation, HalfElevation, XTickLabel, YTickLabel] = Get_Grid (NStory, NBay,HStory, WBay);

Section=MF_COLUMNS{1,1};
[SecData]=Load_SecData (Section, Units);

for Story=1:NStory
    for Axis=1:NBay+1
        Column_Data.d(Story,Axis)=SecData.d(Column_Index(Story,Axis));
    end
end

Section=MF_BEAMS{1,1};
[SecData]=Load_SecData (Section, Units);
for Floor=2:NStory+1
    Fi=Floor-1;
    for Bay=1:NBay
        Beam_Data.d(Fi,Bay)=SecData.d(Beam_Index(Fi,Bay));
    end
end

if FrameType==2
    Section=BRACES{1,1};
    [SecData]=Load_SecData (Section, Units);
    for Story=1:NStory
        for Bay=1:NBay
            Brace_Data.Py(Story,Bay)=SecData.Area(Brace_Index(Story,Bay))*fyBrace;
        end
    end
end

app.axes1.cla;
app.axes1.Box='on';
app.axes1.XGrid='on';
app.axes1.YGrid='on';
hold(app.axes1,"on");
app.axes1.XLim=[0.0-0.5*WBay(1)   GridX(end)+0.5*WBay(1)];
app.axes1.YLim=[0.0-0.2*HStory(1) HBuilding+0.2*HStory(1)];
app.axes1.YTick=Elevation;
app.axes1.YTickLabel=YTickLabel;
app.axes1.XTick=AXIS;
app.axes1.XTickLabel=XTickLabel;
app.axes1.YLabel.String='Floor';
app.axes1.XLabel.String='Axis';
app.axes1.GridLineStyle='-.';
app.axes1.GridColor=[0.0 0.0 0.0];

% Plot Column Elements
for Story=1:NStory
    Fi=Story; Fj=Story+1; Fjb=min(NStory,Story+1);
    for Axis=1:NBay+1
        plot(app.axes1,[GridX(Axis) GridX(Axis)],[GridY(Fi)+Beam_Data.d(Fi,1)/2 GridY(Fj)-Beam_Data.d(Fjb,1)/2],'-k');
    end
end
drawnow;

% Plot Splice Points
for Story=1:NStory
    if Splice(Story,1)
        Fi=Story;
        for Axis=1:NBay+3
            if SpliceConnection==1; plot(app.axes1,[GridX(Axis) GridX(Axis)],[GridY(Fi)+HStory(Story,1)*Splice(Story,2) GridY(Fi)+HStory(Story,1)*Splice(Story,2)],'-ok','MarkerSize',3); end
            if SpliceConnection==2; plot(app.axes1,[GridX(Axis) GridX(Axis)],[GridY(Fi)+HStory(Story,1)*Splice(Story,2) GridY(Fi)+HStory(Story,1)*Splice(Story,2)],'-k','Marker','square','MarkerSize',3); end
        end
    end
end
drawnow;

% Plot Beam Elements
for Floor=2:NStory+1
    Story=Floor-1;
    for Bay=1:NBay
        Axisi=Bay; Axisj=Bay+1;
        plot(app.axes1,[GridX(Axisi)+Column_Data.d(Story,Axisi)/2 GridX(Axisj)-Column_Data.d(Story,Axisj)/2],  [GridY(Floor) GridY(Floor)],'-k');
    end
end
drawnow;

% Plot PZ Elements
for Floor=2:NStory+1
    Story=Floor-1;
    Fi=Floor-1;
    for Axis=1:NBay+1
        Bay=min(Axis, NBay);
        plot(app.axes1,[GridX(Axis)-Column_Data.d(Story,Axis)/2 GridX(Axis)+Column_Data.d(Story,Axis)/2],[GridY(Floor)+Beam_Data.d(Fi,Bay)/2 GridY(Floor)+Beam_Data.d(Fi,Bay)/2],'-k');  % top horizontal element
        plot(app.axes1,[GridX(Axis)+Column_Data.d(Story,Axis)/2 GridX(Axis)+Column_Data.d(Story,Axis)/2],[GridY(Floor)+Beam_Data.d(Fi,Bay)/2 GridY(Floor)-Beam_Data.d(Fi,Bay)/2],'-k');  % right vertical element
        plot(app.axes1,[GridX(Axis)+Column_Data.d(Story,Axis)/2 GridX(Axis)-Column_Data.d(Story,Axis)/2],[GridY(Floor)-Beam_Data.d(Fi,Bay)/2 GridY(Floor)-Beam_Data.d(Fi,Bay)/2],'-k');  % bottom horizontal element
        plot(app.axes1,[GridX(Axis)-Column_Data.d(Story,Axis)/2 GridX(Axis)-Column_Data.d(Story,Axis)/2],[GridY(Floor)-Beam_Data.d(Fi,Bay)/2 GridY(Floor)+Beam_Data.d(Fi,Bay)/2],'-k');  % left vertical element
    end
end
drawnow;

% Plot GF Column Elements
for Story=1:NStory
    Fi=Story; Fj=Story+1;
    Axis=NBay+2;
    plot(app.axes1,[GridX(Axis) GridX(Axis)],[GridY(Fi) GridY(Fj)],'-k');
    Axis=NBay+3;
    plot(app.axes1,[GridX(Axis) GridX(Axis)],[GridY(Fi) GridY(Fj)],'-k');
end
drawnow;

% Plot Rigid Links Elements
for Floor=2:NStory+1
    Story=Floor-1;
    Axisi=NBay+1; Axisj=NBay+2;
    plot(app.axes1,[GridX(Axisi)+Column_Data.d(Story,Axisi)/2 GridX(Axisj)],[GridY(Floor) GridY(Floor)],'-ok','linewidth',1.5,'Markerfacecolor','k','MarkerSize',3);
end
drawnow;

% Plot GF Beam Elements
for Floor=2:NStory+1
    Axisi=NBay+2; Axisj=NBay+3;
    plot(app.axes1,[GridX(Axisi) GridX(Axisj)],[GridY(Floor) GridY(Floor)],'-k');
end
drawnow;

% Plot Column Supports
for Axis=1:NBay+1
    rectangle(app.axes1,'Position',[GridX(Axis)-0.25*HStory(1) -0.08*HStory(1) 0.5*HStory(1) 0.08*HStory(1)],'FaceColor',[0.5 0.5 0.5]);
end
Axis=NBay+2;
patch(app.axes1,[GridX(Axis) GridX(Axis)-0.2*HStory(1) GridX(Axis)+0.2*HStory(1)] , [0.0 -0.08*HStory(1) -0.08*HStory(1)],[0.5 0.5 0.5]);
Axis=NBay+3;
patch(app.axes1,[GridX(Axis) GridX(Axis)-0.2*HStory(1) GridX(Axis)+0.2*HStory(1)] , [0.0 -0.08*HStory(1) -0.08*HStory(1)] , [0.5 0.5 0.5]);

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

app.axes1.FontName='Times';
app.axes1.FontSize=16;