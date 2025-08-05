function plot_BMD (app, Ti, dispfloor, FType, scale, fontsize)

global  ProjectName ProjectPath Column_Data Beam_Data
load(strcat(ProjectPath,ProjectName))

DataColIndx=FType;
if DataColIndx ==3
    conv_factor=1/1000;
else
    conv_factor=1;
end

%%
if GFX==1; xx=2; else; xx=0; end

count=1;
Val=zeros(NStory*2,NBay+1+xx);
RootName = 'ColSpring';
for Fi = 1:NStory+1
    Story=max(NStory,Fi-1);

    for Axis = 1:NBay+1+xx

        if Fi==1

            Sub_RootName = 'T';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            Val(Fi,Axis)=RESULTS.(char(F_Data))(Ti,DataColIndx)*conv_factor;

        elseif  Fi==NStory+1

            Sub_RootName = 'B';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            Val(NStory*2,Axis)=RESULTS.(char(F_Data))(Ti,DataColIndx)*conv_factor;

        else

            Sub_RootName = 'B';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            Val(count+1,Axis)=RESULTS.(char(F_Data))(Ti,DataColIndx)*conv_factor;

            Sub_RootName = 'T';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            Val(count+2,Axis)=RESULTS.(char(F_Data))(Ti,DataColIndx)*conv_factor;

        end

    end
    if Fi >1
        count=count+2;
    end
end

Val_col=Val;


%%
Val=zeros(NStory, NBay*2);
RootName = 'BeamSpring';
for Fi = 2:NStory+1
    Story=Fi-1;
    count=1;
    for Axis = 1:NBay+1
        Bayi = max(1,Axis-1); Bayj = min(NBay,Axis+1);

        if Axis==NBay+1

            Sub_RootName = 'L';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            Val(Story,NBay*2)=RESULTS.(char(F_Data))(Ti,DataColIndx)*conv_factor;

        elseif  Axis==1

            Sub_RootName = 'R';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            Val(Story,1)=RESULTS.(char(F_Data))(Ti,DataColIndx)*conv_factor;

        else

            Sub_RootName = 'L';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            Val(Story,count+1)=RESULTS.(char(F_Data))(Ti,DataColIndx)*conv_factor;

            Sub_RootName = 'R';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            Val(Story,count+2)=RESULTS.(char(F_Data))(Ti,DataColIndx)*conv_factor;

        end
        if Axis >1
            count=count+2;
        end
    end
end

Val_beam=Val;



%%
Val=zeros(NStory,2);
RootName = 'EGFconnection';
for Fi = 2:NStory+1

    if GFX==1 && Recorders.EGFconnection==1
        Sub_RootName = 'R';
        evalc(['F_Data=','''',RootName,num2str(Fi),num2str(NBay+2),Sub_RootName,'_F','''']);
        Val(Fi-1,1)=RESULTS.(char(F_Data))(Ti,DataColIndx)*conv_factor;

        Sub_RootName = 'L';
        evalc(['F_Data=','''',RootName,num2str(Fi),num2str(NBay+3),Sub_RootName,'_F','''']);
        Val(Fi-1,2)=RESULTS.(char(F_Data))(Ti,DataColIndx)*conv_factor;

    end

end

Val_egf=Val;


%% Plot

maxVal = max([max(max(abs(Val_col))) max(max(abs(Val_beam))) max(max(abs(Val_egf)))]);

normVal = Val_col./ maxVal *0.1*HStory(1)*scale;
count=0;
for Si = 1:NStory
    for Axis = 1:NBay+1+xx

        X=[GridX(Axis)+dispfloor(Si) GridX(Axis)+dispfloor(Si)+normVal(count+1,Axis)    GridX(Axis)+dispfloor(Si+1)+normVal(count+2,Axis)   GridX(Axis)+dispfloor(Si+1)];
        Y=[GridY(Si)   GridY(Si)                            GridY(Si+1)                         GridY(Si+1)];

        patch(app.axes1,X, Y,'r','FaceAlpha',0.2,'LineWidth',0.5,'EdgeColor','r');
        text(app.axes1,GridX(Axis)+dispfloor(Si)  +1.02*normVal(count+1,Axis), 1.05*GridY(Si),  num2str(round(Val_col(count+1,Axis))),'Fontsize',fontsize,'Color','r');
        text(app.axes1,GridX(Axis)+dispfloor(Si+1)+0.95*normVal(count+2,Axis), 0.95*GridY(Si+1),num2str(round(Val_col(count+2,Axis))),'Fontsize',fontsize,'Color','r');
    end
    count=count+2;
end


normVal = Val_beam./ maxVal *0.1*HStory(1)*scale;
for Fi = 2:NStory+1
    Story=Fi-1;
    count=0;
    for Bay = 1:NBay

        X=[GridX(Bay)   GridX(Bay)                          GridX(Bay+1)                     GridX(Bay+1)]+dispfloor(Fi);
        Y=[GridY(Fi)    GridY(Fi)+normVal(Story,count+1)    GridY(Fi)+normVal(Story,count+2)   GridY(Fi)];

        patch(app.axes1,X, Y,'b','FaceAlpha',0.2,'LineWidth',0.5,'EdgeColor','b');
        text(app.axes1,1.05*GridX(Bay)+dispfloor(Fi)  , GridY(Fi)+1.05*normVal(Story,count+1),num2str(round(Val_beam(Story,count+1))),'Fontsize',fontsize,'Color','b');
        text(app.axes1,0.90*GridX(Bay+1)+dispfloor(Fi), GridY(Fi)+1.05*normVal(Story,count+2),num2str(round(Val_beam(Story,count+2))),'Fontsize',fontsize,'Color','b');

        count=count+2;

    end
end

normVal = Val_egf./ maxVal *0.1*HStory(1)*scale;
for Fi = 2:NStory+1
    Story=Fi-1;

    X=[GridX(NBay+2)   GridX(NBay+2)                 GridX(NBay+3)                GridX(NBay+3)]+dispfloor(Fi);
    Y=[GridY(Fi)       GridY(Fi)+normVal(Story,1)    GridY(Fi)+normVal(Story,2)   GridY(Fi)];

    patch(app.axes1,X, Y,'b','FaceAlpha',0.2,'LineWidth',0.5,'EdgeColor','b');
    text(app.axes1,1.02*GridX(NBay+2)+dispfloor(Fi), GridY(Fi)+1.03*normVal(Story,1),num2str(round(Val_egf(Story,1))),'Fontsize',fontsize,'Color','b');
    text(app.axes1,0.95*GridX(NBay+3)+dispfloor(Fi), GridY(Fi)+1.03*normVal(Story,2),num2str(round(Val_egf(Story,2))),'Fontsize',fontsize,'Color','b');

end

%%
drawnow