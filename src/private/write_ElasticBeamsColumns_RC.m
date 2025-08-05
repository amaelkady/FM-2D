function [EL_ELEMENTS] = write_ElasticBeamsColumns_RC (INP, NStory, NBay, ColElementOption, BeamElementOption, MF_COLUMNS, MF_BEAMS, nIntegration,coeff_cracked)


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
matID=666;
for Story=NStory:-1:1
    Fi=Story; Fj=Story+1;
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,Axis};
        [SecData]=Load_SecData_RC (Section);
        Area = SecData.B*SecData.H;
        Ix   = coeff_cracked*SecData.B*SecData.H^3/12;

        nodeIDb=100*Fi+10*Axis+03;
        nodeIDt=100*Fj+10*Axis+01;
        ElemID=600000+1000*Story+100*Axis;
        if ColElementOption==1
            fprintf(INP,'element ModElasticBeam2d %8d %8d %8d  %.4f $E [expr ($n+1)/$n*%.4f] $K11_2 $K33_2 $K44_2 $trans_selected; ',ElemID,nodeIDb,nodeIDt,Area,Ix);
        elseif ColElementOption==2
            secID=secID+1;
            matID=matID+1;
            fprintf(INP,'FiberRC_Rectangular %5d %.4f %.4f %.4f %.4f %2d %.4f %2d %.4f  %2d %.4f; ',secID,SecData.H,SecData.B,SecData.coverH,SecData.coverB,SecData.nBarTop,SecData.areaBarTop,SecData.nBarBot,SecData.areaBarBot,SecData.nBarInt,SecData.areaBarInt); 
            fprintf(INP,'ConstructFiberColumn %d  %6d %6d %5d %d %.4f %d $trans_selected %d;\n',ElemID,nodeIDb,nodeIDt,secID, 5, 0, nIntegration,0);
        elseif ColElementOption==3
            secID=secID+1;
            matID=matID+1;
            fprintf(INP,'FiberRC_Rectangular %5d %.4f %.4f %.4f %.4f %2d %.4f %2d %.4f  %2d %.4f; ',secID,SecData.H,SecData.B,SecData.coverH,SecData.coverB,SecData.nBarTop,SecData.areaBarTop,SecData.nBarBot,SecData.areaBarBot,SecData.nBarInt,SecData.areaBarInt); 
            fprintf(INP,'element nonlinearBeamColumn %d  %6d %6d  %d %d $trans_selected;\n',ElemID,nodeIDb,nodeIDt,nIntegration,secID);
        end
        EL_ELEMENTS(count,1)=ElemID;
        count=count+1;
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');

fprintf(INP,'# BEAMS\n');
for Floor=NStory+1:-1:2
    for Bay=1:NBay
        Axisi=Bay; Axisj=Bay+1;
        Section=MF_BEAMS{Floor-1,Bay};
        [SecData]=Load_SecData_RC (Section);
        
        Area = SecData.B*SecData.H;
        Ix   = coeff_cracked*SecData.B*SecData.H^3/12;

        nodeIDl=100*Floor+10*Axisi+04;
        nodeIDr=100*Floor+10*Axisj+02;
        ElemID=500000+1000*Floor+100*Bay;
        
        if BeamElementOption==1
            fprintf(INP,'element ModElasticBeam2d %8d %8d %8d  %.4f $E [expr ($n+1)/$n*0.90*%.4f] $K11_2 $K33_2 $K44_2 $trans_selected; ',ElemID,nodeIDl,nodeIDr,Area,Ix);
        elseif BeamElementOption==2
            secID=secID+1;
            matID=matID+1;
            fprintf(INP,'FiberRC_Rectangular %5d %.4f %.4f %.4f %.4f %2d %.4f %2d %.4f  %2d %.4f; ',secID,SecData.H,SecData.B,SecData.coverH,SecData.coverB,SecData.nBarTop,SecData.areaBarTop,SecData.nBarBot,SecData.areaBarBot,SecData.nBarInt,SecData.areaBarInt); 
            fprintf(INP,'ConstructFiberBeam %d  %6d %6d %5d %d %.4f %d $trans_selected %d;\n',ElemID,nodeIDl,nodeIDr,secID, 5, 0, nIntegration,0);
        elseif BeamElementOption==3
            secID=secID+1;
            matID=matID+1;
            fprintf(INP,'FiberRC_Rectangular %5d %.4f %.4f %.4f %.4f %2d %.4f %2d %.4f  %2d %.4f; ',secID,SecData.H,SecData.B,SecData.coverH,SecData.coverB,SecData.nBarTop,SecData.areaBarTop,SecData.nBarBot,SecData.areaBarBot,SecData.nBarInt,SecData.areaBarInt); 
            fprintf(INP,'element nonlinearBeamColumn %d  %6d %6d  %d %d $trans_selected;\n',ElemID,nodeIDl,nodeIDr,nIntegration,secID);
        end
        
        EL_ELEMENTS(count,1)=ElemID;
        count=count+1;
        
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');


end