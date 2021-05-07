function write_BeamSpring_CBF (INP, NStory, NBay, WBay, FrameType, BraceLayout, MF_COLUMNS, MF_BEAMS, MGP_W, MFconnectionOdd, MFconnectionEven, fy, Units)


fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                           MF BEAM SPRINGS                                       #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

if MFconnectionOdd==2
    fprintf(INP,'# COMMAND SYNTAX \n');
    fprintf(INP,'# Spring_Pinching $SpringID $iNode $jNode $EffectivePlasticStrength $gap $CompositeFlag\n');
    fprintf(INP,'\n');
    fprintf(INP,'set gap 0.08;\n');
end

if FrameType==2
    for Floor=NStory+1:-1:2
        Story=Floor-1;
        if mod(Floor,2)==0 || BraceLayout==2
            for Axis=1:NBay+1
                Bay=max(1,Axis-1);
                Axisi=Bay; Axisj=Bay+1;
                Section=MF_BEAMS{Floor-1,Bay};
                [SecData]=Load_SecData (Section, Units);
                idx=find(contains(SecData.Name,Section));
                Section=MF_COLUMNS{Story,Axisi};
                [SecData]=Load_SecData (Section, Units);
                idxCi=find(contains(SecData.Name,Section));
                
                H_BEAM =  WBay(Bay)*0.5 - 0.5*SecData.d(idxCi) - MGP_W(Story,1)*0.5;
                L_BEAM = (WBay(Bay)*0.5 - 0.5*SecData.d(idxCi) - MGP_W(Story,1)*0.5)*0.5;
                Lb_BEAM = H_BEAM*0.5;
                My=1.1*SecData.Zx(idx)*fy;
                
                SpringID02=900000+Floor*1000+Axis*100+02;
                SpringID04=900000+Floor*1000+Axis*100+04;
                
                if MFconnectionEven==1
                    if Axis~=1 && Axis~=NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID02,iNode,jNode);
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID04,iNode,jNode);
                    end
                    if Axis==1
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID04,iNode,jNode);
                    end
                    if Axis==NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID02,iNode,jNode);
                    end
                elseif MFconnectionEven==2
                    if Axis~=1 && Axis~=NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID02,iNode,jNode,My);
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID04,iNode,jNode,My);
                    end
                    if Axis==1
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID04,iNode,jNode,My);
                    end
                    if Axis==NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID02,iNode,jNode,My);
                    end
                elseif MFconnectionEven==3
                    ConnectionType=0;
                    if Axis~=1 && Axis~=NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f]  %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID02,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f]  %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID04,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                    end
                    if Axis==1
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f]  %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID04,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                    end
                    if Axis==NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f]  %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID02,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                    end
                end
            end
            
            for Bay=1:NBay
                ConnectionType=0;
                Axisi=Bay; Axisj=Bay+1;
                Section=MF_BEAMS{Floor-1,Bay};
                [SecData]=Load_SecData (Section, Units);
                idx=find(contains(SecData.Name,Section));
                Section=MF_COLUMNS{Story,Axisi};
                [SecData]=Load_SecData (Section, Units);
                idxCi=find(contains(SecData.Name,Section));
                
                H_BEAM =  WBay(Bay)*0.5 - 0.5*SecData.d(idxCi) - MGP_W(Story,1)*0.5;
                L_BEAM = (WBay(Bay)*0.5 - 0.5*SecData.d(idxCi) - MGP_W(Story,1)*0.5)*0.5;
                Lb_BEAM = H_BEAM*0.5;
                My=1.1*SecData.Zx(idx)*fy;
                
                jNode = 200000+1000*Floor+100*Bay+2;
                iNode = 200000+1000*Floor+100*Bay+12;
                SpringID=900000+Floor*1000+Bay*100+22;
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                iNode = 200000+1000*Floor+100*Bay+5;
                jNode = 200000+1000*Floor+100*Bay+15;
                SpringID=900000+Floor*1000+Bay*100+55;
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
            end
            fprintf(INP,'\n');
        end
    end
    fprintf(INP,'\n');
    
    for Floor=NStory+1:-1:2
        Story=Floor-1;
        if mod(Floor,2)~=0 && BraceLayout==1
            for Axis=1:NBay+1
                Bay=max(1,Axis-1);
                Axisi=Bay; Axisj=Bay+1;
                Section=MF_BEAMS{Floor-1,Bay};
                [SecData]=Load_SecData (Section, Units);
                idx=find(contains(SecData.Name,Section));
                Section=MF_COLUMNS{Story,Axisi};
                [SecData]=Load_SecData (Section, Units);
                idxCi=find(contains(SecData.Name,Section));
                Section=MF_COLUMNS{Story,Axisj};
                [SecData]=Load_SecData (Section, Units);
                idxCj=find(contains(SecData.Name,Section));
                
                H_BEAM =  WBay(Bay) - 0.5*SecData.d(idxCi) - 0.5*SecData.d(idxCj);
                L_BEAM = (WBay(Bay) - 0.5*SecData.d(idxCi) - 0.5*SecData.d(idxCj))*0.5;
                Lb_BEAM = H_BEAM*0.5;
                My=1.1*SecData.Zx(idx)*fy;
                
                SpringID02=900000+Floor*1000+Axis*100+02;
                SpringID04=900000+Floor*1000+Axis*100+04;
                
                if MFconnectionOdd==1
                    if Axis~=1 && Axis~=NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID02,iNode,jNode);
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID04,iNode,jNode);
                    end
                    if Axis==1
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID04,iNode,jNode);
                    end
                    if Axis==NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID02,iNode,jNode);
                    end
                elseif MFconnectionOdd==2
                    if Axis~=1 && Axis~=NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID02,iNode,jNode,My);
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID04,iNode,jNode,My);
                    end
                    if Axis==1
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID04,iNode,jNode,My);
                    end
                    if Axis==NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID02,iNode,jNode,My);
                    end
                elseif MFconnectionOdd==3
                    ConnectionType=0; % Fully Restrained Connection (OTHER-THAN-RBS)
                    if Axis~=1 && Axis~=NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID02,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID04,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                    end
                    if Axis==1
                        iNode = 400000+1000*Floor+100*Axis+04;
                        jNode = 100*Floor+10*Axis+04;
                        fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID04,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                    end
                    if Axis==NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID02,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                    end
                end
            end
            fprintf(INP,'\n');
        end
    end
    fprintf(INP,'\n');
