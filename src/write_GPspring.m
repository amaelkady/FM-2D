function write_GPspring (INP, NStory, NBay, FrameType, BraceLayout, BRACES, MGP_L123, MGP_tp, MGP_Lc, CGP_L123, CGP_tp, CGP_Lc, Units)

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                 			GUSSET PLATE SPRINGS   		                            #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# COMMAND SYNTAX \n');
fprintf(INP,'# Spring_Gusset $SpringID $NodeIDi $NodeIDj $E $fy $L_buckling $t_plate $L_connection $d_brace $MatID;\n');
fprintf(INP,'\n');

matID=4000;
fprintf(INP,'# BEAM MID-SPAN GUSSET PLATE SPRING\n');
if FrameType==2
    for Floor=NStory+1:-1:2
        Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
        if mod(Floor,2)==0 || BraceLayout==2
            for Bay=1:NBay
                Section=BRACES{Storyi,Bay};
                [SecData]=Load_SecData (Section, Units);
                idxi=find(contains(SecData.Name,Section));
                Section=BRACES{Storyj,Bay};
                [SecData]=Load_SecData (Section, Units);
                idxj=find(contains(SecData.Name,Section));
                nodeID3 =200000+1000*Floor+100*Bay+3;
                nodeID13=200000+1000*Floor+100*Bay+13;
                nodeID4 =200000+1000*Floor+100*Bay+4;
                nodeID14=200000+1000*Floor+100*Bay+14;
                SpringID33=900000+Floor*1000+Bay*100+33;
                SpringID44=900000+Floor*1000+Bay*100+44;
                if BraceLayout==1
                    SpringID66=900000+Floor*1000+Bay*100+66;
                    SpringID77=900000+Floor*1000+Bay*100+77;
                end
                
                fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID33, nodeID13, nodeID3, mean(MGP_L123(Storyi,1:3)), MGP_tp(Storyi,Bay), MGP_Lc(Storyi,1), SecData.h(idxi), matID);
                matID=matID+1;
                fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID44, nodeID14, nodeID4, mean(MGP_L123(Storyi,1:3)), MGP_tp(Storyi,Bay), MGP_Lc(Storyi,1), SecData.h(idxi), matID);
                matID=matID+1;
                if Floor<NStory+1 && FrameType==2 && BraceLayout==1
                    nodeID6 =200000+1000*Floor+100*Bay+6;
                    nodeID16=200000+1000*Floor+100*Bay+16;
                    nodeID7 =200000+1000*Floor+100*Bay+7;
                    nodeID17=200000+1000*Floor+100*Bay+17;
                    fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID66, nodeID16, nodeID6, mean(MGP_L123(Storyj,1:3)), MGP_tp(Storyj,Bay), MGP_Lc(Storyj,1), SecData.h(idxj), matID);
                    matID=matID+1;
                    fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID77, nodeID17, nodeID7, mean(MGP_L123(Storyj,1:3)), MGP_tp(Storyj,Bay), MGP_Lc(Storyj,1), SecData.h(idxj), matID);
                    matID=matID+1;
                end
            end
            fprintf(INP,'\n');
        end
    end
    fprintf(INP,'\n');
    
    fprintf(INP,'# CORNER GUSSET PLATE SPRINGS\n');
    for Floor=NStory+1:-1:1
        Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
        if mod(Floor,2)~=0 || BraceLayout==2
            for Axis=1:NBay+1
                Bay=max(1,Axis-1);
                Section=BRACES{Storyi,Bay};
                [SecData]=Load_SecData (Section, Units);
                idxi=find(contains(SecData.Name,Section));
                Section=BRACES{Storyj,Bay};
                [SecData]=Load_SecData (Section, Units);
                idxj=find(contains(SecData.Name,Section));
                SpringID11=900000+Floor*1000+Axis*100+11;
                SpringID99=900000+Floor*1000+Axis*100+99;
                if Floor~=1 && Floor~=NStory+1
                    iNode=100000+1000*Floor+100*Axis+40;
                    jNode=100000+1000*Floor+100*Axis+41;
                    fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID11, iNode, jNode, mean(CGP_L123(Storyj,1:3)), CGP_tp(Storyj,Bay), CGP_Lc(Storyj,1), SecData.h(idxj), matID);
                    matID=matID+1;
                    if BraceLayout==1
                        iNode=100000+1000*Floor+100*Axis+50;
                        jNode=100000+1000*Floor+100*Axis+51;
                        fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID99, iNode, jNode, mean(CGP_L123(Storyi,1:3)), CGP_tp(Storyi,Bay), CGP_Lc(Storyi,1), SecData.h(idxi), matID);
                        matID=matID+1;
                    end
                end
                if Floor==NStory+1 && BraceLayout==1
                    iNode=100000+1000*Floor+100*Axis+50;
                    jNode=100000+1000*Floor+100*Axis+51;
                    fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID99, iNode, jNode, mean(CGP_L123(Storyi,1:3)), CGP_tp(Storyi,Bay), CGP_Lc(Storyi,1), SecData.h(idxi), matID);
                    matID=matID+1;
                end
                if Floor==1
                    iNode=100000+1000*Floor+100*Axis+40;
                    jNode=100000+1000*Floor+100*Axis+41;
                    fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID11, iNode, jNode, mean(CGP_L123(Storyj,1:3)), CGP_tp(Storyj,Bay), CGP_Lc(Storyj,1), SecData.h(idxj), matID);
                    matID=matID+1;
                end
            end
            fprintf(INP,'\n');
        end
    end
    fprintf(INP,'\n');
