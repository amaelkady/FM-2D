function write_EGFelements_FiberFrame (INP,NStory,NBay,GFX,Orientation,nMF,nGC,nGB,MF_COLUMNS,GF_COLUMNS,GF_BEAMS)


fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                          EGF COLUMNS AND BEAMS                                   #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

for Story=NStory:-1:1
    Iy_MFcolumns(Story,1)=0;
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,1};
        [SecData]=Load_SecData_RC (Section);
        Iy_MFcolumns(Story,1)=Iy_MFcolumns(Story,1)+0.5*SecData.H*SecData.B^3/12;
    end
end

fprintf(INP,'# GRAVITY COLUMNS\n');
for Story=NStory:-1:1
    Fi=Story; Fj=Story+1;
	
    if GFX==0
        A_GC=100000.; I_GC=100000000.;
    else
        Section=GF_COLUMNS{Story,1};
        [SecData]=Load_SecData_RC (Section);
        A_GC = nGC *  SecData.H*SecData.B/nMF/2;
        if Orientation==1
            I_GC = nGC *  0.5*SecData.H*SecData.B^3/12/nMF/2;
        else
            I_GC = nGC *  0.5*SecData.B*SecData.H^3/12/nMF/2;
        end
    end
	
    for Axis=NBay+2:NBay+3
        iNode=100*Fi+10*Axis;
        jNode=100*Fj+10*Axis;
        ElemID=600000+1000*Story+100*Axis;
        if GFX==1; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E [expr (%.4f  + %.4f)] $trans_PDelta; ', ElemID,iNode,jNode,A_GC, I_GC, Iy_MFcolumns(Story,1)); end
        if GFX==0; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $E %.4f $trans_PDelta; ', ElemID,iNode,jNode,A_GC, I_GC); end
    end

    fprintf(INP,'\n');
end
fprintf(INP,'\n');



fprintf(INP,'# GRAVITY BEAMS\n');
for Floor=NStory+1:-1:2
    if GFX==0
        A_GB=100000.; I_GB=100000000.;
    else
        Section=GF_BEAMS{Floor-1,1};
        [SecData]=Load_SecData_RC (Section);
        A_GB = nGB *  SecData.B*SecData.H/nMF;
        I_GB = nGB *  0.5*SecData.B*SecData.H^3/12/nMF;
    end
    nodeID1=100*Floor+10*(NBay+2)+04;
    nodeID2=100*Floor+10*(NBay+3)+02;
    ElemID=500000+1000*Floor+100*(NBay+1)+00;
    if GFX==1; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $Ec %.4f $trans_PDelta;\n', ElemID, nodeID1, nodeID2, A_GB, I_GB); end
    if GFX==0; fprintf(INP,'element elasticBeamColumn %7d %7d %7d %.4f $Ec %.4f $trans_PDelta;\n', ElemID, nodeID1, nodeID2, A_GB, I_GB); end
end
fprintf(INP,'\n');



