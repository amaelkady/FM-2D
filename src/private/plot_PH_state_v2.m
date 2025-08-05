function plot_PH_state_v2 (app, Ti, dispfloor)

global  ProjectName ProjectPath Column_Data Beam_Data
load(strcat(ProjectPath,ProjectName))

DataColIndx=3;
convfactor=1;

%%
if GFX==1; xx=2; else; xx=0; end

RootName = 'ColSpring';
for Fi = 1:NStory+1
    Story=max(NStory,Fi-1);

    for Axis = 1:NBay+1

        if Fi==1

            Sub_RootName = 'T';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(1:Ti,3);
            Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

            [maxF,~]=max(abs(Y));
            [maxR,~]=max(abs(X));

            [Backbone] = get_backbone_Column  (E, fy, HStory, MF_COLUMNS, MF_BEAMS, Splice, NStory, NBay, Fi, Axis, Pred, Units);

            if maxF < Backbone.Mye
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif maxF >= Backbone.Mye &&  maxR < Backbone.theta_p
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif maxR >= Backbone.theta_p
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

        elseif  Fi==NStory+1

            Sub_RootName = 'B';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(1:Ti,3);
            Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

            [maxF,~]=max(abs(Y));
            [maxR,~]=max(abs(X));


            [Backbone] = get_backbone_Column  (E, fy, HStory, MF_COLUMNS, MF_BEAMS, Splice, NStory, NBay, Fi, Axis, Pred, Units);

            if maxF < Backbone.Mye
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif maxF >= Backbone.Mye &&  maxR < Backbone.theta_p
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif maxR >= Backbone.theta_p
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

        else

            Sub_RootName = 'T';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(1:Ti,3);
            Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

            [maxF,~]=max(abs(Y));
            [maxR,~]=max(abs(X));

            [Backbone] = get_backbone_Column  (E, fy, HStory, MF_COLUMNS, MF_BEAMS, Splice, NStory, NBay, Fi, Axis, Pred, Units);

            if maxF < Backbone.Mye
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif maxF >= Backbone.Mye &&  maxR < Backbone.theta_p
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif maxR >= Backbone.theta_p
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

            Sub_RootName = 'B';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(1:Ti,3);
            Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

            [maxF,~]=max(abs(Y));
            [maxR,~]=max(abs(X));

            [Backbone] = get_backbone_Column  (E, fy, HStory, MF_COLUMNS, MF_BEAMS, Splice, NStory, NBay, Fi, Axis, Pred, Units);

            if maxF < Backbone.Mye
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif maxF >= Backbone.Mye &&  maxR < Backbone.theta_p
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif maxR >= Backbone.theta_p
                plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
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
            X=RESULTS.(char(D_Data))(1:Ti,3);
            Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

            [maxF,~]=max(abs(Y));
            [maxR,~]=max(abs(X));

            [Backbone] = get_backbone_Beam (E, fy, NStory, WBay, MF_COLUMNS, MF_BEAMS, Fi, Bayi, MFconnection, a, b, c, k_beambracing, Units);

            if maxF < Backbone.Mye
                plot(app.axes1,GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif maxF >= Backbone.Mye &&  maxR < Backbone.theta_p
                plot(app.axes1,GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif maxR >= Backbone.theta_p
                plot(app.axes1,GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

        elseif  Axis==1

            Sub_RootName = 'R';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(1:Ti,3);
            Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

            [maxF,~]=max(abs(Y));
            [maxR,~]=max(abs(X));

            [Backbone] = get_backbone_Beam (E, fy, NStory, WBay, MF_COLUMNS, MF_BEAMS, Fi, Bayi, MFconnection, a, b, c, k_beambracing, Units);

            if maxF < Backbone.Mye
                plot(app.axes1,GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif maxF >= Backbone.Mye &&  maxR < Backbone.theta_p
                plot(app.axes1,GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif maxR >= Backbone.theta_p
                plot(app.axes1,GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

        else

            Sub_RootName = 'L';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(1:Ti,3);
            Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

            [maxF,~]=max(abs(Y));
            [maxR,~]=max(abs(X));

            [Backbone] = get_backbone_Beam (E, fy, NStory, WBay, MF_COLUMNS, MF_BEAMS, Fi, Bayi, MFconnection, a, b, c, k_beambracing, Units);

            if maxF < Backbone.Mye
                plot(app.axes1,GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif maxF >= Backbone.Mye &&  maxR < Backbone.theta_p
                plot(app.axes1,GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif maxR >= Backbone.theta_p
                plot(app.axes1,GridX(Axis)-Column_Data.d(Story,Axis)-Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end

            Sub_RootName = 'R';
            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
            evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
            X=RESULTS.(char(D_Data))(1:Ti,3);
            Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

            [maxF,~]=max(abs(Y));
            [maxR,~]=max(abs(X));

            [Backbone] = get_backbone_Beam (E, fy, NStory, WBay, MF_COLUMNS, MF_BEAMS, Fi, Bayi, MFconnection, a, b, c, k_beambracing, Units);

            if maxF < Backbone.Mye
                plot(app.axes1,GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif maxF >= Backbone.Mye &&  maxR < Backbone.theta_p
                plot(app.axes1,GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
            elseif maxR >= Backbone.theta_p
                plot(app.axes1,GridX(Axis)  +Column_Data.d(Story,Axis)+Beam_Data.LRBS(Fi,Bayj)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end
        end
    end
end

%%
RootName = 'PZ';
for Fi = 2:NStory+1
    if Recorders.PZ==1
        if Splice(max(1,Fi-1),1)==1; Story = Fi; else; Story = Fi-1; end
        for Axis = 1:NBay+1
            Bayi = max(1,Axis-1); Bayj = Axis;

            evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),'_F','''']);
            Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

            [maxF,~]=max(abs(Y));

            [Backbone] = get_backbone_PZ (MF_COLUMNS, MF_BEAMS, Doubler, Story, Axis, Fi, Bayi, E, fy, Units);

            if maxF < Backbone.Vy
                plot(app.axes1,GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,Bayi)/2,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
            elseif maxF >= Backbone.Vy
                plot(app.axes1,GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,Bayi)/2,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
                % elseif maxF >= Backbone.Vp_4gamma
                %     plot(app.axes1,GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,Bayi)/2,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
            end
        end
    else
        plot(app.axes1,GridX(Axis)+Column_Data.d(Story,Axis)/2+dispfloor(Fi), GridY(Fi)+Beam_Data.d(Fi,Bayi)/2,'o','Markeredgecolor',[0 0 0],'Markerfacecolor',[0.6 0.6 0.6],'MarkerSize',5);
    end
end



%% EGF Columns

if GFX ==1
    count=0;
    RootName = 'ColSpring';
    for Fi=NStory+1:-1:1
        Story=max(NStory,Fi-1);


        if Fi==1

            Section=GF_COLUMNS{Story,1}; if Splice(Story,1)==1; Section = GF_COLUMNS{Floor,1}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel

            [Backbone] = get_backbone_EGFColumn  (E, fy, Section, HStory(Story), PgPye_GC(count+1,1), Units);

            for Axis = NBay+2:NBay+3

                Sub_RootName = 'T';
                evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
                evalc(['D_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_D','''']);
                X=RESULTS.(char(D_Data))(1:Ti,3);
                Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

                [maxR,~]=max(abs(X));
                [maxF,~]=max(abs(Y));

                if maxF < Backbone.Mye * nGC /nMF/2
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
                elseif maxF >= Backbone.Mye* nGC /nMF/2 &&  maxR < Backbone.theta_p
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
                elseif maxR >= Backbone.theta_p
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
                end
            end

        elseif  Fi==NStory+1

            Section=GF_COLUMNS{Story,1}; if Splice(Story,1)==1; Section = GF_COLUMNS{Floor,1}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel

            [Backbone] = get_backbone_EGFColumn  (E, fy, Section, HStory(Story), PgPye_GC(count+1,1), Units);
            for Axis = NBay+2:NBay+3

                Sub_RootName = 'B';
                evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
                Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

                [maxF,~]=max(abs(Y));


                if maxF < Backbone.Mye * nGC /nMF/2
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
                elseif maxF >= Backbone.Mye * nGC /nMF/2 &&  maxF < Backbone.Mc * nGC /nMF/2
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
                elseif maxF >= Backbone.Mc * nGC /nMF/2
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
                end
            end
        else

            Section=GF_COLUMNS{Story,1}; if Splice(Story,1)==1; Section = GF_COLUMNS{Floor,1}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel

            [Backbone] = get_backbone_EGFColumn  (E, fy, Section, HStory(Story), PgPye_GC(count+1,1), Units);
            for Axis = NBay+2:NBay+3

                Sub_RootName = 'T';
                evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
                Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

                [maxF,~]=max(abs(Y));


                if maxF < Backbone.Mye * nGC /nMF/2
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
                elseif maxF >= Backbone.Mye * nGC /nMF/2 &&  maxF < Backbone.Mc * nGC /nMF/2
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
                elseif maxF >= Backbone.Mc * nGC /nMF/2
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)+0.05*HStory,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
                end
            end
            [Backbone] = get_backbone_EGFColumn  (E, fy, Section, HStory(Story), PgPye_GC(count+1,1), Units);
            for Axis = NBay+2:NBay+3

                Sub_RootName = 'B';
                evalc(['F_Data=','''',RootName,num2str(Fi),num2str(Axis),Sub_RootName,'_F','''']);
                Y=RESULTS.(char(F_Data))(1:Ti,DataColIndx)*convfactor;

                [maxF,~]=max(abs(Y));

                if maxF < Backbone.Mye * nGC /nMF/2
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
                elseif maxF >= Backbone.Mye * nGC /nMF/2 &&  maxF < Backbone.Mc * nGC /nMF/2
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
                elseif maxF >= Backbone.Mc * nGC /nMF/2
                    plot(app.axes1,GridX(Axis)+dispfloor(Fi), GridY(Fi)-0.05*HStory,'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
                end
            end
        end

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
            plot(app.axes1,GridX(NBay+2)+0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
        elseif Ti >= indxP &&  Ti < indxC
            plot(app.axes1,GridX(NBay+2)+0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
        elseif Ti > indxC
            plot(app.axes1,GridX(NBay+2)+0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
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
            plot(app.axes1,GridX(NBay+3)-0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.4660 0.6740 0.1880],'Markerfacecolor','g','MarkerSize',5);
        elseif Ti >= indxP &&  Ti < indxC
            plot(app.axes1,GridX(NBay+3)-0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.8500 0.3250 0.0980],'Markerfacecolor',[0.9290 0.6940 0.1250],'MarkerSize',5);
        elseif Ti > indxC
            plot(app.axes1,GridX(NBay+3)-0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0.6350 0.0780 0.1840],'Markerfacecolor','r','MarkerSize',5);
        end
    else
        plot(app.axes1,GridX(NBay+2)+0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0 0 0],'Markerfacecolor',[0.6 0.6 0.6],'MarkerSize',5);
        plot(app.axes1,GridX(NBay+3)-0.05*WBay(1)+dispfloor(Fi), GridY(Fi),'o','Markeredgecolor',[0 0 0],'Markerfacecolor',[0.6 0.6 0.6],'MarkerSize',5);

    end

end

%%
drawnow