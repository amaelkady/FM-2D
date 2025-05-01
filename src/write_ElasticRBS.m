function write_ElasticRBS (INP, NStory, NBay, MF_BEAMS, c, Units)

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                      ELASTIC RBS ELEMENTS                                        #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

for Floor=NStory+1:-1:2
    for Axis=1:NBay+1
        Bay=max(1, Axis-1);

        Section=MF_BEAMS{Floor-1,Bay};
        [SecData]=Load_SecData (Section,Units);
        idx=min(find(contains(SecData.Name,Section)));
        
        A_RBS  =SecData.Area(idx) - 4 * c * SecData.bf(idx)*SecData.tf(idx);
        I_RBS  =SecData.Ix(idx) - 4 * c * SecData.bf(idx)*SecData.tf(idx)*((SecData.d(idx)-SecData.tf(idx))/2)^2 - 4 *c * SecData.bf(idx)*SecData.tf(idx)^3/12;
        Z_RBS  =2 * (SecData.bf(idx) - c * SecData.bf(idx))*SecData.tf(idx)*(SecData.d(idx)/2-SecData.tf(idx)/2) + 2 * (SecData.d(idx)/2-SecData.tf(idx))*SecData.tw(idx)*(SecData.d(idx)/2-SecData.tf(idx))/2;
        A_AVG  =(SecData.Area(idx)+ A_RBS) / 2.;
        I_AVG  =(SecData.Ix(idx)  + I_RBS) / 2.;
        Z_AVG  =(SecData.Zx(idx)  + Z_RBS) / 2.;
        
        factor_I_mod = get_mod_I_with_shear ('Beam', Bay, 0, SecData, idx);

        if Axis~=1 && Axis~=NBay+1

            nodeID1=400000+Floor*1000+Axis*100+02;
            nodeID2=Floor*1000+Axis*100+20;
            ElemID=500000+1000*Floor+100*Axis+02;
            fprintf(INP,'element elasticBeamColumn %d %d %d %.3f $E [expr $Comp_I*%.3f*%.3f] 1; ',ElemID,nodeID1,nodeID2,A_AVG,I_AVG,factor_I_mod);
            
            nodeID1=400000+Floor*1000+Axis*100+04;
            nodeID2=Floor*1000+Axis*100+40;
            ElemID=500000+1000*Floor+100*Axis+04;
            fprintf(INP,'element elasticBeamColumn %d %d %d %.3f $E [expr $Comp_I*%.3f*%.3f] 1; ',ElemID,nodeID1,nodeID2,A_AVG,I_AVG,factor_I_mod);
        
        elseif Axis==1
        
            nodeID1=400000+Floor*1000+Axis*100+04;
            nodeID2=Floor*1000+Axis*100+40;
            ElemID=500000+1000*Floor+100*Axis+04;
            fprintf(INP,'element elasticBeamColumn %d %d %d %.3f $E [expr $Comp_I*%.3f*%.3f] 1; ',ElemID,nodeID1,nodeID2,A_AVG,I_AVG,factor_I_mod);
        
        elseif Axis==NBay+1
            
            nodeID1=400000+Floor*1000+Axis*100+02;
            nodeID2=Floor*1000+Axis*100+20;
            ElemID=500000+1000*Floor+100*Axis+02;
            fprintf(INP,'element elasticBeamColumn %d %d %d %.3f $E [expr $Comp_I*%.3f*%.3f] 1; ',ElemID,nodeID1,nodeID2,A_AVG,I_AVG,factor_I_mod);
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');