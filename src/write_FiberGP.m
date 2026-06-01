function write_FiberGP (INP)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'NStory','FrameType','NBay','BraceLayout','BRACES','Units', 'Ry_gusset', 'MGP_tp', 'MGP_Lc', 'CGP_tp', 'CGP_Lc');

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                 			GUSSET PLATE SPRINGS   		                            #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# COMMAND SYNTAX \n');
fprintf(INP,'# Spring_Gusset_FB $SpringID $NodeIDi $NodeIDj $E $fy $t_plate $L_connection $d_brace $MatID;\n');
fprintf(INP,'\n');

matID=4000;
fprintf(INP,'# BEAM MID-SPAN GUSSET PLATE\n');
if FrameType==2
    for Floor=NStory+1:-1:2
        Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
        if mod(Floor,2)==0 || BraceLayout==2
            for Bay=1:NBay
                
                Section=BRACES{Storyi,Bay};
                [SecData]=load_SecData (Section, Units);
                idxi= find(contains(SecData.Name,Section),1,'first');

                Section=BRACES{Storyj,Bay};
                [SecData]=load_SecData (Section, Units);
                idxj= find(contains(SecData.Name,Section),1,'first');

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
                
                fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f] %.4f %.4f %.4f %5d;\n', SpringID33, nodeID13, nodeID3, Ry_gusset, MGP_tp(Storyi,Bay), MGP_Lc(Storyi,1), SecData.h(idxi), matID);
                matID=matID+1;
                fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f] %.4f %.4f %.4f %5d;\n', SpringID44, nodeID14, nodeID4, Ry_gusset, MGP_tp(Storyi,Bay), MGP_Lc(Storyi,1), SecData.h(idxi), matID);
                matID=matID+1;
                if Floor<NStory+1 && FrameType==2 && BraceLayout==1
                    nodeID6 =200000+1000*Floor+100*Bay+6;
                    nodeID16=200000+1000*Floor+100*Bay+16;
                    nodeID7 =200000+1000*Floor+100*Bay+7;
                    nodeID17=200000+1000*Floor+100*Bay+17;
                    fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f] %.4f %.4f %.4f %5d;\n', SpringID66, nodeID16, nodeID6, Ry_gusset, MGP_tp(Storyj,Bay), MGP_Lc(Storyj,1), SecData.h(idxj), matID);
                    matID=matID+1;
                    fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f] %.4f %.4f %.4f %5d;\n', SpringID77, nodeID17, nodeID7, Ry_gusset, MGP_tp(Storyj,Bay), MGP_Lc(Storyj,1), SecData.h(idxj), matID);
                    matID=matID+1;
                end
            end
            fprintf(INP,'\n');
        end
    end
    fprintf(INP,'\n');
    
    fprintf(INP,'# CORNER GUSSET PLATE\n');
    for Floor=NStory+1:-1:1
        Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
        if mod(Floor,2)~=0 || BraceLayout==2
            for Axis=1:NBay+1
                Bay=max(1,Axis-1);
                
                Section=BRACES{Storyi,Bay};
                [SecData]=load_SecData (Section, Units);
                idxi= find(contains(SecData.Name,Section),1,'first');

                Section=BRACES{Storyj,Bay};
                [SecData]=load_SecData (Section, Units);
                idxj= find(contains(SecData.Name,Section),1,'first');

                SpringID11=900000+Floor*1000+Axis*100+11;
                SpringID99=900000+Floor*1000+Axis*100+99;
                
                if Floor~=1 && Floor~=NStory+1
                    iNode=100000+1000*Floor+100*Axis+40;
                    jNode=100000+1000*Floor+100*Axis+41;
                    fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f] %.4f %.4f %.4f %5d;\n', SpringID11, iNode, jNode, Ry_gusset, CGP_tp(Storyj,Bay), CGP_Lc(Storyj,1), SecData.h(idxj), matID);
                    matID=matID+1;
                    if BraceLayout==1
                        iNode=100000+1000*Floor+100*Axis+50;
                        jNode=100000+1000*Floor+100*Axis+51;
                        fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f] %.4f %.4f %.4f %5d;\n', SpringID99, iNode, jNode, Ry_gusset, CGP_tp(Storyi,Bay), CGP_Lc(Storyi,1), SecData.h(idxi), matID);
                        matID=matID+1;
                    end
                end
                if Floor==NStory+1 && BraceLayout==1
                    iNode=100000+1000*Floor+100*Axis+50;
                    jNode=100000+1000*Floor+100*Axis+51;
                    fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f] %.4f %.4f %.4f %5d;\n', SpringID99, iNode, jNode, Ry_gusset, CGP_tp(Storyi,Bay), CGP_Lc(Storyi,1), SecData.h(idxi), matID);
                    matID=matID+1;
                end
                if Floor==1
                    iNode=100000+1000*Floor+100*Axis+40;
                    jNode=100000+1000*Floor+100*Axis+41;
                    fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f] %.4f %.4f %.4f %5d;\n', SpringID11, iNode, jNode, Ry_gusset, CGP_tp(Storyj,Bay), CGP_Lc(Storyj,1), SecData.h(idxj), matID);
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
            [SecData]=load_SecData (Section, Units);
            idxi= find(contains(SecData.Name,Section),1,'first');
            
            nodeID3 =200000+1000*Floor+100*Bay+3;
            nodeID13=200000+1000*Floor+100*Bay+13;
            nodeID4 =200000+1000*Floor+100*Bay+4;
            nodeID14=200000+1000*Floor+100*Bay+14;

            SpringID33=900000+Floor*1000+Bay*100+33;
            SpringID44=900000+Floor*1000+Bay*100+44;
            
            fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f]  %.4f %.4f %.4f %5d;\n', SpringID33, nodeID13, nodeID3, Ry_gusset, MGP_tp(Storyi,Bay), MGP_Lc(Storyi,1), SecData.h(idxi), matID);
            matID=matID+1;
            if BraceLayout==1
                fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f] %.4f %.4f %.4f %5d;\n', SpringID44, nodeID14, nodeID4, Ry_gusset,  MGP_tp(Storyi,Bay), MGP_Lc(Storyi,1), SecData.h(idxi), matID);
                matID=matID+1;
            end
        end
        fprintf(INP,'\n');
    end
    
    fprintf(INP,'\n');
    
    fprintf(INP,'# CORNER GUSSET PLATE\n');
    for Floor=NStory:-1:1
        Storyi=max(1,Floor-1);    Storyj=min(NStory,Floor);
        for Axis=1:NBay+1
            
            if BraceLayout==2 && Axis>1; break; end
            
            Bay=max(1,Axis-1);
            
            Section=BRACES{Storyj,Bay};
            [SecData]=load_SecData (Section, Units);
            idxj= find(contains(SecData.Name,Section),1,'first');
            
            SpringID11=900000+Floor*1000+Axis*100+11;
            
            iNode=100000+1000*Floor+100*Axis+40;
            jNode=100000+1000*Floor+100*Axis+41;

            fprintf(INP,'Spring_Gusset_FB %d %6d %6d $E [expr $fyG * %.2f] %.4f %.4f %.4f %5d;\n', SpringID11, iNode, jNode, Ry_gusset, CGP_tp(Storyj,Bay), CGP_Lc(Storyj,1), SecData.h(idxj), matID);
            matID=matID+1;
        end
        fprintf(INP,'\n');
    end
    fprintf(INP,'\n');
end
end
