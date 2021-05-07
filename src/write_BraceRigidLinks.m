function write_BraceRigidLinks (INP, NStory, NBay, FrameType, BraceLayout,PZ_Multiplier)


fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                          RIGID BRACE LINKS                                       #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# COMMAND SYNTAX \n');
fprintf(INP,'# element elasticBeamColumn $ElementID $NodeIDi $NodeIDj $Area $E $Inertia $transformation;\n');
fprintf(INP,'\n');

if FrameType==2
    fprintf(INP,'# MIDDLE RIGID LINKS\n');
    for Floor=NStory+1:-1:2
        if mod(Floor,2)==0 || BraceLayout==2
            for Bay=1:NBay
                nodeID1=200000+1000*Floor+100*Bay+1;
                nodeID2=200000+1000*Floor+100*Bay+2;
                nodeID3=200000+1000*Floor+100*Bay+3;
                nodeID4=200000+1000*Floor+100*Bay+4;
                nodeID5=200000+1000*Floor+100*Bay+5;
                ElemID22=700000+Floor*1000+Bay*100+22;
                ElemID33=700000+Floor*1000+Bay*100+33;
                ElemID44=700000+Floor*1000+Bay*100+44;
                ElemID55=700000+Floor*1000+Bay*100+55;
                ElemID66=700000+Floor*1000+Bay*100+66;
                ElemID77=700000+Floor*1000+Bay*100+77;
                fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_selected;\n',ElemID22, nodeID1,nodeID2);
                fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n', ElemID33, nodeID1,nodeID3);
                fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n', ElemID44, nodeID1,nodeID4);
                fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_selected;\n',ElemID55, nodeID1,nodeID5);
                if Floor<NStory+1 && BraceLayout==1
                    nodeID6=200000+1000*Floor+100*Bay+6;
                    nodeID7=200000+1000*Floor+100*Bay+7;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID66, nodeID1,nodeID6);
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID77, nodeID1,nodeID7);
                end
            end
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
end

%% FOR EBFs (under development)
if FrameType==3
    fprintf(INP,'# MIDDLE RIGID LINKS\n');
    for Floor=NStory+1:-1:2
        
        for Bay=1:NBay
            nodeID8=200000+1000*Floor+100*Bay+8;
            nodeID9=200000+1000*Floor+100*Bay+9;
            nodeID2=200000+1000*Floor+100*Bay+2;
            nodeID3=200000+1000*Floor+100*Bay+3;
            nodeID4=200000+1000*Floor+100*Bay+4;
            nodeID5=200000+1000*Floor+100*Bay+5;
            ElemID22=700000+Floor*1000+Bay*100+22;
            ElemID33=700000+Floor*1000+Bay*100+33;
            ElemID44=700000+Floor*1000+Bay*100+44;
            ElemID55=700000+Floor*1000+Bay*100+55;
            fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_selected;\n',ElemID22, nodeID8,nodeID2);
            fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n', ElemID33, nodeID8,nodeID3);
            if BraceLayout==1
                fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n', ElemID44, nodeID9,nodeID4);
                fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_selected;\n',ElemID55, nodeID9,nodeID5);
            end
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
end
%%


