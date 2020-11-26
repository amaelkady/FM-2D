function write_EGFelements (INP,NStory,NBay,HStory,GFX,CompositeX,Orientation,nMF,nGC,nGB,MF_COLUMNS,MF_BEAMS,GF_COLUMNS,GF_BEAMS,Splice,fy,Units)


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
            if GFX==0; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E %.4f $trans_PDelta; ', ElemID,iNode,jNode,A_GC, I_GC); end
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
            if GFX==0; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E %.4f $trans_PDelta; ',ElemID02, nodeIDsplice72, nodeIDb, A_GC, I_GC); end
        end
        fprintf(INP,'\n');
        for Axis=NBay+2:NBay+3
            nodeIDt=100*Fi+10*Axis+03;
            nodeIDsplice71=100000+1000*Story+100*Axis+71;
            ElemID01=600000+1000*Story+100*Axis+01;
            if GFX==1; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E [expr (%.4f  + %.4f)] $trans_PDelta; ',ElemID01, nodeIDt, nodeIDsplice71, A_GC, I_GC, Iy_MFcolumns(Story,1)); end
            if GFX==0; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E %.4f $trans_PDelta; ',ElemID01, nodeIDt, nodeIDsplice71, A_GC, I_GC); end
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
    if GFX==0; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E %.4f $trans_PDelta;\n', ElemID, nodeID1, nodeID2, A_GB, I_GB); end
end
fprintf(INP,'\n');



