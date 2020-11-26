function write_BeamSpring_MRF (INP, NStory, NBay, WBay, ModelELOption, MF_COLUMNS, MF_BEAMS, MFconnection, a, b, c, fy, Units)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                           MF BEAM SPRINGS                                       #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

if ModelELOption==2
    for Floor=NStory+1:-1:2
        Story=Floor-1;
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            Axisi=Bay; Axisj=Bay+1;
            
            SpringID_L=900000+Floor*1000+Axis*100+02;
            SpringID_R=900000+Floor*1000+Axis*100+04;
            
            if Axis~=1 && Axis~=NBay+1
                iNode = 1000*Floor+100*Axis+20;
                jNode = 100*Floor+10*Axis+02;
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_L,iNode,jNode);
                iNode = 100*Floor+10*Axis+04;
                jNode = 1000*Floor+100*Axis+40;
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_R,iNode,jNode);
            end
            if Axis==1
                iNode = 100*Floor+10*Axis+04;
                jNode = 1000*Floor+100*Axis+40;
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_R,iNode,jNode);
            end
            if Axis==NBay+1
                iNode = 1000*Floor+100*Axis+20;
                jNode = 100*Floor+10*Axis+02;
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_L,iNode,jNode);
            end
        end
        fprintf(INP,'\n');
    end
    
else
    
    fprintf(INP,'# Command Syntax \n');
    fprintf(INP,'# Spring_IMK SpringID iNode jNode E fy Ix d htw bftf ry L Ls Lb My PgPye CompositeFLAG MFconnection Units; \n');
    fprintf(INP,'\n');

    for Floor=NStory+1:-1:2
        Story=min(NStory,Floor);
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            Axisi=Bay; Axisj=Bay+1;
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section,Units);
            idx=find(contains(SecData.Name,Section));
            Section=MF_COLUMNS{Story,Axisi};
            [SecData]=Load_SecData (Section,Units);
            idxCi=find(contains(SecData.Name,Section));
            Section=MF_COLUMNS{Story,Axisj};
            [SecData]=Load_SecData (Section,Units);
            idxCj=find(contains(SecData.Name,Section));
            
            L_RBS   = a *  SecData.bf(idx)+ b * SecData.d(idx)/2;
            L_BEAM  =  WBay(Bay) - 0.5*SecData.d(idxCi) - 0.5*SecData.d(idxCj) - 2*L_RBS;
            Ls_BEAM = (WBay(Bay) - 0.5*SecData.d(idxCi) - 0.5*SecData.d(idxCj) - 2*L_RBS)*0.5;
            Lb_BEAM = (WBay(Bay) - 0.5*SecData.d(idxCi) - 0.5*SecData.d(idxCj))          *0.5;
            
            A_RBS  =     SecData.Area(idx) - 4 * c * SecData.bf(idx)*SecData.tf(idx);
            I_RBS  =     SecData.Ix(idx) - 4 * c * SecData.bf(idx) *SecData.tf(idx)*((SecData.d(idx)-SecData.tf(idx))/2)^2 - 4 *c * SecData.bf(idx)*SecData.tf(idx)^3/12;
            Z_RBS  =2 * (SecData.bf(idx) - 2 * c * SecData.bf(idx))*SecData.tf(idx)*(SecData.d(idx)/2-SecData.tf(idx)/2) + 2 * (SecData.d(idx)/2-SecData.tf(idx))*SecData.tw(idx)*(SecData.d(idx)/2-SecData.tf(idx))/2;
            
            My=1.1*Z_RBS*fy;
            
            SpringID_L=900000+Floor*1000+Axis*100+02;
            SpringID_R=900000+Floor*1000+Axis*100+04;
            
            Node20 = 1000*Floor+100*Axis+20;
            Node02 = 100 *Floor+10 *Axis+02;
            Node40 = 1000*Floor+100*Axis+40;
            Node04 = 100 *Floor+10 *Axis+04;
            
            if Axis~=1 && Axis~=NBay+1
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f 0.0 $Composite %d %d; ',SpringID_L,Node20,Node02,I_RBS, SecData.d(idx),SecData.h_tw(idx),SecData.bf_tf(idx), SecData.ry(idx), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f 0.0 $Composite %d %d; ',SpringID_R,Node04,Node40,I_RBS, SecData.d(idx),SecData.h_tw(idx),SecData.bf_tf(idx), SecData.ry(idx), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
            end
            if Axis==1
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f 0.0 $Composite %d %d; ',SpringID_R,Node04,Node40,I_RBS, SecData.d(idx),SecData.h_tw(idx),SecData.bf_tf(idx), SecData.ry(idx), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
            end
            if Axis==NBay+1
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f 0.0 $Composite %d %d; ',SpringID_L,Node20,Node02,I_RBS, SecData.d(idx),SecData.h_tw(idx),SecData.bf_tf(idx), SecData.ry(idx), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
            end
        end
        fprintf(INP,'\n');
    end
end
fprintf(INP,'\n');