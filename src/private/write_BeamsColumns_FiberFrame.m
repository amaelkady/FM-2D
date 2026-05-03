function [EL_ELEMENTS] = write_BeamsColumns_FiberFrame (INP, NStory, NBay, ColElementOption, MF_COLUMNS, MF_BEAMS, nIntegration, coeff_cracked)

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                     ELASTIC COLUMNS AND BEAMS                                    #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

count=1;
fprintf(INP,'# COLUMNS\n');
secID=100;
matID=777;
for Story=NStory:-1:1
    Fi=Story; Fj=Story+1;
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,Axis};
        [SecData]=Load_SecData_RC (Section);
        
        nodeIDb=100*Fi+10*Axis;
        nodeIDt=100*Fj+10*Axis;
        ElemID=600000+1000*Story+100*Axis;
        
        if ColElementOption==1
            secID=secID+1;
            Area=SecData.H*SecData.B;
            Iz= coeff_cracked*1./12*SecData.B*SecData.H^3;
            fprintf(INP,'section Elastic %8d $Ec %.4f %.4f; ',secID,Area,Iz);
            fprintf(INP,'element nonlinearBeamColumn %d  %6d %6d  %d %d $trans_selected;\n',ElemID,nodeIDb,nodeIDt,nIntegration,secID);
        elseif ColElementOption==2
            secID=secID+1;
            matID=matID+1;
            fprintf(INP,'FiberRC_Rectangular %5d %.4f %.4f %.4f %.4f %2d %.4f %2d %.4f  %2d %.4f; ',secID,SecData.H,SecData.B,SecData.coverH,SecData.coverB,SecData.nBarTop,SecData.areaBarTop,SecData.nBarBot,SecData.areaBarBot,SecData.nBarInt,SecData.areaBarInt); 
            fprintf(INP,'ConstructFiberColumn %d  %6d %6d %5d %d %.4f %d $trans_selected %d;\n',ElemID,nodeIDb,nodeIDt,secID, 5, nIntegration,0);
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
        
        nodeIDl=100*Floor+10*Axisi;
        nodeIDr=100*Floor+10*Axisj;
        ElemID=500000+1000*Floor+100*Bay;
        
        secID=secID+1;
        matID=matID+1;
        fprintf(INP,'FiberRC_Rectangular %5d %.4f %.4f %.4f %.4f %2d %.4f %2d %.4f  %2d %.4f; ',secID,SecData.H,SecData.B,SecData.coverH,SecData.coverB,SecData.nBarTop,SecData.areaBarTop,SecData.nBarBot,SecData.areaBarBot,SecData.nBarInt,SecData.areaBarInt); 
        fprintf(INP,'element nonlinearBeamColumn %d  %6d %6d  %d %d $trans_selected;\n',ElemID,nodeIDl,nodeIDr,nIntegration,secID);
        EL_ELEMENTS(count,1)=ElemID;
        count=count+1;
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');
