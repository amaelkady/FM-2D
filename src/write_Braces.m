function write_Braces (INP, NStory, NBay, BRACES, Brace_L, FrameType, BraceLayout, nSegments, initialGI, nIntegration, Units)

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                 BRACE MEMBERS WITH FATIGUE MATERIAL                              #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# CREATE FATIGUE MATERIALS\n');
fprintf(INP,'# COMMAND SYNTAX \n');
fprintf(INP,'# FatigueMat $MatID $BraceSecType $fy $E $L_brace $ry_brace $ht_brace $htw_brace $bftf_brace;\n');
matID=100;
for Story=1:NStory
    Section=BRACES{Story,1};
    [SecData]=Load_SecData (Section, Units);
    idx=find(contains(SecData.Name,Section));
    if SecData.Type(idx) == 3
        fprintf(INP,'FatigueMat %d %d $fyB $E %.4f %.4f 0.0 %.4f %.4f;',matID,SecData.Type(idx),Brace_L(Story,1),SecData.ry(idx),SecData.h_t(idx),SecData.b_t(idx));
        matFatigue(Story) = matID+1;
        matID = matID + 2;
    else
        fprintf(INP,'FatigueMat %d %d $fyB $E %.4f %.4f %.4f  0.0 0.0;',matID,SecData.Type(idx),Brace_L(Story,1),SecData.ry(idx),SecData.h_t(idx));
        matFatigue(Story) = matID+1;
        matID = matID + 2;
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');

fprintf(INP,'# CREATE THE BRACE SECTIONS\n');
fprintf(INP,'# COMMAND SYNTAX \n');
fprintf(INP,'# FiberRHSS $BraceSecType $FatigueMatID $h_brace $t_brace $nFiber $nFiber $nFiber $nFiber;\n');
secID = 1;
for Story=1:NStory
    Section=BRACES{Story,1};
    [SecData]=Load_SecData (Section,Units);
    idx=find(contains(SecData.Name,Section));
    if SecData.Type(idx) == 1
        fprintf(INP,'FiberRHSS %5d %5d %.4f %.4f 10 4 10 4; ',secID,matFatigue(Story),SecData.h(idx),SecData.t(idx));
        secID = secID + 1;
    elseif SecData.Type(idx) == 2
        fprintf(INP,'FiberCHSS %5d %5d %.4f %.4f 12 4; ',secID,matFatigue(Story),SecData.h(idx),SecData.t(idx));
        secID = secID + 1;
    elseif SecData.Type(idx) == 3
        fprintf(INP,'FiberWF  %5d %5d %.4f %.4f %.4f %.4f 6 2 6 2; ',secID,matFatigue(Story),SecData.d(idx),SecData.bf(idx),SecData.tf(idx),SecData.tw(idx));
        secID = secID + 1;
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');


