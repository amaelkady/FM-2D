function write_BeamSpring_MRF (INP, NStory, NBay, WBay, ModelELOption, MF_COLUMNS, MF_BEAMS, MFconnection, a, b, c, k_beambracing, fy, Units)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                           MF BEAM SPRINGS                                       #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# Command Syntax \n');
fprintf(INP,'# Spring_IMK SpringID iNode jNode E fy Ix d htw bftf ry L Ls Lb My PgPye CompositeFLAG MFconnection Units; \n');
fprintf(INP,'\n');

for Floor=NStory+1:-1:2
    Story=min(NStory,Floor);
    for Axis=1:NBay+1
        Bay=max(1,Axis-1);
        Axisi=Bay; Axisj=Bay+1;
        Section=MF_BEAMS{Floor-1,Bay};
        [SecDataB]=Load_SecData (Section,Units);
        idxB=min(find(contains(SecDataB.Name,Section)));

        Section=MF_COLUMNS{Story,Axisi};
        [SecDataCi]=Load_SecData (Section,Units);
        idxCi=min(find(contains(SecDataCi.Name,Section)));

        Section=MF_COLUMNS{Story,Axisj};
        [SecDataCj]=Load_SecData (Section,Units);
        idxCj=min(find(contains(SecDataCj.Name,Section)));

        L_RBS   = a *  SecDataB.bf(idxB)+ b * SecDataB.d(idxB)/2;
        L_BEAM  =  WBay(Bay) - 0.5*SecDataCi.d(idxCi) - 0.5*SecDataCj.d(idxCj) - 2*L_RBS;
        Ls_BEAM = (WBay(Bay) - 0.5*SecDataCi.d(idxCi) - 0.5*SecDataCj.d(idxCj) - 2*L_RBS)*0.5;
        Lb_BEAM = (WBay(Bay) - 0.5*SecDataCi.d(idxCi) - 0.5*SecDataCj.d(idxCj))          *k_beambracing;

        A_RBS  =     SecDataB.Area(idxB) - 4 * c * SecDataB.bf(idxB)*SecDataB.tf(idxB);
        I_RBS  =     SecDataB.Ix(idxB)   - 4 * c * SecDataB.bf(idxB) *SecDataB.tf(idxB)*((SecDataB.d(idxB)-SecDataB.tf(idxB))/2)^2 - 4 *c * SecDataB.bf(idxB)*SecDataB.tf(idxB)^3/12;

        if MFconnection ==1
            Z_RBS = SecDataB.Zx(idxB);
            My = Z_RBS*fy;
        elseif MFconnection ==0
            Z_RBS = 2 * (SecDataB.bf(idxB)   - 2 * c * SecDataB.bf(idxB))*SecDataB.tf(idxB)*(SecDataB.d(idxB)/2-SecDataB.tf(idxB)/2) + 2 * (SecDataB.d(idxB)/2-SecDataB.tf(idxB))*SecDataB.tw(idxB)*(SecDataB.d(idxB)/2-SecDataB.tf(idxB))/2;
            My = Z_RBS*fy;
        end

        SpringID_L=900000+Floor*1000+Axis*100+02;
        SpringID_R=900000+Floor*1000+Axis*100+04;

        Node20 = 1000*Floor+100*Axis+20;
        Node02 = 100 *Floor+10 *Axis+02;
        Node40 = 1000*Floor+100*Axis+40;
        Node04 = 100 *Floor+10 *Axis+04;

        if ModelELOption==1

            if Axis~=1 && Axis~=NBay+1
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f 0.0 $Composite %d %d; ',SpringID_L,Node02,Node20,I_RBS, SecDataB.d(idxB),SecDataB.h_tw(idxB),SecDataB.bf_tf(idxB), SecDataB.ry(idxB), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f 0.0 $Composite %d %d; ',SpringID_R,Node40,Node04,I_RBS, SecDataB.d(idxB),SecDataB.h_tw(idxB),SecDataB.bf_tf(idxB), SecDataB.ry(idxB), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
            elseif Axis==1
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f 0.0 $Composite %d %d; ',SpringID_R,Node40,Node04,I_RBS, SecDataB.d(idxB),SecDataB.h_tw(idxB),SecDataB.bf_tf(idxB), SecDataB.ry(idxB), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
            elseif Axis==NBay+1
                fprintf(INP,'Spring_IMK %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f 0.0 $Composite %d %d; ',SpringID_L,Node02,Node20,I_RBS, SecDataB.d(idxB),SecDataB.h_tw(idxB),SecDataB.bf_tf(idxB), SecDataB.ry(idxB), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
            end

        else

            if Axis~=1 && Axis~=NBay+1
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_L,Node02,Node20);
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_R,Node40,Node04);
            elseif Axis==1
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_R,Node40,Node04);
            elseif Axis==NBay+1
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_L,Node02,Node20);
            end
            
        end

    end
    fprintf(INP,'\n');
end

fprintf(INP,'\n');