function write_FloorLinks_FiberFrame (INP,NStory,NBay,WBay,FloorLink,Fs,Fs_Profile)

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                              FLOOR LINKS                                         #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# Command Syntax \n');
fprintf(INP,'# element truss $ElementID $iNode $jNode $Area $matID\n');

    if FloorLink==1
        for Floor=NStory+1:-1:2
            nodeID1=(10*Floor+(NBay+1))*10;
            nodeID2=(10*Floor+(NBay+2))*10;
            eleID=1000+Floor;
            fprintf(INP,'element truss %d %d %d $A_Stiff 99;\n',eleID, nodeID1, nodeID2);
        end
    else
        b=Ks/(10000000.*1/WBay(end));
        for Floor=NStory+1:-1:2
            matID=900+Floor;
            fprintf(INP,'uniaxialMaterial Steel02 %d %.4f 10000000. %.4f 15 0.925 15;\n', matID,Fs*Fs_Profile(Floor-1,1), b);
            nodeID1=(10*Floor+(NBay+1))*10;
            nodeID2=(10*Floor+(NBay+2))*10;
            eleID=1000+Floor;
            fprintf(INP,'element truss %d %d %d 1.0 %d;\n',eleID, nodeID1, nodeID2,matID);
        end
    end
    fprintf(INP,'\n');
