function write_PZspring(INP,NStory,NBay,PZ_Multiplier,EL_Multiplier,CompositeX,MF_COLUMNS,MF_BEAMS,Doubler,trib,ts,mu,Units)

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                          PANEL ZONE SPRINGS                                      #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

SH_Panel=0.03;

if PZ_Multiplier==1
    fprintf(INP,'# COMMAND SYNTAX \n');
    fprintf(INP,'# Spring_PZ    Element_ID Node_i Node_j E mu fy tw_Col tdp d_Col d_Beam tf_Col bf_Col Ic trib ts Response_ID transfTag\n');
    for Floor=NStory+1:-1:2
        Story=min(NStory,Floor);
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section,Units);
            idx1=find(contains(SecData.Name,Section));
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section,Units);
            idx2=find(contains(SecData.Name,Section));
            SpringID=900000+Floor*1000+Axis*100+00;
            node1=400000+Floor*1000+Axis*100+09;
            node2=400000+Floor*1000+Axis*100+10;
            if CompositeX == 0; Response_ID=2; end
            if CompositeX ~= 0; Response_ID=2; end
            if CompositeX ~= 0 &&  Axis~=1 && Axis~=NBay+1; Response_ID=0; end
            
            fprintf(INP,'Spring_PZ    %d %d %d $E $mu [expr $fy * %5.1f] %5.2f  %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f %5.3f %5.3f %d 1; ',SpringID,node1,node2,EL_Multiplier,SecData.tw(idx1),Doubler(Floor-1,Axis),SecData.d(idx1),SecData.d(idx2),SecData.tf(idx1),SecData.bf(idx1),SecData.Ix(idx1),trib,ts,Response_ID);
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
end