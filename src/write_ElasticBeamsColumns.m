function [EL_ELEMENTS] = write_ElasticBeamsColumns (INP, NStory, NBay, FrameType, BraceLayout, ColElementOption, MF_COLUMNS, MF_BEAMS, MF_SL, Splice, initialGI, nIntegration, Units)


fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                     ELASTIC COLUMNS AND BEAMS                                    #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# COMMAND SYNTAX \n');
fprintf(INP,'# element ModElasticBeam2d $ElementID $iNode $jNode $Area $E $Ix $K11 $K33 $K44 $transformation \n');
fprintf(INP,'\n');

fprintf(INP,'# STIFFNESS MODIFIERS\n');
fprintf(INP,'set n 10.;\n');
fprintf(INP,'set K44_2 [expr 6*(1+$n)/(2+3*$n)];\n');
fprintf(INP,'set K11_2 [expr (1+2*$n)*$K44_2/(1+$n)];\n');
fprintf(INP,'set K33_2 [expr (1+2*$n)*$K44_2/(1+$n)];\n');
fprintf(INP,'set K44_1 [expr 6*$n/(1+3*$n)];\n');
fprintf(INP,'set K11_1 [expr (1+2*$n)*$K44_1/(1+$n)];\n');
fprintf(INP,'set K33_1 [expr 2*$K44_1];\n');
fprintf(INP,'\n');

count=1;
fprintf(INP,'# COLUMNS\n');
secID=100;
for Story=NStory:-1:1
    Fi=Story; Fj=Story+1;
    if Splice(Story,1)==0
        for Axis=1:NBay+1
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            nodeIDb=100*Fi+10*Axis+03;
            nodeIDt=100*Fj+10*Axis+01;
            ElemID=600000+1000*Story+100*Axis;
            if ColElementOption==1
                fprintf(INP,'element ModElasticBeam2d %8d %8d %8d  %.4f $E [expr ($n+1)/$n*%.4f] $K11_2 $K33_2 $K44_2 $trans_selected; ',ElemID,nodeIDb,nodeIDt,SecData.Area(idx),SecData.Ix(idx));
            elseif ColElementOption==2
                secID=secID+1;
                fprintf(INP,'FiberWF  %5d 666 %.4f %.4f %.4f %.4f 6 2 6 2; ',secID,SecData.d(idx),SecData.bf(idx),SecData.tf(idx),SecData.tw(idx));
                fprintf(INP,'ConstructFiberColumn %d  %6d %6d %5d %d %.4f %d $trans_selected %d;\n',ElemID,nodeIDb,nodeIDt,secID, 5, initialGI, nIntegration,0);
            elseif ColElementOption==3
                secID=secID+1;
                fprintf(INP,'FiberWF  %5d 666 %.4f %.4f %.4f %.4f 6 2 6 2; ',secID,SecData.d(idx),SecData.bf(idx),SecData.tf(idx),SecData.tw(idx));
                fprintf(INP,'element nonlinearBeamColumn %d  %6d %6d  %d %d $trans_selected; ',ElemID,nodeIDb,nodeIDt,5,secID);
            end
            EL_ELEMENTS(count,1)=ElemID;
            count=count+1;
        end
    else
        for Axis=1:NBay+1
            ElemID01=600000+1000*Story+100*Axis+01;
            ElemID02=600000+1000*Story+100*Axis+02;
            Section=MF_COLUMNS{min(Story+1,NStory),Axis};
            [SecData]=Load_SecData (Section, Units);
            idx1=find(contains(SecData.Name,Section));
            nodeIDb=100*Fj+10*Axis+01;
            nodeIDsplice72=100000+1000*Story+100*Axis+72;
            if ColElementOption==1
                fprintf(INP,'element ModElasticBeam2d %8d %8d %8d %.4f $E [expr ($n+1)/$n*%.4f] $K33_1 $K11_1 $K44_1 $trans_selected;  ',ElemID02,nodeIDsplice72,nodeIDb,SecData.Area(idx1),SecData.Ix(idx1));
            elseif ColElementOption==2
                secID=secID+1;
                fprintf(INP,'FiberWF  %5d 666 %.4f %.4f %.4f %.4f 6 2 6 2; ',secID,SecData.d(idx1),SecData.bf(idx1),SecData.tf(idx1),SecData.tw(idx1));
                fprintf(INP,'ConstructFiberColumn %d  %6d %6d %5d %d %.4f %d $trans_selected %d;\n',ElemID02,nodeIDsplice72,nodeIDb,secID, 2, initialGI, nIntegration,2);
            elseif ColElementOption==3
                secID=secID+1;
                fprintf(INP,'FiberWF  %5d 666 %.4f %.4f %.4f %.4f 6 2 6 2; ',secID,SecData.d(idx1),SecData.bf(idx1),SecData.tf(idx1),SecData.tw(idx1));
                fprintf(INP,'element nonlinearBeamColumn %d  %6d %6d  %d %d $trans_selected; ',ElemID02,nodeIDsplice72,nodeIDb,5,secID);
            end
            EL_ELEMENTS(count,1)=ElemID02;
            count=count+1;
        end
        fprintf(INP,'\n');
        for Axis=1:NBay+1
            ElemID01=600000+1000*Story+100*Axis+01;
            ElemID02=600000+1000*Story+100*Axis+02;
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            nodeIDt=100*Fi+10*Axis+03;
            nodeIDsplice71=100000+1000*Story+100*Axis+71;
            if ColElementOption==1
                fprintf(INP,'element ModElasticBeam2d %8d %8d %8d %.4f $E [expr ($n+1)/$n*%.4f] $K33_1 $K11_1 $K44_1 $trans_selected;  ',ElemID01,nodeIDt,nodeIDsplice71,SecData.Area(idx),SecData.Ix(idx));
            elseif ColElementOption==2
                secID=secID+1;
                fprintf(INP,'FiberWF %6d 666 %.4f %.4f %.4f %.4f 6 2 6 2; ',secID,SecData.d(idx),SecData.bf(idx),SecData.tf(idx),SecData.tw(idx));
                fprintf(INP,'ConstructFiberColumn %7d  %7d %7d %5d %d %.4f %d $trans_selected %d;\n',ElemID01,nodeIDt,nodeIDsplice71,secID, 2, initialGI, nIntegration,1);
            elseif ColElementOption==3
                secID=secID+1;
                fprintf(INP,'FiberWF %6d 666 %.4f %.4f %.4f %.4f 6 2 6 2; ',secID,SecData.d(idx),SecData.bf(idx),SecData.tf(idx),SecData.tw(idx));
                fprintf(INP,'element nonlinearBeamColumn %7d  %7d %7d  %d %d $trans_selected; ',ElemID01,nodeIDt,nodeIDsplice71,5,secID);
            end
            EL_ELEMENTS(count,1)=ElemID01;
            count=count+1;
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');