end




if FrameType==3
    for Floor=NStory+1:-1:2
        Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
        for Bay=1:NBay
            Section=BRACES{Storyi,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxi=find(contains(SecData.Name,Section));
            Section=BRACES{Storyj,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxj=find(contains(SecData.Name,Section));
            nodeID3 =200000+1000*Floor+100*Bay+3;
            nodeID13=200000+1000*Floor+100*Bay+13;
            nodeID4 =200000+1000*Floor+100*Bay+4;
            nodeID14=200000+1000*Floor+100*Bay+14;
            SpringID33=900000+Floor*1000+Bay*100+33;
            SpringID44=900000+Floor*1000+Bay*100+44;
            
            fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID33, nodeID13, nodeID3, mean(MGP_L123(Storyi,1:3)), MGP_tp(Storyi,Bay), MGP_Lc(Storyi,1), SecData.h(idxi), matID);
            matID=matID+1;
            if BraceLayout==1
                fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID44, nodeID14, nodeID4, mean(MGP_L123(Storyi,1:3)), MGP_tp(Storyi,Bay), MGP_Lc(Storyi,1), SecData.h(idxi), matID);
                matID=matID+1;
            end
        end
        fprintf(INP,'\n');
    end
end
fprintf(INP,'\n');

fprintf(INP,'# CORNER GUSSET PLATE SPRINGS\n');
for Floor=NStory:-1:1
    Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
    for Axis=1:NBay+1
        
        if BraceLayout==2 && Axis>1; break; end
        
        Bay=max(1,Axis-1);
        Section=BRACES{Storyi,Bay};
        [SecData]=Load_SecData (Section, Units);
        idxi=find(contains(SecData.Name,Section));
        Section=BRACES{Storyj,Bay};
        [SecData]=Load_SecData (Section, Units);
        idxj=find(contains(SecData.Name,Section));
        
        SpringID11=900000+Floor*1000+Axis*100+11;

        iNode=100000+1000*Floor+100*Axis+40;
        jNode=100000+1000*Floor+100*Axis+41;
        fprintf(INP,'Spring_Gusset %d %6d %6d $E $fyG %.4f %.4f %.4f %.4f %5d;\n', SpringID11, iNode, jNode, mean(CGP_L123(Storyj,1:3)), CGP_tp(Storyj,Bay), CGP_Lc(Storyj,1), SecData.h(idxj), matID);
        matID=matID+1;    
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');
end