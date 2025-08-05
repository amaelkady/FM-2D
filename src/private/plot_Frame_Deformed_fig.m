function [h]=plot_Frame_Deformed_fig(dispfloor, maxDisp)
global ProjectName ProjectPath
clc;
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

if FrameType==2
    Section=BRACES{1,1};
    [SecData]=Load_SecData (Section, Units);
    for Story=1:NStory
        for Bay=1:NBay
            Brace_Data.Py(Story,Bay)=SecData.Area(Brace_Index(Story,Bay))*fyBrace;
        end
    end
end

h=figure('position',[100 100 400 550],'color','white');
grid on; hold on; box on;
hold("on");
xlim([0.0-0.5*WBay(1)-maxDisp   GridX(end)+0.5*WBay(1)+maxDisp]);
ylim([0.0-0.2*HStory(1) HBuilding+0.2*HStory(1)]);
yticks(Elevation);
set(gca, 'YTickLabel', YTickLabel);
xticks(AXIS);
set(gca, 'XTickLabel', XTickLabel);
ylabel([]);
xlabel('Axis');
set(gca,GridLineStyle='-.');
set(gca,'GridColor',[0.0 0.0 0.0]);

% Plot Column Elements
for Story=1:NStory
    Fi=Story; Fj=Story+1; Fjb=min(NStory,Story+1);
    for Axis=1:NBay+1
        plot([GridX(Axis)+dispfloor(Fi) GridX(Axis)+dispfloor(Fj)],[GridY(Fi)+Beam_Data.d(Fi,1)/2 GridY(Fj)-Beam_Data.d(Fjb,1)/2],'-k');
    end
end
drawnow;

% Plot Splice Points
for Story=1:NStory
    if Splice(Story,1)
        Fi=Story;
        dispfloorsplice=(dispfloor(Fi)+dispfloor(Fi+1))/2;
        for Axis=1:NBay+3
            if SpliceConnection==1; plot([GridX(Axis)+dispfloorsplice],[GridY(Fi)+HStory(Story,1)*Splice(Story,2)],'ok','MarkerSize',3); end
            if SpliceConnection==2; plot([GridX(Axis)+dispfloorsplice],[GridY(Fi)+HStory(Story,1)*Splice(Story,2)],'k','Marker','square','MarkerSize',3); end
        end
    end
end
drawnow;

% Plot Beam Elements
for Floor=2:NStory+1
    Story=Floor-1;
    for Bay=1:NBay
        Axisi=Bay; Axisj=Bay+1;
        plot([GridX(Axisi)+Column_Data.d(Story,Axisi)/2+dispfloor(Floor) GridX(Axisj)-Column_Data.d(Story,Axisj)/2+dispfloor(Floor)],  [GridY(Floor) GridY(Floor)],'-k');
    end
end
drawnow;

% Plot PZ Elements
for Floor=2:NStory+1
    Story=Floor-1;
    Fi=Floor-1;
    for Axis=1:NBay+1
        Bay=min(Axis, NBay);
        plot([GridX(Axis)-Column_Data.d(Story,Axis)/2+dispfloor(Floor) GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Floor)],[GridY(Floor)+Beam_Data.d(Fi,Bay)/2 GridY(Floor)+Beam_Data.d(Fi,Bay)/2],'-k');  % top horizontal element
        plot([GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Floor) GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Floor)],[GridY(Floor)+Beam_Data.d(Fi,Bay)/2 GridY(Floor)-Beam_Data.d(Fi,Bay)/2],'-k');  % right vertical element
        plot([GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Floor) GridX(Axis)-Column_Data.d(Story,Axis)/2+dispfloor(Floor)],[GridY(Floor)-Beam_Data.d(Fi,Bay)/2 GridY(Floor)-Beam_Data.d(Fi,Bay)/2],'-k');  % bottom horizontal element
        plot([GridX(Axis)-Column_Data.d(Story,Axis)/2+dispfloor(Floor) GridX(Axis)-Column_Data.d(Story,Axis)/2+dispfloor(Floor)],[GridY(Floor)-Beam_Data.d(Fi,Bay)/2 GridY(Floor)+Beam_Data.d(Fi,Bay)/2],'-k');  % left vertical element
    end
end
drawnow;

% Plot GF Column Elements
for Story=1:NStory
    Fi=Story; Fj=Story+1;
    Axis=NBay+2;
    plot([GridX(Axis)+dispfloor(Fi) GridX(Axis)+dispfloor(Fj)],[GridY(Fi) GridY(Fj)],'-k');
    Axis=NBay+3;
    plot([GridX(Axis)+dispfloor(Fi) GridX(Axis)+dispfloor(Fj)],[GridY(Fi) GridY(Fj)],'-k');
end
drawnow;

% Plot Rigid Links Elements
for Floor=2:NStory+1
    Story=Floor-1;
    Axisi=NBay+1; Axisj=NBay+2;
    plot([GridX(Axisi)+Column_Data.d(Story,Axisi)/2+dispfloor(Floor) GridX(Axisj)+dispfloor(Floor)],[GridY(Floor) GridY(Floor)],'-ok','linewidth',1.5,'Markerfacecolor','k','MarkerSize',3);
end
drawnow;

% Plot GF Beam Elements
for Floor=2:NStory+1
    Axisi=NBay+2; Axisj=NBay+3;
    plot([GridX(Axisi)+dispfloor(Floor) GridX(Axisj)+dispfloor(Floor)],[GridY(Floor) GridY(Floor)],'-k');
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
Axis=NBay+2;
patch([GridX(Axis) GridX(Axis)-0.2*HStory(1) GridX(Axis)+0.2*HStory(1)] , [0.0 -0.08*HStory(1) -0.08*HStory(1)],[0.5 0.5 0.5]);
Axis=NBay+3;
patch([GridX(Axis) GridX(Axis)-0.2*HStory(1) GridX(Axis)+0.2*HStory(1)] , [0.0 -0.08*HStory(1) -0.08*HStory(1)] , [0.5 0.5 0.5]);

% Plot Braces
if FrameType==2
    for Story=1:NStory
        Fi=Story; Fj=Story+1;
        Axis=1;
        if BraceLayout==1
            if rem(Story,2)~=0
                plot([ GridX(Axis)+dispfloor(Fi)    (GridX(Axis)+GridX(Axis+1))/2+dispfloor(Fj)],[GridY(Fi) GridY(Fj)],'-k');
                plot([ GridX(Axis+1)+dispfloor(Fi)  (GridX(Axis)+GridX(Axis+1))/2+dispfloor(Fj)],[GridY(Fi) GridY(Fj)],'-k');
            else
                plot([(GridX(Axis)+GridX(Axis+1))/2+dispfloor(Fi) GridX(Axis)+dispfloor(Fj)]  ,[GridY(Fi) GridY(Fj)],'-k');
                plot([(GridX(Axis)+GridX(Axis+1))/2+dispfloor(Fi) GridX(Axis+1)+dispfloor(Fj)],[GridY(Fi) GridY(Fj)],'-k');
            end
        else
            plot([ GridX(Axis)+dispfloor(Fi)    (GridX(Axis)+GridX(Axis+1))/2+dispfloor(Fj)],[GridY(Fi) GridY(Fj)],'-k');
            plot([ GridX(Axis+1)+dispfloor(Fi)  (GridX(Axis)+GridX(Axis+1))/2+dispfloor(Fj)],[GridY(Fi) GridY(Fj)],'-k');
        end
    end
end

app.axes1.FontName='Times';
app.axes1.FontSize=16;