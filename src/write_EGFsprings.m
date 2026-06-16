function write_EGFsprings (INP)

global MainDirectory 
load(strcat(MainDirectory,'\temp_unpacked'),'NStory','NBay','GFX','GFconnection', 'GF_Connection','CompositeX', 'Orientation','MF_COLUMNS','MF_BEAMS','GF_COLUMNS','GF_BEAMS','Splice', 'LAYOUT', 'MATERIALS', 'LOADS', 'nMF', 'nGC', 'TribAreaIn', 'TribAreaEx', 'HStory', 'TA_MF', 'cDL_W' , 'RoofDL' , 'cLL_W' , 'RoofLL' , 'cGL_W' , 'RoofGL', 'fy', 'TypicalDL', 'TypicalLL', 'TypicalGL','nGB', 'Units');

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                            EGF MEMBER SPRINGS                                    #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

%%
for Story=NStory:-1:1
    Iy_MFcolumns(Story,1)=0;
    Zy_MFcolumns(Story,1)=0;
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,Axis}; if Splice(Story,1)==1; Section = MF_COLUMNS{Story+1,Axis}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel
        [SecData]=load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section),1,'first');
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
        [SecData]=load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section),1,'first');
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
                fprintf(INP,'Spring_Column_WideFlange  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d; ', SpringID,nodeID1,nodeID2,I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, PgPy_GC, Units);
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
                fprintf(INP,'Spring_Column_WideFlange  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d; ', SpringID,nodeID1,nodeID2,I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, PgPy_GC, Units);
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
                fprintf(INP,'Spring_Column_WideFlange  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d; ', SpringID,nodeID1,nodeID2, I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, PgPy_GC, Units);
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
                fprintf(INP,'Spring_Column_WideFlange  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d; ', SpringID,nodeID1,nodeID2, I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, PgPy_GC, Units);
            else
                fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID, nodeID1,nodeID2);
            end
        end
        PgPye_GC(count+1,1)=PgPy_GC;
    end
    fprintf(INP,'\n');

end
fprintf(INP,'\n');

save(strcat(MainDirectory,'\temp_unpacked'),'PgPye_GC','-append')


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

        if GFconnection ~= 1
            Connectioni=GF_Connection{Floor-1,1};
            [ConData]=load_PRConnParams (Connectioni, GFconnection);
        end

        Section=GF_COLUMNS{Story,1}; if Splice(Story,1)==1; Section = GF_COLUMNS{Floor,1}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel
        [SecData]=load_SecData (Section, Units);
        idxC=find(contains(SecData.Name,Section),1,'first');

        Section=GF_BEAMS{Floor-1,1};
        [SecData]=load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section),1,'first');
        Z_GB =  SecData.Zx(idx)/nMF;
        My_GB =	1.1 * fy * Z_GB;

        nodeID0=(10*Floor+   (NBay+2))*10;
        nodeID1=100*Floor+10*(NBay+2)+04;
        if     GFconnection == 1
            fprintf(INP,'Spring_Connection_ShearTab  %7d %7d %7d [expr (%.4f/%.4f)*%.4f] $gap %d; ', SpringID_R,nodeID0,nodeID1, nGB, nMF, My_GB, ResponseID);
        elseif GFconnection == 2
        elseif GFconnection == 3
            fprintf(INP,'Spring_Connection_FEPC      %7d %7d %7d %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f $fyP $fuP $fy $fu $fyb $fub %d %d %.4f %d %d; ', SpringID_R,nodeID0,nodeID1, ConData.dt, ConData.g, ConData.tep, SecData.tf(idxC), ConData.d_b, SecData.d(idx), SecData.d(idxC), SecData.tw(idxC), ConData.StiffenerC, ConData.nrows, nGB/nMF, CompositeX, Units);
        elseif GFconnection == 4
            fprintf(INP,'Spring_Connection_SR_EEPC   %7d %7d %7d %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f $fyP $fuP $fy $fu $fyb $fub %d %d %.4f %d %d; ', SpringID_R,nodeID0,nodeID1, ConData.pt, ConData.g, ConData.tep, SecData.tf(idxC), ConData.d_b, SecData.d(idx), SecData.d(idxC), SecData.tw(idxC), ConData.StiffenerC, ConData.nrows, nGB/nMF, CompositeX, Units);
        end

        matID=matID+1;
        nodeID0=(10*Floor+   (NBay+3))*10;
        nodeID1=100*Floor+10*(NBay+3)+02;
        if     GFconnection == 1
            fprintf(INP,'Spring_Connection_ShearTab  %7d %7d %7d [expr (%.4f/%.4f)*%.4f] $gap %d; ', SpringID_L, nodeID1, nodeID0, nGB, nMF, My_GB, ResponseID);
        elseif GFconnection == 2
        elseif GFconnection == 3
            fprintf(INP,'Spring_Connection_FEPC      %7d %7d %7d %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f $fyP $fuP $fy $fu $fyb $fub %d %d %.4f %d %d; ', SpringID_L,nodeID1,nodeID0, ConData.dt, ConData.g, ConData.tep, SecData.tf(idxC), ConData.d_b, SecData.d(idx), SecData.d(idxC), SecData.tw(idxC), ConData.StiffenerC, ConData.nrows, nGB/nMF, CompositeX, Units);
        elseif GFconnection == 4
            fprintf(INP,'Spring_Connection_SR_EEPC   %7d %7d %7d %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f $fyP $fuP $fy $fu $fyb $fub %d %d %.4f %d %d; ', SpringID_L,nodeID1,nodeID0, ConData.pt, ConData.g, ConData.tep, SecData.tf(idxC), ConData.d_b, SecData.d(idx), SecData.d(idxC), SecData.tw(idxC), ConData.StiffenerC, ConData.nrows, nGB/nMF, CompositeX, Units);
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