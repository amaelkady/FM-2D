function write_BCs (INP,FrameType,NStory,NBay,PZ_Multiplier,RigidFloor,Support,MidSpanConstraint,BraceLayout)

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

if PZ_Multiplier==1
    if RigidFloor==1
        fprintf(INP,'# MF FLOOR MOVEMENT\n');
        for Floor=NStory+1:-1:2
            node0 = 400000+1000*Floor+100*1+04;
            for Axis=2:NBay+1
                node1 = 400000+1000*Floor+100*Axis+04;
                fprintf(INP,'equalDOF %d %d 1; ',node0,node1);
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
        
        if FrameType==2
            fprintf(INP,'# BEAM MID-SPAN HORIZONTAL MOVEMENT CONSTRAINT\n');
            for Floor=NStory+1:-1:2
                if BraceLayout==2 || (BraceLayout==1 && rem(Floor,2))==0
                    nodeID0 = 400000+1000*Floor+100*1+04;
                    for Bay=1:NBay
                        nodeID1 = 200000+1000*Floor+100*Bay+01;
                        fprintf(INP,'equalDOF %d %d 1; ',nodeID0,nodeID1);
                    end
                    fprintf(INP,'\n');
                end
            end
            fprintf(INP,'\n');
        end
        
        fprintf(INP,'# EGF FLOOR MOVEMENT\n');
        for Floor=NStory+1:-1:2
            nodeID0 = (10*Floor+(NBay+2))*10;
            nodeID1 = (10*Floor+(NBay+3))*10;
            fprintf(INP,'equalDOF %d %d 1;\n',nodeID0,nodeID1);
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
    
else
    
    if RigidFloor==1
        fprintf(INP,'# MF FLOOR MOVEMENT\n');
        for Floor=NStory+1:-1:2
            nodeID0 = 400000+1000*Floor+100*1+04;
            for Axis=2:NBay+1
                if Axis < NBay+1; nodeID1 = 400000+1000*Floor+100*Axis+04; end
                if Axis ==  NBay+1; nodeID1 = (10*Floor+Axis)*10; end
                fprintf(INP,'equalDOF %d %d 1; ',nodeID0,nodeID1);
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
        
        if FrameType~=1
            fprintf(INP,'# BEAM MID-SPAN SAGGING CONSTRAINT\n');
            for Floor=NStory+1:-1:2
                if BraceLayout==2 || (BraceLayout==1 && rem(Floor,2))==0
                    nodeID0 = 400000+1000*Floor+100*1+04;
                    for Bay=1:NBay
                        nodeID1 = 200000+1000*Floor+100*Bay+01;
                        fprintf(INP,'equalDOF %d %d 1; ',nodeID0,nodeID1);
                    end
                    fprintf(INP,'\n');
                end
            end
            fprintf(INP,'\n');
        end
        
        fprintf(INP,'# EGF FLOOR MOVEMENT\n');
        for Floor=NStory+1:-1:2
            nodeID0 = (10*Floor+(NBay+2))*10;
            nodeID1 = (10*Floor+(NBay+3))*10;
            fprintf(INP,'equalDOF %d %d 1;\n',nodeID0,nodeID1);
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
end

if FrameType==2
    if MidSpanConstraint==2
        fprintf(INP,'# BEAM MID-SPAN SAGGING CONSTRAINT\n');
        for Floor=NStory+1:-1:2
            if BraceLayout==2 || (BraceLayout==1 && rem(Floor,2))==0
                nodeID0 = 400000+1000*Floor+100*1+04;
                for Bay=1:NBay
                    nodeID1 = 200000+1000*Floor+100*Bay+01;
                    fprintf(INP,'equalDOF %d %d 2; ',nodeID0,nodeID1);
                end
                fprintf(INP,'\n');
            end
        end
        fprintf(INP,'\n');
    end
end

if FrameType==3
    if MidSpanConstraint==2
        fprintf(INP,'# BEAM MID-SPAN SAGGING CONSTRAINT\n');
        for Floor=NStory+1:-1:2
            if BraceLayout==2 || (BraceLayout==1 && rem(Floor,2))==0
                nodeID0 = 400000+1000*Floor+100*1+04;
                for Bay=1:NBay
                    nodeID1 = 200000+1000*Floor+100*Bay+08;
                    fprintf(INP,'equalDOF %d %d 2; ',nodeID0,nodeID1);
                    nodeID1 = 200000+1000*Floor+100*Bay+09;
                    fprintf(INP,'equalDOF %d %d 2; ',nodeID0,nodeID1);
                end
                fprintf(INP,'\n');
            end
        end
        fprintf(INP,'\n');
    end
end

fprintf(INP,'##################################################################################################\n');
fprintf(INP,'##################################################################################################\n');
fprintf(INP,'                                       puts "Model Built"\n');
fprintf(INP,'##################################################################################################\n');
fprintf(INP,'##################################################################################################\n');
fprintf(INP,'\n');