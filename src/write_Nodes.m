function write_Nodes (INP, NStory, NBay, FrameType, BraceLayout, MF_COLUMNS, MF_BEAMS, MGP_W, EBF_W, Splice, HStory, PZ_Multiplier, MFconnection, Units)

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                                  NODES                                           #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# COMMAND SYNTAX \n');
fprintf(INP,'# node $NodeID  $X-Coordinate  $Y-Coordinate;\n');
fprintf(INP,'\n');

fprintf(INP,'#SUPPORT NODES\n');
for Axis=1:NBay+3
    nodeID=(10*1+Axis)*10;
    fprintf(INP,'node %d   $Axis%d  $Floor1; ',nodeID,Axis);
end
fprintf(INP,'\n\n');

fprintf(INP,'# EGF COLUMN GRID NODES\n');
for Floor=NStory+1:-1:2
    for Axis=NBay+2:NBay+3
        nodeID=(10*Floor+Axis)*10;
        fprintf(INP,'node %d   $Axis%d  $Floor%d; ',nodeID,Axis,Floor);
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');


fprintf(INP,'# EGF COLUMN NODES\n');
for Floor=NStory+1:-1:1
    if Floor==NStory+1
        for Axis=NBay+2:NBay+3
            nodeID=100*Floor+10*Axis+01;
            fprintf(INP,'node %d  $Axis%d  $Floor%d; ',nodeID,Axis,Floor);
        end
    end
    if Floor~=1 && Floor~=NStory+1
        for Axis=NBay+2:NBay+3
            nodeID=100*Floor+10*Axis+03;
            fprintf(INP,'node %d  $Axis%d  $Floor%d; ',nodeID,Axis,Floor);
        end
        fprintf(INP,'\n');
        for Axis=NBay+2:NBay+3
            nodeID=100*Floor+10*Axis+01;
            fprintf(INP,'node %d  $Axis%d  $Floor%d; ',nodeID,Axis,Floor);
        end
    end
    if Floor==1
        for Axis=NBay+2:NBay+3
            nodeID=100*Floor+10*Axis+03;
            fprintf(INP,'node %d  $Axis%d  $Floor%d; ',nodeID,Axis,Floor);
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');

fprintf(INP,'# EGF BEAM NODES\n');
for Floor=NStory+1:-1:2
    for Axis=NBay+2:NBay+3
        if Axis==NBay+2
            nodeID=100*Floor+10*Axis+04;
            fprintf(INP,'node %d  $Axis%d  $Floor%d; ',nodeID,Axis,Floor);
        end
        if Axis==NBay+3
            nodeID=100*Floor+10*Axis+02;
            fprintf(INP,'node %d  $Axis%d  $Floor%d; ',nodeID,Axis,Floor);
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');


fprintf(INP,'# MF COLUMN NODES\n');
for Floor=NStory+1:-1:1
    if Floor==NStory+1
        for Axis=1:NBay+1
            nodeID=100*Floor+10*Axis+01;
            Bay=max(1,Axis-1);
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            fprintf(INP,'node %d  $Axis%d [expr $Floor%d - %5.2f/2]; ',nodeID,Axis,Floor,SecData.d(idx));
        end
    end
    if Floor~=1 && Floor~=NStory+1
        for Axis=1:NBay+1
            nodeID=100*Floor+10*Axis+03;
            Bay=max(1,Axis-1);
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            fprintf(INP,'node %d  $Axis%d [expr $Floor%d + %5.2f/2]; ',nodeID,Axis,Floor,SecData.d(idx));
        end
        fprintf(INP,'\n');
        for Axis=1:NBay+1
            nodeID=100*Floor+10*Axis+01;
            Bay=max(1,Axis-1);
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            fprintf(INP,'node %d  $Axis%d [expr $Floor%d - %5.2f/2]; ',nodeID,Axis,Floor,SecData.d(idx));
        end
    end
    if Floor==1
        for Axis=1:NBay+1
            nodeID=100*Floor+10*Axis+03;
            fprintf(INP,'node %d  $Axis%d $Floor%d; ',nodeID,Axis,Floor);
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');

