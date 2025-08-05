function write_EGFsprings (INP,GFX,EGFconnection, CONNECTIONS,CompositeX,Orientation,MF_COLUMNS,MF_BEAMS,GF_COLUMNS,GF_BEAMS,Splice, LAYOUT, MATERIALS, LOADS, Units)
global ProjectPath ProjectName

% Unload structure variables into fields
save('temp.mat','-struct','MATERIALS')
save('temp.mat','-struct','LOADS','-append')
save('temp.mat','-struct','LAYOUT','-append')
load('temp.mat')

for Story=NStory:-1:1
    Iy_MFcolumns(Story,1)=0;
    Zy_MFcolumns(Story,1)=0;
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,Axis}; if Splice(Story,1)==1; Section = MF_COLUMNS{Story+1,Axis}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel
        [SecData]=Load_SecData (Section, Units);
        idx=min(find(contains(SecData.Name,Section)));
        Iy_MFcolumns(Story,1)=0; %Iy_MFcolumns(Story,1)+SecData.Iy(idx);
        Zy_MFcolumns(Story,1)=0; %Zy_MFcolumns(Story,1)+SecData.Zy(idx);
    end
end

%%
count=0;
fprintf(INP,'# GRAVITY COLUMNS SPRINGS\n');
for Floor=NStory+1:-1:1
    Story=min(NStory,Floor);


    if GFX==1
        Section=GF_COLUMNS{Story,1}; if Splice(Story,1)==1; Section = GF_COLUMNS{Floor,1}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel
        [SecData]=Load_SecData (Section, Units);
        idx=min(find(contains(SecData.Name,Section)));
        if Orientation==1
            I_GC = nGC *  SecData.Iy(idx)/nMF/2;
            Z_GC = nGC *  SecData.Zy(idx)/nMF/2;
        else
            I_GC = nGC *  SecData.Ix(idx)/nMF/2;
            Z_GC = nGC *  SecData.Zx(idx)/nMF/2;
        end
        A_GC = nGC *  SecData.Area(idx)/nMF/2;
        H_GC = HStory(Story);
        L_GC  = H_GC/2;
        Lb_GC = H_GC;
        Area_EGF = TA_MF - (NBay-1)*TribAreaIn - 2* TribAreaEx;
    else
        PgPy_GC=0;
    end


    if Floor~=NStory+1 && Floor~=1

        for Axis=NBay+2:NBay+3
            nodeID1=(10*Floor+Axis)*10;
            nodeID2=100*Floor+10*Axis+03;
            SpringID=900000+Floor*1000+Axis*100+03;
            if GFX==1
                Pg_EGF   = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * Area_EGF + (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * Area_EGF * (NStory+1 - Floor -1);
                PgPy_GC  = Pg_EGF/(A_GC*fy);
                My_GC =	1.1 * fy * (Z_GC + Zy_MFcolumns(Story,1));
                fprintf(INP,'Spring_IMK  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f $Composite 2 %d; ', SpringID,nodeID1,nodeID2,I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, PgPy_GC, Units);
            else
                fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID, nodeID1, nodeID2);
            end
        end
        PgPye_GC(count+1,1)=PgPy_GC;
        fprintf(INP,'\n');


        for Axis=NBay+2:NBay+3
            nodeID1=(10*Floor+Axis)*10;
            nodeID2=100*Floor+10*Axis+01;
            SpringID=900000+Floor*1000+Axis*100+01;
            if GFX==1
                Pg_EGF   = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * Area_EGF + (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * Area_EGF * (NStory+1 - Floor);
                PgPy_GC  = Pg_EGF/(A_GC*fy);
                fprintf(INP,'Spring_IMK  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f $Composite 2 %d; ', SpringID,nodeID1,nodeID2,I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, PgPy_GC, Units);
            else
                fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID, nodeID1, nodeID2);
            end
        end
        PgPye_GC(count+1,1)=PgPy_GC;

    elseif Floor==NStory+1

        for Axis=NBay+2:NBay+3

            nodeID1=(10*Floor+Axis)*10;
            nodeID2=100*Floor+10*Axis+01;
            SpringID=900000+Floor*1000+Axis*100+01;
            if GFX==1
                Pg_EGF   = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * Area_EGF;
                PgPy_GC  = Pg_EGF/(A_GC*fy);
                My_GC =	1.1 * fy * (Z_GC + Zy_MFcolumns(Story,1));
                fprintf(INP,'Spring_IMK  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f $Composite 2 %d; ', SpringID,nodeID1,nodeID2, I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, PgPy_GC, Units);
            else
                fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID, nodeID1,nodeID2);
            end
        end
        PgPye_GC(count+1,1)=PgPy_GC;

    elseif Floor==1

        for Axis=NBay+2:NBay+3

            nodeID1=(10*Floor+Axis)*10;
            nodeID2=100*Floor+10*Axis+03;
            SpringID=900000+Floor*1000+Axis*100+03;
            if GFX==1
                Pg_EGF   = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * Area_EGF + (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * Area_EGF * (NStory-1);
                PgPy_GC  = Pg_EGF/(A_GC*fy);
                My_GC =	1.1 * fy * (Z_GC + Zy_MFcolumns(Story,1));
                fprintf(INP,'Spring_IMK  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f $Composite 2 %d; ', SpringID,nodeID1,nodeID2, I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, PgPy_GC, Units);
            else
                fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID, nodeID1,nodeID2);
            end
        end
        PgPye_GC(count+1,1)=PgPy_GC;
    end
    fprintf(INP,'\n');

