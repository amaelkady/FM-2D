function write_EGF (INP,NStory,NBay,HStory,GFX,CompositeX,Orientation,nMF,nGC,nGB,MF_COLUMNS,MF_BEAMS,GF_COLUMNS,GF_BEAMS,Splice,fy,Units)


fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                          EGF COLUMNS AND BEAMS                                   #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

for Story=NStory:-1:1
    Iy_MFcolumns(Story,1)=0;
    Zy_MFcolumns(Story,1)=0;
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,Axis};
        [SecData]=Load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section));
        Iy_MFcolumns(Story,1)=Iy_MFcolumns(Story,1)+SecData.Iy(idx);
        Zy_MFcolumns(Story,1)=Zy_MFcolumns(Story,1)+SecData.Zy(idx);
    end
end

fprintf(INP,'# GRAVITY COLUMNS\n');
for Story=NStory:-1:1
    Fi=Story; Fj=Story+1;
	
    if GFX==0
        A_GC=100000.; I_GC=100000000.; Z_GC=100000000.;
    else
        Section=GF_COLUMNS{Story,1};
        [SecData]=Load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section));
        A_GC = nGC *  SecData.Area(idx)/nMF/2;
        if Orientation==1
            I_GC = nGC *  SecData.Iy(idx)/nMF/2;
            Z_GC = nGC *  SecData.Zy(idx)/nMF/2;
        else
            I_GC = nGC *  SecData.Ix(idx)/nMF/2;
            Z_GC = nGC *  SecData.Zx(idx)/nMF/2;
        end
    end
	
    if Splice(Story,1)==0
        for Axis=NBay+2:NBay+3
            iNode=100*Fi+10*Axis+03;
            jNode=100*Fj+10*Axis+01;
            ElemID=600000+1000*Story+100*Axis;
            if GFX==1; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E [expr (%.4f  + %.4f)] $trans_PDelta; ', ElemID,iNode,jNode,A_GC, I_GC, Iy_MFcolumns(Story,1)); end
            if GFX==0; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E %.4f 				    $trans_PDelta; ', ElemID,iNode,jNode,A_GC, I_GC); end
        end
    else
        if GFX==0
            A_GC=100000.; I_GC=100000000.; Z_GC=100000000.;
        else
            Section=GF_COLUMNS{min(Story+1,NStory),1};
            [SecData]=Load_SecData (Section, Units);
            idx1=find(contains(SecData.Name,Section));
            A_GC = nGC *  SecData.Area(idx1)/nMF/2;
            if Orientation==1
                I_GC = nGC *  SecData.Iy(idx1)/nMF/2;
                Z_GC = nGC *  SecData.Zy(idx1)/nMF/2;
            else
                I_GC = nGC *  SecData.Ix(idx1)/nMF/2;
                Z_GC = nGC *  SecData.Zx(idx1)/nMF/2;
            end
        end
        for Axis=NBay+2:NBay+3
            nodeIDb=100*Fj+10*Axis+01;
            nodeIDsplice72=100000+1000*Story+100*Axis+72;
            ElemID02=600000+1000*Story+100*Axis+02;
            if GFX==1; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E [expr (%.4f  + %.4f)] $trans_PDelta; ',ElemID02, nodeIDsplice72, nodeIDb, A_GC, I_GC, Iy_MFcolumns(min(Story+1,NStory),1)); end
            if GFX==0; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E %.4f 				    $trans_PDelta; ',ElemID02, nodeIDsplice72, nodeIDb, A_GC, I_GC); end
        end
        fprintf(INP,'\n');
        for Axis=NBay+2:NBay+3
            nodeIDt=100*Fi+10*Axis+03;
            nodeIDsplice71=100000+1000*Story+100*Axis+71;
            ElemID01=600000+1000*Story+100*Axis+01;
            if GFX==1; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E [expr (%.4f  + %.4f)] $trans_PDelta; ',ElemID01, nodeIDt, nodeIDsplice71, A_GC, I_GC, Iy_MFcolumns(Story,1)); end
            if GFX==0; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E %.4f 				 $trans_PDelta; ',ElemID01, nodeIDt, nodeIDsplice71, A_GC, I_GC); end
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');