fprintf(INP,'# CONSTRUCT THE BRACE MEMBERS\n');
fprintf(INP,'# COMMAND SYNTAX \n');
fprintf(INP,'# ConstructBrace $BraceID $NodeIDi $NodeIDj $nSegments $Imperfeection $nIntgeration $transformation;\n');
if FrameType==2
    for Story=1:NStory
        Fi=Story; Fj=Story+1;
        for Bay=1:NBay
            Axisi=Bay; Axisj=Bay+1;
            if mod(Story,2)~=0 || BraceLayout==2
                % Left Brace
                iNode = 100000+1000*Fi+100*Axisi+41;
                jNode = 200000+1000*Fj+100*Bay+13;
                BraceID_L = 8100000+1000*Story+100*Bay;
                fprintf(INP,'ConstructBrace %d   %6d   %6d %5d   $nSegments $initialGI $nIntegration  $trans_Corot;\n',BraceID_L,iNode,jNode,Story);
                % Right Brace
                iNode = 100000+1000*Fi+100*Axisj+41;
                jNode = 200000+1000*Fj+100*Bay+14;
                BraceID_R = 8200000+1000*Story+100*Bay;
                fprintf(INP,'ConstructBrace %d   %6d   %6d %5d   $nSegments $initialGI $nIntegration  $trans_Corot;\n',BraceID_R,iNode,jNode,Story);
            else
                % Left Brace
                jNode = 200000+1000*Fi+100*Bay+17;
                iNode = 100000+1000*Fj+100*Axisi+51;
                BraceID_L = 8100000+1000*Story+100*Bay;
                fprintf(INP,'ConstructBrace %d   %6d   %6d %5d   $nSegments $initialGI $nIntegration  $trans_Corot;\n',BraceID_L,iNode,jNode,Story);
                % Right Brace
                jNode = 200000+1000*Fi+100*Bay+16;
                iNode = 100000+1000*Fj+100*Axisj+51;
                BraceID_R = 8200000+1000*Story+100*Bay;
                fprintf(INP,'ConstructBrace %d   %6d   %6d %5d   $nSegments $initialGI $nIntegration  $trans_Corot;\n',BraceID_R,iNode,jNode,Story);
            end
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
    
    
    %Ghost Trusses to the Braces (with very Small Stiffness) to Diminish
    %Convergence Problems and to Get the Deformation of the Brace Members
    matID=1000;
    fprintf(INP,'# CONSTRUCT THE GHOST BRACES\n');
    fprintf(INP,'uniaxialMaterial Elastic %d 100.0\n',matID);
    for Story=1:NStory
        Fi=Story; Fj=Story+1;
        for Bay=1:NBay
            if mod(Story,2)~=0 || BraceLayout==2
                iNode = 100000+1000*Fi+100*Axisi+41;
                jNode = 200000+1000*Fj+100*Bay+13;
                BraceID_L = 4100000+1000*Story+100*Bay;
                fprintf(INP,'element corotTruss %d   %6d   %6d  0.05 %5d;\n',BraceID_L,iNode,jNode,matID);
                iNode = 100000+1000*Fi+100*Axisj+41;
                jNode = 200000+1000*Fj+100*Bay+14;
                BraceID_R = 4200000+1000*Story+100*Bay;
                fprintf(INP,'element corotTruss %d   %6d   %6d  0.05 %5d;\n',BraceID_R,iNode,jNode,matID);
            else
                jNode = 200000+1000*Fi+100*Bay+17;
                iNode = 100000+1000*Fj+100*Axisi+51;
                BraceID_L = 4100000+1000*Story+100*Bay;
                fprintf(INP,'element corotTruss %d   %6d   %6d  0.05 %5d;\n',BraceID_L,iNode,jNode,matID);
                jNode = 200000+1000*Fi+100*Bay+16;
                iNode = 100000+1000*Fj+100*Axisj+51;
                BraceID_R = 4200000+1000*Story+100*Bay;
                fprintf(INP,'element corotTruss %d   %6d   %6d  0.05 %5d;\n',BraceID_R,iNode,jNode,matID);
                
            end
        end
    end
    fprintf(INP,'\n');
end






if FrameType==3
    for Story=1:NStory
        Fi=Story; Fj=Story+1;
        for Bay=1:NBay
            Axisi=Bay; Axisj=Bay+1;
            % Left Brace
            iNode = 100000+1000*Fi+100*Axisi+41;
            jNode = 200000+1000*Fj+100*Bay+13;
            BraceID_L = 8100000+1000*Story+100*Bay;
            fprintf(INP,'ConstructBrace %d   %6d   %6d %5d   $nSegments $initialGI $nIntegration  $trans_Corot;\n',BraceID_L,iNode,jNode,Story);
            if BraceLayout==1
                
                % Right Brace
                iNode = 100000+1000*Fi+100*Axisj+41;
                jNode = 200000+1000*Fj+100*Bay+14;
                BraceID_R = 8200000+1000*Story+100*Bay;
                fprintf(INP,'ConstructBrace %d   %6d   %6d %5d   $nSegments $initialGI $nIntegration  $trans_Corot;\n',BraceID_R,iNode,jNode,Story);
            end
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
    
    
    %Ghost Trusses to the Braces (with very Small Stiffness) to Diminish
    %Convergence Problems and to Get the Deformation of the Brace Members
    matID=1000;
    fprintf(INP,'# CONSTRUCT THE GHOST BRACES\n');
    fprintf(INP,'uniaxialMaterial Elastic %d 100.0\n',matID);
    for Story=1:NStory
        Fi=Story; Fj=Story+1;
        for Bay=1:NBay
            iNode = 100000+1000*Fi+100*Axisi+41;
            jNode = 200000+1000*Fj+100*Bay+13;
            BraceID_L = 4100000+1000*Story+100*Bay;
            fprintf(INP,'element corotTruss %d   %6d   %6d  0.05 %5d;\n',BraceID_L,iNode,jNode,matID);
            if BraceLayout==1
                iNode = 100000+1000*Fi+100*Axisj+41;
                jNode = 200000+1000*Fj+100*Bay+14;
                BraceID_R = 4200000+1000*Story+100*Bay;
                fprintf(INP,'element corotTruss %d   %6d   %6d  0.05 %5d;\n',BraceID_R,iNode,jNode,matID);
            end
        end
    end
    fprintf(INP,'\n');
end