end
fprintf(INP,'\n');

save(strcat(ProjectPath,ProjectName),'PgPye_GC','-append')




%%

fprintf(INP,'# GRAVITY BEAMS SPRINGS\n');
if GFX==1
    fprintf(INP,'set gap 0.08;\n');
    if CompositeX==1
        ResponseID =1;
    else
        ResponseID =0;
    end
end

matID=22;
for Floor=NStory+1:-1:2

    SpringID_R=900000+Floor*1000+(NBay+2)*100+04;
    SpringID_L=900000+Floor*1000+(NBay+3)*100+02;

    if GFX==1

        if EGFconnection == 2 || EGFconnection == 3
            Connectioni=CONNECTIONS{Floor-1,1};
            [ConData]=Load_ConData_EPC (Connectioni, EGFconnection);
        end

        Section=GF_COLUMNS{Story,1}; if Splice(Story,1)==1; Section = GF_COLUMNS{Floor,1}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel
        [SecData]=Load_SecData (Section, Units);
        idxC=min(find(contains(SecData.Name,Section)));

        Section=GF_BEAMS{Floor-1,1};
        [SecData]=Load_SecData (Section, Units);
        idx=min(find(contains(SecData.Name,Section)));
        Z_GB =  SecData.Zx(idx)/nMF;
        My_GB =	1.1 * fy * Z_GB;

        nodeID0=(10*Floor+   (NBay+2))*10;
        nodeID1=100*Floor+10*(NBay+2)+04;
        if     EGFconnection == 1
            fprintf(INP,'Spring_Pinching  %7d %7d %7d [expr (%.4f/%.4f)*%.4f] $gap %d; ', SpringID_R,nodeID0,nodeID1, nGB, nMF, My_GB, ResponseID);
        elseif EGFconnection == 2
        elseif EGFconnection == 3
            fprintf(INP,'Spring_FEPC      %7d %7d %7d %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d %d %.4f %d %d; ', SpringID_R,nodeID0,nodeID1, ConData.dt, ConData.g, ConData.tep, SecData.tf(idxC), ConData.d_b, SecData.d(idx), SecData.d(idxC), SecData.tw(idxC),  fyP, fuP, fy, fu, fyb, fub, ConData.StiffenerC, 2, nGB/nMF, CompositeX, Units);
        elseif EGFconnection == 4
            fprintf(INP,'Spring_EEPC      %7d %7d %7d %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d %d %.4f %d %d; ', SpringID_R,nodeID0,nodeID1, ConData.pt, ConData.g, ConData.tep, SecData.tf(idxC), ConData.d_b, SecData.d(idx), SecData.d(idxC), SecData.tw(idxC),  fyP, fuP, fy, fu, fyb, fub, ConData.StiffenerC, 4, nGB/nMF, CompositeX, Units);
        end

        matID=matID+1;
        nodeID0=(10*Floor+   (NBay+3))*10;
        nodeID1=100*Floor+10*(NBay+3)+02;
        if     EGFconnection == 1
            fprintf(INP,'Spring_Pinching  %7d %7d %7d [expr (%.4f/%.4f)*%.4f] $gap %d; ', SpringID_L, nodeID1, nodeID0, nGB, nMF, My_GB, ResponseID);
        elseif EGFconnection == 2
        elseif EGFconnection == 3
            fprintf(INP,'Spring_FEPC      %7d %7d %7d %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d %d %.4f %d %d; ', SpringID_L,nodeID1,nodeID0, ConData.dt, ConData.g, ConData.tep, SecData.tf(idxC), ConData.d_b, SecData.d(idx), SecData.d(idxC), SecData.tw(idxC),  fyP, fuP, fy, fu, fyb, fub, ConData.StiffenerC, 2, nGB/nMF, CompositeX, Units);
        elseif EGFconnection == 4
            fprintf(INP,'Spring_EEPC      %7d %7d %7d %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d %d %.4f %d %d; ', SpringID_L,nodeID1,nodeID0, ConData.pt, ConData.g, ConData.tep, SecData.tf(idxC), ConData.d_b, SecData.d(idx), SecData.d(idxC), SecData.tw(idxC),  fyP, fuP, fy, fu, fyb, fub, ConData.StiffenerC, 4, nGB/nMF, CompositeX, Units);
        end
        matID=matID+1;


    else

        nodeID0=(10*Floor+(NBay+2))*10;
        nodeID1=100*Floor+10*(NBay+2)+04;
        fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID_R,nodeID0,nodeID1);
        nodeID0=(10*Floor+(NBay+3))*10;
        nodeID1=100*Floor+10*(NBay+3)+02;
        fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID_L,nodeID0,nodeID1);

    end

    fprintf(INP,'\n');
end
fprintf(INP,'\n');