if FrameType~=1
    fprintf(INP,'# MF BEAM NODES\n');
    for Floor=NStory+1:-1:2
        Story=Floor-1;
        for Axis=1:NBay+1
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            if Axis==1
                nodeID=100*Floor+10*Axis+04;
                fprintf(INP,'node %d   [expr $Axis%d + %5.2f/2] $Floor%d; ',nodeID,Axis,SecData.d(idx),Floor);
            end
            if Axis~=1 && Axis~=NBay+1
                nodeIDr=100*Floor+10*Axis+04;
                nodeIDl=100*Floor+10*Axis+02;
                if FrameType==3 && BraceLayout==2
                else
                    fprintf(INP,'node %d   [expr $Axis%d - %5.2f/2] $Floor%d; ',nodeIDl,Axis,SecData.d(idx),Floor);
                end
                fprintf(INP,'node %d   [expr $Axis%d + %5.2f/2] $Floor%d; ',nodeIDr,Axis,SecData.d(idx),Floor);
            end
            if Axis==NBay+1
                nodeID=100*Floor+10*Axis+02;
                if FrameType==3 && BraceLayout==2
                else
                    fprintf(INP,'node %d   [expr $Axis%d - %5.2f/2] $Floor%d; ',nodeID,Axis,SecData.d(idx),Floor);
                end
            end
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
end

if FrameType==1
    
    fprintf(INP,'# MF BEAM NODES\n');
    for Floor=NStory+1:-1:2
        for Axis=1:NBay+1
            Story=Floor-1;
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section,Units);
            idx=find(contains(SecData.Name,Section));
            
            nodeID04=100*Floor+10*Axis+04;
            nodeID02=100*Floor+10*Axis+02;
            
            if Axis==1
                fprintf(INP,'node %d   [expr $Axis%d + $L_RBS%d + %5.2f/2] $Floor%d; ',nodeID04,Axis,Floor,SecData.d(idx),Floor);
            end
            if Axis~=1 && Axis~=NBay+1
                fprintf(INP,'node %d   [expr $Axis%d - $L_RBS%d - %5.2f/2] $Floor%d; ',nodeID02,Axis,Floor,SecData.d(idx),Floor);
                fprintf(INP,'node %d   [expr $Axis%d + $L_RBS%d + %5.2f/2] $Floor%d; ',nodeID04,Axis,Floor,SecData.d(idx),Floor);
            end
            if Axis==NBay+1
                fprintf(INP,'node %d   [expr $Axis%d - $L_RBS%d - %5.2f/2] $Floor%d; ',nodeID02,Axis,Floor,SecData.d(idx),Floor);
            end
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
    
    fprintf(INP,'# BEAM SPRING NODES\n');
    for Floor=NStory+1:-1:2
        Story=Floor-1;
        for Axis=1:NBay+1
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section,Units);
            idx=find(contains(SecData.Name,Section));
            
            nodeID40=1000*Floor+100*Axis+40;
            nodeID20=1000*Floor+100*Axis+20;
            
            if Axis==1
                fprintf(INP,'node %d   [expr $Axis%d + $L_RBS%d + %5.2f/2] $Floor%d; ',nodeID40,Axis,Floor,SecData.d(idx),Floor);
            end
            if Axis~=1 && Axis~=NBay+1
                fprintf(INP,'node %d   [expr $Axis%d - $L_RBS%d - %5.2f/2] $Floor%d; ',nodeID20,Axis,Floor,SecData.d(idx),Floor);
                fprintf(INP,'node %d   [expr $Axis%d + $L_RBS%d + %5.2f/2] $Floor%d; ',nodeID40,Axis,Floor,SecData.d(idx),Floor);
            end
            if Axis==NBay+1
                fprintf(INP,'node %d   [expr $Axis%d - $L_RBS%d - %5.2f/2] $Floor%d; ',nodeID20,Axis,Floor,SecData.d(idx),Floor);
            end
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
end

