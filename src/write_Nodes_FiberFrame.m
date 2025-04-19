function write_Nodes_FiberFrame (INP, NStory, NBay, HStory)

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

fprintf(INP,'# MF NODES\n');
for Floor=NStory+1:-1:1
    if Floor~=1 
        for Axis=1:NBay+1
            nodeID=(10*Floor+Axis)*10;
            fprintf(INP,'node %d  $Axis%d $Floor%d; ',nodeID,Axis,Floor);
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');

