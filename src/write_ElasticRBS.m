function write_ElasticRBS (INP, NStory, NBay, MF_BEAMS, MFconnection, c, Units)

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                      ELASTIC RBS ELEMENTS                                        #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

for Floor=NStory+1:-1:2
    for Axis=1:NBay+1
        if Axis==1; xx=1; else xx=Axis-1; end
        if Axis==NBay+1; xx=NBay; end
        Section=MF_BEAMS{Floor-1,xx};
        [SecData]=Load_SecData (Section,Units);
        idx=find(contains(SecData.Name,Section));
        
        A_RBS  =SecData.Area(idx) - 4 * c * SecData.bf(idx)*SecData.tf(idx);
        I_RBS  =SecData.Ix(idx) - 4 * c * SecData.bf(idx)*SecData.tf(idx)*((SecData.d(idx)-SecData.tf(idx))/2)^2 - 4 *c * SecData.bf(idx)*SecData.tf(idx)^3/12;
        Z_RBS  =2 * (SecData.bf(idx) - c * SecData.bf(idx))*SecData.tf(idx)*(SecData.d(idx)/2-SecData.tf(idx)/2) + 2 * (SecData.d(idx)/2-SecData.tf(idx))*SecData.tw(idx)*(SecData.d(idx)/2-SecData.tf(idx))/2;
        A_AVG  =(SecData.Area(idx)+ A_RBS) / 2.;
        I_AVG  =(SecData.Ix(idx)  + I_RBS) / 2.;
        Z_AVG  =(SecData.Zx(idx)  + Z_RBS) / 2.;
        
        if MFconnection==1
            A_RBS  =SecData.Area(idx);
            I_RBS  =SecData.Ix(idx);
            Z_RBS  =SecData.Zx(idx);
            A_AVG  =A_RBS;
            I_AVG  =I_RBS;
            Z_AVG  =Z_RBS;
        end
        
        if Axis~=1 && Axis~=NBay+1
            nodeID1=400000+Floor*1000+Axis*100+02;
            nodeID2=Floor*1000+Axis*100+20;
            ElemID=500000+1000*Floor+100*Axis+02;
            fprintf(INP,'element elasticBeamColumn %d %d %d %.3f $E [expr $Comp_I*%.3f] 1; ',ElemID,nodeID1,nodeID2,A_AVG,I_AVG);
            nodeID1=400000+Floor*1000+Axis*100+04;
            nodeID2=Floor*1000+Axis*100+40;
            ElemID=500000+1000*Floor+100*Axis+04;
            fprintf(INP,'element elasticBeamColumn %d %d %d %.3f $E [expr $Comp_I*%.3f] 1; ',ElemID,nodeID1,nodeID2,A_AVG,I_AVG);
        end
        if Axis==1
            nodeID1=400000+Floor*1000+Axis*100+04;
            nodeID2=Floor*1000+Axis*100+40;
            ElemID=500000+1000*Floor+100*Axis+04;
            fprintf(INP,'element elasticBeamColumn %d %d %d %.3f $E [expr $Comp_I*%.3f] 1; ',ElemID,nodeID1,nodeID2,A_AVG,I_AVG);
        end
        if Axis==NBay+1
            nodeID1=400000+Floor*1000+Axis*100+02;
            nodeID2=Floor*1000+Axis*100+20;
            ElemID=500000+1000*Floor+100*Axis+02;
            fprintf(INP,'element elasticBeamColumn %d %d %d %.3f $E [expr $Comp_I*%.3f] 1; ',ElemID,nodeID1,nodeID2,A_AVG,I_AVG);
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');