fprintf(INP,'# GRAVITY BEAMS\n');
for Floor=NStory+1:-1:2
    if GFX==0
        A_GB=100000.; I_GB=100000000.; Z_GB=100000000.;
    else
        Section=GF_BEAMS{Floor-1,1};
        [SecData]=Load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section));
        A_GB = nGB *  SecData.Area(idx)/nMF;
        I_GB = nGB *  SecData.Ix(idx)/nMF;
    end
    nodeID1=100*Floor+10*(NBay+2)+04;
    nodeID2=100*Floor+10*(NBay+3)+02;
    ElemID=500000+1000*Floor+100*(NBay+1)+00;
    if GFX==1; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E [expr $Comp_I_GC * %.4f] $trans_PDelta;\n', ElemID, nodeID1, nodeID2, A_GB, I_GB); end
    if GFX==0; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E %.4f                     $trans_PDelta;\n', ElemID, nodeID1, nodeID2, A_GB, I_GB); end
end
fprintf(INP,'\n');



fprintf(INP,'# GRAVITY COLUMNS SPRINGS\n');
for Floor=NStory+1:-1:1
    Story=min(Story,Floor);
    if GFX==1
        Section=GF_COLUMNS{Story,1};
        [SecData]=Load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section));
        if Orientation==1
            I_GC = nGC *  SecData.Iy(idx)/nMF/2;
            Z_GC = nGC *  SecData.Zy(idx)/nMF/2;
        else
            I_GC = nGC *  SecData.Ix(idx)/nMF/2;
            Z_GC = nGC *  SecData.Zx(idx)/nMF/2;
        end
        H_GC = HStory(Story);
        L_GC  = H_GC/2;
        Lb_GC = H_GC;
    end
    
    if Floor~=NStory+1 && Floor~=1
        for Axis=NBay+2:NBay+3
            nodeID1=(10*Floor+Axis)*10;
            nodeID2=100*Floor+10*Axis+03;
            SpringID=900000+Floor*1000+Axis*100+03;
            
            if GFX==1
                My_GC =	1.1 * fy * (Z_GC + Zy_MFcolumns(Story,1));
                fprintf(INP,'Spring_IMK  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite 0 %d; ', SpringID,nodeID1,nodeID2,I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, Units);
            end
            if GFX==0
                fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID, nodeID1, nodeID2);
            end
        end
        fprintf(INP,'\n');
        for Axis=NBay+2:NBay+3
            nodeID1=(10*Floor+Axis)*10;
            nodeID2=100*Floor+10*Axis+01;
            SpringID=900000+Floor*1000+Axis*100+01;
            if GFX==1
                fprintf(INP,'Spring_IMK  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite 0 %d; ', SpringID,nodeID1,nodeID2,I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, Units);
            end
            if GFX==0
                fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID, nodeID1, nodeID2);
            end
        end
    end
    if Floor==NStory+1
        for Axis=NBay+2:NBay+3
            nodeID1=(10*Floor+Axis)*10;
            nodeID2=100*Floor+10*Axis+01;
            SpringID=900000+Floor*1000+Axis*100+01;
            if GFX==1
                My_GC =	1.1 * fy * (Z_GC + Zy_MFcolumns(Story,1));
                fprintf(INP,'Spring_IMK  %7d %7d %7d $E $fy [expr (%.4f + %.4f)] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite 0 %d; ', SpringID,nodeID1,nodeID2,I_GC, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, Units);
            end
            if GFX==0
                fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID, nodeID1,nodeID2);
            end
        end
    end
    if Floor==1
        for Axis=NBay+2:NBay+3
            nodeID1=(10*Floor+Axis)*10;
            nodeID2=100*Floor+10*Axis+03;
            SpringID=900000+Floor*1000+Axis*100+03;
            if GFX==1
                My_GC =	1.1 * fy * (Zy_MFcolumns(Story,1));
                fprintf(INP,'Spring_IMK  %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite 0 %d; ', SpringID,nodeID1,nodeID2, Iy_MFcolumns(Story,1),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx), H_GC,L_GC,Lb_GC,My_GC, Units);
            end
            if GFX==0
                fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID, nodeID1,nodeID2);
            end
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');


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
        Section=GF_BEAMS{Floor-1,1};
        [SecData]=Load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section));
        Z_GB = nGB *  SecData.Zx(idx)/nMF;
        My_GB =	1.1 * fy * Z_GB;
        
        nodeID0=(10*Floor+(NBay+2))*10;
        nodeID1=100*Floor+10*(NBay+2)+04;
        fprintf(INP,'Spring_Pinching  %7d %7d %7d %.4f $gap %d; ', SpringID_R,nodeID0,nodeID1, My_GB, ResponseID);
        matID=matID+1;
        nodeID0=(10*Floor+(NBay+3))*10;
        nodeID1=100*Floor+10*(NBay+3)+02;
        fprintf(INP,'Spring_Pinching  %7d %7d %7d %.4f $gap %d; ', SpringID_L,nodeID0,nodeID1, My_GB, ResponseID);
        matID=matID+1;
    end
    if GFX==0
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