end






if FrameType==3
    for Floor=NStory+1:-1:2
        Story=Floor-1;
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            Axisi=Bay; Axisj=Bay+1;
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            Section=MF_COLUMNS{Story,Axisi};
            [SecData]=Load_SecData (Section, Units);
            idxCi=find(contains(SecData.Name,Section));
            
            H_BEAM =  WBay(Bay)*0.5 - 0.5*SecData.d(idxCi) - MGP_W(Story,1)*0.5;
            L_BEAM = (WBay(Bay)*0.5 - 0.5*SecData.d(idxCi) - MGP_W(Story,1)*0.5)*0.5;
            Lb_BEAM = H_BEAM*0.5;
            My=1.1*SecData.Zx(idx)*fy;
            
            SpringID02=900000+Floor*1000+Axis*100+02;
            SpringID04=900000+Floor*1000+Axis*100+04;
            
            if MFconnectionEven==1
                if Axis~=1 && Axis~=NBay+1
                    if BraceLayout==1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID02,iNode,jNode);
                    end
                    iNode = 400000+1000*Floor+100*Axis+04;
                    jNode = 100*Floor+10*Axis+04;
                    fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID04,iNode,jNode);
                end
                if Axis==1
                    iNode = 400000+1000*Floor+100*Axis+04;
                    jNode = 100*Floor+10*Axis+04;
                    fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID04,iNode,jNode);
                end
                if BraceLayout==1
                    if Axis==NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Zero  %d  %d %d; ', SpringID02,iNode,jNode);
                    end
                end
            elseif MFconnectionEven==2
                if Axis~=1 && Axis~=NBay+1
                    if BraceLayout==1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID02,iNode,jNode,My);
                    end
                    iNode = 400000+1000*Floor+100*Axis+04;
                    jNode = 100*Floor+10*Axis+04;
                    fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID04,iNode,jNode,My);
                end
                if Axis==1
                    iNode = 400000+1000*Floor+100*Axis+04;
                    jNode = 100*Floor+10*Axis+04;
                    fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID04,iNode,jNode,My);
                end
                if BraceLayout==1
                    if Axis==NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_Pinching  %d  %d %d %.4f $gap $Composite; ', SpringID02,iNode,jNode,My);
                    end
                end
            elseif MFconnectionEven==3
                ConnectionType=0;
                if Axis~=1 && Axis~=NBay+1
                    if BraceLayout==1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f]  %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID02,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                    end
                    iNode = 400000+1000*Floor+100*Axis+04;
                    jNode = 100*Floor+10*Axis+04;
                    fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f]  %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID04,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                end
                if Axis==1
                    iNode = 400000+1000*Floor+100*Axis+04;
                    jNode = 100*Floor+10*Axis+04;
                    fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f]  %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID04,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                end
                if BraceLayout==1
                    if Axis==NBay+1
                        iNode = 100*Floor+10*Axis+02;
                        jNode = 400000+1000*Floor+100*Axis+02;
                        fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f]  %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID02,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
                    end
                end
            end
        end
        
        for Bay=1:NBay
            ConnectionType=0;
            Axisi=Bay; Axisj=Bay+1;
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            Section=MF_COLUMNS{Story,Axisi};
            [SecData]=Load_SecData (Section, Units);
            idxCi=find(contains(SecData.Name,Section));
            
            H_BEAM =  WBay(Bay)*0.5 - 0.5*SecData.d(idxCi) - MGP_W(Story,1)*0.5;
            L_BEAM = (WBay(Bay)*0.5 - 0.5*SecData.d(idxCi) - MGP_W(Story,1)*0.5)*0.5;
            Lb_BEAM = H_BEAM*0.5;
            My=1.1*SecData.Zx(idx)*fy;
            
            jNode = 200000+1000*Floor+100*Bay+2;
            iNode = 200000+1000*Floor+100*Bay+12;
            SpringID=900000+Floor*1000+Bay*100+22;
            fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
            if BraceLayout==1
                iNode = 200000+1000*Floor+100*Bay+5;
                jNode = 200000+1000*Floor+100*Bay+15;
                SpringID=900000+Floor*1000+Bay*100+55;
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.4f] %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f 0 $Composite %d %d; ',SpringID,iNode,jNode,SecData.Ix(idx), SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx), SecData.ry(idx), H_BEAM, L_BEAM, Lb_BEAM, My, ConnectionType, Units);
            end
        end
        fprintf(INP,'\n');
    end
    
    fprintf(INP,'\n');
end