function highlight_component (app, Element, SpringLoc, Story, Floor, Axis, Bay)

global  ProjectName ProjectPath 

load(strcat(ProjectPath,ProjectName), 'FrameType', 'NStory', 'NBay', 'GridX', 'GridY','Column_Data','Beam_Data','Brace_Data');

Fi = Story; Fj = Story+1;
Bayi = max(1,Axis-1); Bayj = Axis;


if strcmp(Element,'Column Spring')==1
    if SpringLoc==2
        scatter(app.axes1,GridX(Axis) , GridY(Floor)-Beam_Data.d(Floor,1)/2,'or','Markerfacecolor','y');
    elseif  SpringLoc==1 && Floor==NStory+1
        scatter(app.axes1,GridX(Axis) , GridY(Floor)-Beam_Data.d(Floor,1)/2,'or','Markerfacecolor','y');
    else
        scatter(app.axes1,GridX(Axis) , GridY(Floor)+Beam_Data.d(Floor,1)/2,'or','Markerfacecolor','y');
    end
elseif strcmp(Element,'Beam Spring')==1
    if SpringLoc==2
        scatter(app.axes1,GridX(Axis)+Column_Data.d(Story,Axis)/2+Beam_Data.LRBS(Floor+1,Bayj), GridY(Floor+1),'or','Markerfacecolor','y');
    elseif  SpringLoc==1 && Axis==1
        scatter(app.axes1,GridX(Axis)+Column_Data.d(Story,Axis)/2+Beam_Data.LRBS(Floor+1,Bayj), GridY(Floor+1),'or','Markerfacecolor','y');
    else
        scatter(app.axes1,GridX(Axis)-Column_Data.d(Story,Axis)/2-Beam_Data.LRBS(Floor+1,Bayi), GridY(Floor+1),'or','Markerfacecolor','y');
    end
elseif strcmp(Element,'Panel Zone Spring')==1
    scatter(app.axes1,GridX(Axis)+Column_Data.d(Story,Axis)/2, GridY(Floor+1)+Beam_Data.d(Floor+1,Bayi)/2,'or','Markerfacecolor','y');
end

if strcmp(Element,'Column Elastic Element')==1
    plot(app.axes1,[GridX(Axis) GridX(Axis)] , [GridY(Fj)-Beam_Data.d(Fj,Bayi)/2 GridY(Fi)+Beam_Data.d(Fi,Bayi)/2],'-r','Linewidth',2);
    if SpringLoc==1
        scatter(app.axes1,GridX(Axis) , GridY(Fj)-Beam_Data.d(Fj,Bayi)/2 , 'or','Markerfacecolor','y');
    else
        scatter(app.axes1,GridX(Axis) , GridY(Fi), 'or','Markerfacecolor','y');
    end
elseif strcmp(Element,'Beam Elastic Element')==1
    Axisi=Bay; Axisj=Bay+1;
    plot(app.axes1,[GridX(Axisi)+Column_Data.d(Story,Axisi)/2+Beam_Data.LRBS(Floor+1,Bay) GridX(Axisj)-Column_Data.d(Story,Axisj)/2-Beam_Data.LRBS(Floor+1,Bay)] , [GridY(Floor+1) GridY(Floor+1)],'-r','Linewidth',2);
    if SpringLoc==1
        scatter(app.axes1,GridX(Axisi)+Column_Data.d(Story,Axisi)/2+Beam_Data.LRBS(Floor+1,Bay) , GridY(Floor+1),'or','Markerfacecolor','y');
    else
        scatter(app.axes1,GridX(Axisj)-Column_Data.d(Story,Axisj)/2-Beam_Data.LRBS(Floor+1,Bay) , GridY(Floor+1),'or','Markerfacecolor','y');
    end
elseif strcmp(Element,'EGF Connection')==1
    scatter(app.axes1,GridX(NBay+1+Axis), GridY(Floor+1),'or','Markerfacecolor','y');
elseif strcmp(Element,'Floor Link')==1
    plot(app.axes1,[GridX(NBay+1)+Column_Data.d(Story,NBay+1)/2 GridX(NBay+2)],[GridY(Floor+1) GridY(Floor+1)],'-or','linewidth',1.5,'Markerfacecolor','k','MarkerSize',3);
end

if FrameType==2
    if strcmp(Element,'Brace')==1
        Axis=1;
        if BraceLayout==1
            if rem(Story,2)~=0
                if SpringLoc==1
                    plot(app.axes1,[ GridX(Axis)    (GridX(Axis)+GridX(Axis+1))/2],[GridY(Fi) GridY(Fj)],'-r','linewidth',2);
                else
                    plot(app.axes1,[ GridX(Axis+1)  (GridX(Axis)+GridX(Axis+1))/2],[GridY(Fi) GridY(Fj)],'-r','linewidth',2);
                end
            else
                if SpringLoc==1
                    plot(app.axes1,[(GridX(Axis)+GridX(Axis+1))/2 GridX(Axis)]  ,[GridY(Fi) GridY(Fj)],'-r','linewidth',2);
                else
                    plot(app.axes1,[(GridX(Axis)+GridX(Axis+1))/2 GridX(Axis+1)],[GridY(Fi) GridY(Fj)],'-r','linewidth',2);
                end
            end
        else
            if SpringLoc==1
                plot(app.axes1,[ GridX(Axis)    (GridX(Axis)+GridX(Axis+1))/2],[GridY(Fi) GridY(Fj)],'-r','linewidth',2);
            else
                plot(app.axes1,[ GridX(Axis+1)  (GridX(Axis)+GridX(Axis+1))/2],[GridY(Fi) GridY(Fj)],'-r','linewidth',2);
            end
        end
    end
end

drawnow