fprintf(INP,'# BEAMS\n');
for Floor=NStory+1:-1:2
    if (FrameType==2 && BraceLayout==1 && mod(Floor,2)~=0) || FrameType==1
        for Bay=1:NBay
            Axisi=Bay; Axisj=Bay+1;
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            nodeIDr=100*Floor+10*Axisi+04;
            nodeIDl=100*Floor+10*Axisj+02;
            ElemID=500000+1000*Floor+100*Bay;
            fprintf(INP,'element ModElasticBeam2d %8d %8d %8d  %.4f $E [expr ($n+1)/$n*0.90*$Comp_I*%.4f] $K11_2 $K33_2 $K44_2 $trans_selected; ',ElemID,nodeIDr,nodeIDl,SecData.Area(idx),SecData.Ix(idx));
            EL_ELEMENTS(count,1)=ElemID;
            count=count+1;
        end
    else
        for Bay=1:NBay
            Axisi=Bay; Axisj=Bay+1;
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            nodeIDr =100*Floor+10*Axisi+04;
            nodeIDrC=200000+1000*Floor+100*Axisi+12;
            nodeIDl =100*Floor+10*Axisj+02;
            nodeIDlC=200000+1000*Floor+100*Axisi+15;
            ElemID01=500000+1000*Floor+100*Bay+01;
            ElemID02=500000+1000*Floor+100*Bay+02;
            fprintf(INP,'element ModElasticBeam2d %8d %8d %8d  %.4f $E [expr ($n+1)/$n*0.90*$Comp_I*%.4f] $K11_2 $K33_2 $K44_2 $trans_selected; ',ElemID01,nodeIDr,nodeIDrC,SecData.Area(idx),SecData.Ix(idx));
            EL_ELEMENTS(count,1)=ElemID01;
            count=count+1;
            if FrameType ==3 && BraceLayout ==2
            else
            fprintf(INP,'element ModElasticBeam2d %8d %8d %8d  %.4f $E [expr ($n+1)/$n*0.90*$Comp_I*%.4f] $K11_2 $K33_2 $K44_2 $trans_selected; ',ElemID02,nodeIDl,nodeIDlC,SecData.Area(idx),SecData.Ix(idx));
            EL_ELEMENTS(count,1)=ElemID02;
            count=count+1;
            end
        end
    end
    
    fprintf(INP,'\n');
end
fprintf(INP,'\n');



%% EBFs (under development)
if FrameType==3
fprintf(INP,'# EBF SHEAR LINKS\n');
for Floor=NStory+1:-1:2
        for Bay=1:NBay
            Axisi=Bay; Axisj=Bay+1;
            Section=MF_SL{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            nodeID08=200000+1000*Floor+100*Bay+8;
            nodeID09=200000+1000*Floor+100*Bay+9;
            nodeID02=400000+1000*Floor+100*Axisj+02;
            ElemID=500000+1000*Floor+100*Bay+03;
            
            secID=secID+1;
            fprintf(INP,'FiberWF  %5d 666 %.4f %.4f %.4f %.4f 6 2 6 2; ',secID,SecData.d(idx),SecData.bf(idx),SecData.tf(idx),SecData.tw(idx));
            if BraceLayout==1
                fprintf(INP,'ConstructFiberBeam %d  %6d %6d %5d %d %.4f %d $trans_selected %d;',ElemID,nodeID08,nodeID09,secID, 5, 0, nIntegration,0);
            else
                fprintf(INP,'ConstructFiberBeam %d  %6d %6d %5d %d %.4f %d $trans_selected %d;',ElemID,nodeID08,nodeID02,secID, 5, 0, nIntegration,0);
            end
        end
   
    fprintf(INP,'\n');
end
fprintf(INP,'\n');
end