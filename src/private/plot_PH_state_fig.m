function plot_PH_state_fig (Ti, dispfloor)

global  ProjectName ProjectPath Column_Data Beam_Data
load(strcat(ProjectPath,ProjectName))

DataColIndx=3;
convfactor=1/1000;

%%
RootName = 'ColSpring';
for Fi = 1:NStory+1
    Story=max(NStory,Fi-1);

    for Axis = 1:NBay+1
        Bayi = max(1,Axis-1); Bayj = Axis;

        if Fi==1
            Sub_RootName = 'T';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(:,3)*100;
            Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

            slope=abs(diff((Y))./diff((X)));
            indxP= min(find(slope(~isinf(slope))<0.2*max(slope(~isinf(slope)))));
            [maxF,indxmaxF]=max(abs(Y));
            if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  abs(Y(indxmaxF+1))<abs(Y(indxmaxF)); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
            %indxC= min(find(slope(~isinf(slope))<0));
            if isempty(indxP); indxP=length(Y); end
            if isempty(indxC); indxC=length(Y);     end

            if Ti < indxP
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif Ti >= indxP &&  Ti < indxC
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif Ti > indxC
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

        elseif  Fi==NStory+1
            Sub_RootName = 'B';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(:,3)*100;
            Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

            slope=abs(diff((Y))./diff((X)));
            indxP= min(find(slope(~isinf(slope))<0.2*max(slope(~isinf(slope)))));
            [maxF,indxmaxF]=max(abs(Y));
            if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  abs(Y(indxmaxF+1))<abs(Y(indxmaxF)); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
            %indxC= min(find(slope(~isinf(slope))<0));
            if isempty(indxP); indxP=length(Y); end
            if isempty(indxC); indxC=length(Y);     end

            if Ti < indxP
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)-Beam_Data.d(Fi,1),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif Ti >= indxP &&  Ti < indxC
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)-Beam_Data.d(Fi,1),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif Ti > indxC
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)-Beam_Data.d(Fi,1),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end
        else
            Sub_RootName = 'T';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(:,3)*100;
            Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

            slope=abs(diff((Y))./diff((X)));
            indxP= min(find(slope(~isinf(slope))<0.2*max(slope(~isinf(slope)))));
            [maxF,indxmaxF]=max(abs(Y));
            if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  abs(Y(indxmaxF+1))<abs(Y(indxmaxF)); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
            %indxC= min(find(slope(~isinf(slope))<0));
            if isempty(indxP); indxP=length(Y); end
            if isempty(indxC); indxC=length(Y);     end

            if Ti < indxP
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,1),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif Ti >= indxP &&  Ti < indxC
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,1),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif Ti > indxC
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,1),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

            Sub_RootName = 'B';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(:,3)*100;
            Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

            slope=abs(diff((Y))./diff((X)));
            indxP= min(find(slope(~isinf(slope))<0.2*max(slope(~isinf(slope)))));
            [maxF,indxmaxF]=max(abs(Y));
            if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  abs(Y(indxmaxF+1))<abs(Y(indxmaxF)); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
            %indxC= min(find(slope(~isinf(slope))<0));
            if isempty(indxP); indxP=length(Y); end
            if isempty(indxC); indxC=length(Y);     end

            if Ti < indxP
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)-Beam_Data.d(Fi,1),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif Ti >= indxP &&  Ti < indxC
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)-Beam_Data.d(Fi,1),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif Ti > indxC
                plot(GridX(Axis)+dispfloor(Fi), GridY(Fi)-Beam_Data.d(Fi,1),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

        end

    end
end

%%
RootName = 'BeamSpring';
for Fi = 2:NStory+1
    Story=Fi-1;
    for Axis = 1:NBay+1
        Bayi = max(1,Axis-1); Bayj = min(NBay,Axis+1);

        if Axis==NBay+1

            Sub_RootName = 'L';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(:,3)*100;
            Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

            slope=abs(diff((Y))./diff((X)));
            indxP= min(find(slope(~isinf(slope))<0.2*max(slope(~isinf(slope)))));
            [maxF,indxmaxF]=max(abs(Y));
            if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  abs(Y(indxmaxF+1))<abs(Y(indxmaxF)); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
            %indxC= min(find(slope(~isinf(slope))<0));
            if isempty(indxP); indxP=length(Y); end
            if isempty(indxC); indxC=length(Y);     end


            if Ti < indxP
                plot(GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif Ti >= indxP &&  Ti < indxC
                plot(GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif Ti > indxC
                plot(GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

        elseif  Axis==1

            Sub_RootName = 'R';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(:,3)*100;
            Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

            slope=abs(diff((Y))./diff((X)));
            indxP= min(find(slope(~isinf(slope))<0.2*max(slope(~isinf(slope)))));
            [maxF,indxmaxF]=max(abs(Y));
            if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  abs(Y(indxmaxF+1))<abs(Y(indxmaxF)); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
            %indxC= min(find(slope(~isinf(slope))<0));
            if isempty(indxP); indxP=length(Y); end
            if isempty(indxC); indxC=length(Y);     end


            if Ti < indxP
                plot(GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif Ti >= indxP &&  Ti < indxC
                plot(GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif Ti > indxC
                plot(GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

        else

            Sub_RootName = 'L';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(:,3)*100;
            Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

            slope=abs(diff((Y))./diff((X)));
            indxP= min(find(slope(~isinf(slope))<0.2*max(slope(~isinf(slope)))));
            [maxF,indxmaxF]=max(abs(Y));
            if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  abs(Y(indxmaxF+1))<abs(Y(indxmaxF)); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
            %indxC= min(find(slope(~isinf(slope))<0));
            if isempty(indxP); indxP=length(Y); end
            if isempty(indxC); indxC=length(Y);     end


            if Ti < indxP
                plot(GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif Ti >= indxP &&  Ti < indxC
                plot(GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif Ti > indxC
                plot(GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

            Sub_RootName = 'R';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(:,3)*100;
            Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

            slope=abs(diff((Y))./diff((X)));
            indxP= min(find(slope(~isinf(slope))<0.2*max(slope(~isinf(slope)))));
            [maxF,indxmaxF]=max(abs(Y));
            if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  abs(Y(indxmaxF+1))<abs(Y(indxmaxF)); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
            %indxC= min(find(slope(~isinf(slope))<0));
            if isempty(indxP); indxP=length(Y); end
            if isempty(indxC); indxC=length(Y);     end


            if Ti < indxP
                plot(GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif Ti >= indxP &&  Ti < indxC
                plot(GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif Ti > indxC
                plot(GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end
        end
    end
end

%%
RootName = 'PZ';
for Fi = 2:NStory+1
    if Recorders.PZ==1
        Story=max(NStory,Fi-1);
        for Axis = 1:NBay+1
            Bayi = max(1,Axis-1); Bayj = Axis;

            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),'_D','''']);
            X=RESULTS.(char(D_Data))(:,1)*100;
            Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

            slope=abs(diff((Y))./diff((X)));
            indxP= min(find(slope(~isinf(slope))<0.5*max(slope(~isinf(slope)))));
            [maxF,indxmaxF]=max(abs(Y));
            if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  Y(indxmaxF+1)<Y(indxmaxF); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
            %indxC= min(find(slope(~isinf(slope))<0));
            if isempty(indxP); indxP=length(Y); end
            if isempty(indxC); indxC=length(Y);     end

            if Ti < indxP
                plot(GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,Bayi)/2,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif Ti >= indxP &&  Ti < indxC
                plot(GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,Bayi)/2,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif Ti > indxC
                plot(GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,Bayi)/2,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end
        end
    else
        plot(GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,Bayi)/2,'o','Markeredgecolor',[0 0 0],'Markerfacecolor',[0.6 0.6 0.6],'MarkerSize',5);
    end
end


%%
RootName = 'EGFconnection';
for Fi = 2:NStory+1

    if GFX==1 && Recorders.EGFconnection==1
        Sub_RootName = 'R';
        evalc(['F_Data=','''',RootName,num2str(Fi),num2str(NBay+2),Sub_RootName,'_F','''']);
        evalc(['D_Data=','''',RootName,num2str(Fi),num2str(NBay+2),Sub_RootName,'_D','''']);
        X=RESULTS.(char(D_Data))(:,3)*100;
        Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

        slope=abs(diff((Y))./diff((X)));
        indxP= min(find(slope(~isinf(slope))<0.2*max(slope(~isinf(slope)))));
        [maxF,indxmaxF]=max(abs(Y));
        if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  Y(indxmaxF+1)<Y(indxmaxF); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
        %indxC= min(find(slope(~isinf(slope))<0));
        if isempty(indxP); indxP=length(Y); end
        if isempty(indxC); indxC=length(Y);     end

        if Ti < indxP
            plot(GridX(NBay+2)+0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
        elseif Ti >= indxP &&  Ti < indxC
            plot(GridX(NBay+2)+0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
        elseif Ti > indxC
            plot(GridX(NBay+2)+0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
        end


        Sub_RootName = 'L';
        evalc(['F_Data=','''',RootName,num2str(Fi),num2str(NBay+3),Sub_RootName,'_F','''']);
        evalc(['D_Data=','''',RootName,num2str(Fi),num2str(NBay+3),Sub_RootName,'_D','''']);
        X=RESULTS.(char(D_Data))(:,3)*100;
        Y=RESULTS.(char(F_Data))(:,DataColIndx)*convfactor;

        slope=abs(diff((Y))./diff((X)));
        indxP= min(find(slope(~isinf(slope))<0.2*max(slope(~isinf(slope)))));
        [maxF,indxmaxF]=max(abs(Y));
        if indxmaxF~=length(Y); if abs(X(indxmaxF+1))>abs(X(indxmaxF)) &&  Y(indxmaxF+1)<Y(indxmaxF); indxC=indxmaxF; else; indxC=length(Y);     end; else; indxC=length(Y);     end
        %indxC= min(find(slope(~isinf(slope))<0));
        if isempty(indxP); indxP=length(Y); end
        if isempty(indxC); indxC=length(Y);     end

        if Ti < indxP
            plot(GridX(NBay+3)-0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
        elseif Ti >= indxP &&  Ti < indxC
            plot(GridX(NBay+3)-0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
        elseif Ti > indxC
            plot(GridX(NBay+3)-0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
        end
    else
        plot(GridX(NBay+2)+0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0 0 0],'Markerfacecolor',[0.6 0.6 0.6],'MarkerSize',5);
        plot(GridX(NBay+3)-0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0 0 0],'Markerfacecolor',[0.6 0.6 0.6],'MarkerSize',5);

    end

end

%%
drawnow