if any(Splice(:) == 1)
    fprintf(INP,'# COLUMN SPLICE NODES\n');
    for Story=NStory:-1:1
        Fi=Story;
        if Splice(Story,1)==1
            for Axis=1:NBay+3
                nodeID72=100000+1000*Story+100*Axis+72;
                fprintf(INP,'node %d $Axis%d [expr ($Floor%d + %.2f * %d)]; ',nodeID72,Axis,Fi,Splice(Story,2),HStory(Story));
            end
            fprintf(INP,'\n');
            for Axis=1:NBay+3
                nodeID71=100000+1000*Story+100*Axis+71;
                fprintf(INP,'node %d $Axis%d [expr ($Floor%d + %.2f * %d)]; ',nodeID71,Axis,Fi,Splice(Story,2),HStory(Story));
            end
            fprintf(INP,'\n');
        end
    end
    fprintf(INP,'\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if FrameType==2
    
    fprintf(INP,'# MID-SPAN GUSSET PLATE RIGID OFFSET NODES\n');
    for Floor=NStory+1:-1:2
        Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
        if mod(Floor,2)==0 || BraceLayout==2
            for Bay=1:NBay
                Axisi=Bay; Axisj=Bay+1;
                nodeID=200000+1000*Floor+100*Bay+1;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2] $Floor%d;\n',nodeID,Axisi,Axisj,Floor);
                nodeID=200000+1000*Floor+100*Bay+2;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - %.4f/2] $Floor%d;\n',nodeID,Axisi,Axisj,MGP_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+12;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - %.4f/2] $Floor%d;\n',nodeID,Axisi,Axisj,MGP_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+5;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + %.4f/2] $Floor%d;\n',nodeID,Axisi,Axisj,MGP_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+15;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + %.4f/2] $Floor%d;\n',nodeID,Axisi,Axisj,MGP_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+4;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + $X_MGP%d] [expr $Floor%d - $Y_MGP%d];\n',nodeID,Axisi,Axisj,Storyi,Floor,Storyi);
                nodeID=200000+1000*Floor+100*Bay+14;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + $X_MGP%d] [expr $Floor%d - $Y_MGP%d];\n',nodeID,Axisi,Axisj,Storyi,Floor,Storyi);
                nodeID=200000+1000*Floor+100*Bay+3;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - $X_MGP%d] [expr $Floor%d - $Y_MGP%d];\n',nodeID,Axisi,Axisj,Storyi,Floor,Storyi);
                nodeID=200000+1000*Floor+100*Bay+13;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - $X_MGP%d] [expr $Floor%d - $Y_MGP%d];\n',nodeID,Axisi,Axisj,Storyi,Floor,Storyi);
                if Floor<NStory+1 && BraceLayout==1
                    nodeID=200000+1000*Floor+100*Bay+6;
                    fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + $X_MGP%d] [expr $Floor%d + $Y_MGP%d];\n',nodeID,Axisi,Axisj,Storyj,Floor,Storyj);
                    nodeID=200000+1000*Floor+100*Bay+16;
                    fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + $X_MGP%d] [expr $Floor%d + $Y_MGP%d];\n',nodeID,Axisi,Axisj,Storyj,Floor,Storyj);
                    nodeID=200000+1000*Floor+100*Bay+7;
                    fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - $X_MGP%d] [expr $Floor%d + $Y_MGP%d];\n',nodeID,Axisi,Axisj,Storyj,Floor,Storyj);
                    nodeID=200000+1000*Floor+100*Bay+17;
                    fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - $X_MGP%d] [expr $Floor%d + $Y_MGP%d];\n',nodeID,Axisi,Axisj,Storyj,Floor,Storyj);
                end
            end
        end
    end
    fprintf(INP,'\n');
    
    fprintf(INP,'# CORNER X-BRACING RIGID OFFSET NODES\n');
    for Floor=NStory+1:-1:1
        Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
        if mod(Floor,2)~=0 || BraceLayout==2
            for Axis=1:NBay+1
                if Axis==1
                    if Floor~=1 && Floor~=NStory+1
                        nodeID=100000+1000*Floor+100*Axis+40;
                        fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                        nodeID=100000+1000*Floor+100*Axis+41;
                        fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                        if BraceLayout==1
                            nodeID=100000+1000*Floor+100*Axis+50;
                            fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d - $Y_CGP%d];\n',nodeID,Axis,Storyi,Floor,Storyi);
                            nodeID=100000+1000*Floor+100*Axis+51;
                            fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d - $Y_CGP%d];\n',nodeID,Axis,Storyi,Floor,Storyi);
                        end
                    elseif Floor==NStory+1 && BraceLayout==1
                        nodeID=100000+1000*Floor+100*Axis+50;
                        fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d - $Y_CGP%d];\n',nodeID,Axis,Storyi,Floor,Storyi);
                        nodeID=100000+1000*Floor+100*Axis+51;
                        fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d - $Y_CGP%d];\n',nodeID,Axis,Storyi,Floor,Storyi);
                    elseif Floor==1
                        nodeID=100000+1000*Floor+100*Axis+40;
                        fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                        nodeID=100000+1000*Floor+100*Axis+41;
                        fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                    end
                end
                
                if Axis==NBay+1
                    if Floor~=1 && Floor~=NStory+1
                        nodeID=100000+1000*Floor+100*Axis+40;
                        fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                        nodeID=100000+1000*Floor+100*Axis+41;
                        fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                        if BraceLayout==1
                            nodeID=100000+1000*Floor+100*Axis+50;
                            fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d - $Y_CGP%d];\n',nodeID,Axis,Storyi,Floor,Storyi);
                            nodeID=100000+1000*Floor+100*Axis+51;
                            fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d - $Y_CGP%d];\n',nodeID,Axis,Storyi,Floor,Storyi);
                        end
                    elseif Floor==NStory+1 && BraceLayout==1
                        nodeID=100000+1000*Floor+100*Axis+50;
                        fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d - $Y_CGP%d];\n',nodeID,Axis,Storyi,Floor,Storyi);
                        nodeID=100000+1000*Floor+100*Axis+51;
                        fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d - $Y_CGP%d];\n',nodeID,Axis,Storyi,Floor,Storyi);
                    elseif Floor==1
                        nodeID=100000+1000*Floor+100*Axis+40;
                        fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                        nodeID=100000+1000*Floor+100*Axis+41;
                        fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                    end
                end
                
            end
        end
    end
    fprintf(INP,'\n');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%NEW CODE FOR EBFs (under development)