if FrameType==2
if PZ_Multiplier==1
    fprintf(INP,'# CORNER RIGID LINKS\n');
    for Floor=NStory+1:-1:1
        if mod(Floor,2)~=0 || BraceLayout==2
            for Axis=1:NBay+1
                ElemID11=700000+Floor*1000+Axis*100+11;
                ElemID99=700000+Floor*1000+Axis*100+99;
                if Floor~=1 && Floor~=NStory+1
                    if Axis==1; 		nodeID1=400000+1000*Floor+100*Axis+10;	end
                    if Axis==NBay+1; 	nodeID1=400000+1000*Floor+100*Axis+08;	end
                    nodeID2=100000+1000*Floor+100*Axis+40;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID11, nodeID1,nodeID2);
                    if BraceLayout==1
                        if Axis==1; 	 nodeID1=400000+1000*Floor+100*Axis+99; end
                        if Axis==NBay+1; nodeID1=400000+1000*Floor+100*Axis+06; end
                        nodeID2=100000+1000*Floor+100*Axis+50;
                        fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID99, nodeID1,nodeID2);
                    end
                end
                if Floor==NStory+1 && BraceLayout==1
                    if Axis==1; 	 nodeID1=400000+1000*Floor+100*Axis+99; end
                    if Axis==NBay+1; nodeID1=400000+1000*Floor+100*Axis+06; end
                    nodeID2=100000+1000*Floor+100*Axis+50;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID99, nodeID1,nodeID2);
                end
                if Floor==1
                    nodeID1=(10*Floor+Axis)*10;
                    nodeID2=100000+1000*Floor+100*Axis+40;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID11, nodeID1,nodeID2);
                end
            end
            fprintf(INP,'\n');
        end
    end
    fprintf(INP,'\n');
    
else
    
    fprintf(INP,'# CORNER RIGID LINKS\n');
    for Floor=NStory+1:-1:1
        if mod(Floor,2)~=0 || BraceLayout==2
            for Axis=1:NBay+1
                ElemID11=700000+Floor*1000+Axis*100+11;
                ElemID99=700000+Floor*1000+Axis*100+99;
                if Floor~=1 && Floor~=NStory+1
                    nodeID1=(10*Floor+Axis)*10;
                    nodeID2=100000+1000*Floor+100*Axis+40;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID11, nodeID1,nodeID2);
                    if BraceLayout==1
                        nodeID1=(10*Floor+Axis)*10;
                        nodeID2=100000+1000*Floor+100*Axis+50;
                        fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID99, nodeID1,nodeID2);
                    end
                end
                if Floor==NStory+1 && mod(Floor,2)~=0 && BraceLayout==1
                    nodeID1=(10*Floor+Axis)*10;
                    nodeID2=100000+1000*Floor+100*Axis+50;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID99, nodeID1,nodeID2);
                end
                if Floor==1
                    nodeID1=(10*Floor+Axis)*10;
                    nodeID2=100000+1000*Floor+100*Axis+40;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID11, nodeID1,nodeID2);
                end
            end
            fprintf(INP,'\n');
        end
    end
    fprintf(INP,'\n');
    
end

end



if FrameType==3
if PZ_Multiplier==1
    fprintf(INP,'# CORNER RIGID LINKS\n');
    for Floor=NStory+1:-1:1
            for Axis=1:NBay+1
                if BraceLayout==2 && Axis>1; break; end
                ElemID11=700000+Floor*1000+Axis*100+11;
                if Floor~=1 && Floor~=NStory+1
                    if Axis==1; 		nodeID1=400000+1000*Floor+100*Axis+10;	end
                    if Axis==NBay+1; 	nodeID1=400000+1000*Floor+100*Axis+08;	end
                    nodeID2=100000+1000*Floor+100*Axis+40;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID11, nodeID1,nodeID2);
                end
                if Floor==1
                    nodeID1=(10*Floor+Axis)*10;
                    nodeID2=100000+1000*Floor+100*Axis+40;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID11, nodeID1,nodeID2);
                end
            end
            fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
    
else
    
    fprintf(INP,'# CORNER RIGID LINKS\n');
    for Floor=NStory+1:-1:1
            for Axis=1:NBay+1
                ElemID11=700000+Floor*1000+Axis*100+11;
                if Floor~=1 && Floor~=NStory+1
                    nodeID1=(10*Floor+Axis)*10;
                    nodeID2=100000+1000*Floor+100*Axis+40;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID11, nodeID1,nodeID2);
                end
                if Floor==1
                    nodeID1=(10*Floor+Axis)*10;
                    nodeID2=100000+1000*Floor+100*Axis+40;
                    fprintf(INP,'element elasticBeamColumn %d %d %d $A_Stiff $E $I_Stiff  $trans_Corot;\n',ElemID11, nodeID1,nodeID2);
                end
            end
            fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
    
end

end