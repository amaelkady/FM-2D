function write_BCs_FiberFrame (INP,NStory,NBay,RigidFloor,Support)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                       BOUNDARY CONDITIONS                                       #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# MF SUPPORTS\n');
for Axis=1:NBay+1
    nodeID=(10*1+Axis)*10;
    if Support==1
        fprintf(INP,'fix %d 1 1 1; ', nodeID);
    else
        fprintf(INP,'fix %d 1 1 0; ', nodeID);
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');

fprintf(INP,'# EGF SUPPORTS\n');
for Axis=NBay+2:NBay+3
    nodeID=(10*1+Axis)*10;
    fprintf(INP,'fix %d 1 1 0; ', nodeID);
end
fprintf(INP,'\n\n');

if RigidFloor==1
    fprintf(INP,'# MF FLOOR MOVEMENT\n');
    for Floor=NStory+1:-1:2
        node0 = 100*Floor+10*1;
        for Axis=2:NBay+1
            node1 = 100*Floor+10*Axis;
            fprintf(INP,'equalDOF %d %d 1; ',node0,node1);
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');

    fprintf(INP,'# EGF FLOOR MOVEMENT\n');
    for Floor=NStory+1:-1:2
        nodeID0 = (10*Floor+(NBay+2))*10;
        nodeID1 = (10*Floor+(NBay+3))*10;
        fprintf(INP,'equalDOF %d %d 1;\n',nodeID0,nodeID1);
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');
    

fprintf(INP,'##################################################################################################\n');
fprintf(INP,'##################################################################################################\n');
fprintf(INP,'                                       puts "Model Built"\n');
fprintf(INP,'##################################################################################################\n');
fprintf(INP,'##################################################################################################\n');
fprintf(INP,'\n');