if FrameType==3
    if BraceLayout==1
        fprintf(INP,'# MID-SPAN GUSSET PLATE RIGID OFFSET NODES\n');
        for Floor=NStory+1:-1:2
            Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
            for Bay=1:NBay
                Axisi=Bay; Axisj=Bay+1;
                nodeID=200000+1000*Floor+100*Bay+8;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - %.4f/2] $Floor%d;\n',nodeID,Axisi,Axisj,EBF_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+9;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + %.4f/2] $Floor%d;\n',nodeID,Axisi,Axisj,EBF_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+2;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - %.4f/2 - %.4f] $Floor%d;\n',nodeID,Axisi,Axisj,EBF_W(Storyi,1),MGP_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+12;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - %.4f/2 - %.4f] $Floor%d;\n',nodeID,Axisi,Axisj,EBF_W(Storyi,1),MGP_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+5;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + %.4f/2 + %.4f] $Floor%d;\n',nodeID,Axisi,Axisj,EBF_W(Storyi,1),MGP_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+15;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + %.4f/2 + %.4f] $Floor%d;\n',nodeID,Axisi,Axisj,EBF_W(Storyi,1),MGP_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+4;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + %.4f/2 + $X_MGP%d] [expr $Floor%d - $Y_MGP%d];\n',nodeID,Axisi,Axisj,EBF_W(Storyi,1),Storyi,Floor,Storyi);
                nodeID=200000+1000*Floor+100*Bay+14;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 + %.4f/2 + $X_MGP%d] [expr $Floor%d - $Y_MGP%d];\n',nodeID,Axisi,Axisj,EBF_W(Storyi,1),Storyi,Floor,Storyi);
                nodeID=200000+1000*Floor+100*Bay+3;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - %.4f/2 - $X_MGP%d] [expr $Floor%d - $Y_MGP%d];\n',nodeID,Axisi,Axisj,EBF_W(Storyi,1),Storyi,Floor,Storyi);
                nodeID=200000+1000*Floor+100*Bay+13;
                fprintf(INP,'node %d   [expr ($Axis%d + $Axis%d)/2 - %.4f/2 - $X_MGP%d] [expr $Floor%d - $Y_MGP%d];\n',nodeID,Axisi,Axisj,EBF_W(Storyi,1),Storyi,Floor,Storyi);
            end
        end
        fprintf(INP,'\n');
        
        fprintf(INP,'# CORNER X-BRACING RIGID OFFSET NODES\n');
        for Floor=NStory+1:-1:1
            Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
            for Axis=1:NBay+1
                if Axis==1
                    if Floor~=1 && Floor~=NStory+1
                        nodeID=100000+1000*Floor+100*Axis+40;
                        fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                        nodeID=100000+1000*Floor+100*Axis+41;
                        fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                    elseif Floor==1
                        nodeID=100000+1000*Floor+100*Axis+40;
                        fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                        nodeID=100000+1000*Floor+100*Axis+41;
                        fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                    end
                end
                
                if Axis==NBay+1
                    if Floor~=1 && Floor~=NStory+1
                        nodeID=100000+1000*Floor+100*Axis+40;
                        fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                        nodeID=100000+1000*Floor+100*Axis+41;
                        fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                    elseif Floor==1
                        nodeID=100000+1000*Floor+100*Axis+40;
                        fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                        nodeID=100000+1000*Floor+100*Axis+41;
                        fprintf(INP,'node %d   [expr $Axis%d - $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
                    end
                end
                
            end
        end
    end
    fprintf(INP,'\n');
    
    
    
    
    
    if BraceLayout==2
        fprintf(INP,'# MID-SPAN GUSSET PLATE RIGID OFFSET NODES\n');
        for Floor=NStory+1:-1:2
            Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
            Story=Floor-1;
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section,Units);
            idx=find(contains(SecData.Name,Section));
            
            for Bay=1:NBay
                Axisi=Bay; Axisj=Bay+1;
                nodeID=200000+1000*Floor+100*Bay+8;
                fprintf(INP,'node %d   [expr $Axis%d - %.4f/2 - %.4f]        $Floor%d;\n',nodeID,Axisj,SecData.d(idx),EBF_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+2;
                fprintf(INP,'node %d   [expr $Axis%d - %.4f/2 - %.4f - %.4f] $Floor%d;\n',nodeID,Axisj,SecData.d(idx),EBF_W(Storyi,1),MGP_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+12;
                fprintf(INP,'node %d   [expr $Axis%d - %.4f/2 - %.4f - %.4f] $Floor%d;\n',nodeID,Axisj,SecData.d(idx),EBF_W(Storyi,1),MGP_W(Storyi,1),Floor);
                nodeID=200000+1000*Floor+100*Bay+3;
                fprintf(INP,'node %d   [expr $Axis%d - %.4f/2 - %.4f - $X_MGP%d] [expr $Floor%d - $Y_MGP%d];\n',nodeID,Axisj,SecData.d(idx),EBF_W(Storyi,1),Storyi,Floor,Storyi);
                nodeID=200000+1000*Floor+100*Bay+13;
                fprintf(INP,'node %d   [expr $Axis%d - %.4f/2 - %.4f - $X_MGP%d] [expr $Floor%d - $Y_MGP%d];\n',nodeID,Axisj,SecData.d(idx),EBF_W(Storyi,1),Storyi,Floor,Storyi);
            end
        end
        fprintf(INP,'\n');
        
        fprintf(INP,'# CORNER X-BRACING RIGID OFFSET NODES\n');
        for Floor=NStory:-1:1
            Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
            Axis=1;
            nodeID=100000+1000*Floor+100*Axis+40;
            fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
            nodeID=100000+1000*Floor+100*Axis+41;
            fprintf(INP,'node %d   [expr $Axis%d + $X_CGP%d] [expr $Floor%d + $Y_CGP%d];\n',nodeID,Axis,Storyj,Floor,Storyj);
            
        end
        fprintf(INP,'\n');
    end
end