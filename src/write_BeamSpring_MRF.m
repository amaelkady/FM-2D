function write_BeamSpring_MRF (INP)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'NStory','NBay', 'WBay','ModelELOption','MF_COLUMNS','MF_BEAMS','MFconnection','a','b','c','k_beambracing','fy','Units','BeamElementOption');


fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                           MF BEAM SPRINGS                                       #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

if ModelELOption==1 && BeamElementOption==1
fprintf(INP,'# Command Syntax \n');
fprintf(INP,'# Spring_Connection_FullyRigid SpringID iNode jNode E fy Ix d htw bftf ry L Ls Lb My CompositeFLAG MFconnection Units; \n');
fprintf(INP,'\n');
else
fprintf(INP,'# Command Syntax \n');
fprintf(INP,'# Spring_Rigid SpringID iNode jNode; \n');
fprintf(INP,'\n');
end

for Floor=NStory+1:-1:2
    Story=min(NStory,Floor);
    for Axis=1:NBay+1
        Bay=max(1,Axis-1);
        Axisi=Bay; Axisj=Bay+1;
        Section=MF_BEAMS{Floor-1,Bay};
        [SecDataB]=load_SecData (Section,Units);
        idxB= find(contains(SecDataB.Name,Section),1,'first');

        Section=MF_COLUMNS{Story,Axisi};
        [SecDataCi]=load_SecData (Section,Units);
        idxCi= find(contains(SecDataCi.Name,Section),1,'first');

        Section=MF_COLUMNS{Story,Axisj};
        [SecDataCj]=load_SecData (Section,Units);
        idxCj= find(contains(SecDataCj.Name,Section),1,'first');

        if MFconnection==3
            ConnectionID=1; % extended endplate
            EEPC=MF_EEPCs{Floor-1,Bay};
            [ConData] = load_PRConnParams(EEPC,ConnectionID); 
        end

        L_RBS   = a *  SecDataB.bf(idxB)+ b * SecDataB.d(idxB)/2;
        L_BEAM  =  WBay(Bay) - 0.5*SecDataCi.d(idxCi) - 0.5*SecDataCj.d(idxCj) - 2*L_RBS;
        Ls_BEAM = (WBay(Bay) - 0.5*SecDataCi.d(idxCi) - 0.5*SecDataCj.d(idxCj) - 2*L_RBS)*0.5;
        Lb_BEAM = (WBay(Bay) - 0.5*SecDataCi.d(idxCi) - 0.5*SecDataCj.d(idxCj))          *k_beambracing;

        A_RBS  =     SecDataB.Area(idxB) - 4 * c * SecDataB.bf(idxB)*SecDataB.tf(idxB);
        I_RBS  =     SecDataB.Ix(idxB)   - 4 * c * SecDataB.bf(idxB) *SecDataB.tf(idxB)*((SecDataB.d(idxB)-SecDataB.tf(idxB))/2)^2 - 4 *c * SecDataB.bf(idxB)*SecDataB.tf(idxB)^3/12;

        if MFconnection ==2
            Z_RBS = SecDataB.Zx(idxB);
            My = Z_RBS*fy;
        elseif MFconnection ==1
            Z_RBS = 2 * (SecDataB.bf(idxB)   - 2 * c * SecDataB.bf(idxB))*SecDataB.tf(idxB)*(SecDataB.d(idxB)/2-SecDataB.tf(idxB)/2) + 2 * (SecDataB.d(idxB)/2-SecDataB.tf(idxB))*SecDataB.tw(idxB)*(SecDataB.d(idxB)/2-SecDataB.tf(idxB))/2;
            My = Z_RBS*fy;
        end

        SpringID_L=900000+Floor*1000+Axis*100+02;
        SpringID_R=900000+Floor*1000+Axis*100+04;

        Node20 = 1000*Floor+100*Axis+20;
        Node02 = 100 *Floor+10 *Axis+02;
        Node40 = 1000*Floor+100*Axis+40;
        Node04 = 100 *Floor+10 *Axis+04;

        if ModelELOption==1 && BeamElementOption==1

            if MFconnection~=3
                if Axis~=1 && Axis~=NBay+1
                    fprintf(INP,'Spring_Connection_FullyRigid %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f $Composite %d %d; ',SpringID_L,Node02,Node20,I_RBS, SecDataB.d(idxB),SecDataB.h_tw(idxB),SecDataB.bf_tf(idxB), SecDataB.ry(idxB), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
                    fprintf(INP,'Spring_Connection_FullyRigid %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f $Composite %d %d; ',SpringID_R,Node40,Node04,I_RBS, SecDataB.d(idxB),SecDataB.h_tw(idxB),SecDataB.bf_tf(idxB), SecDataB.ry(idxB), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
                elseif Axis==1
                    fprintf(INP,'Spring_Connection_FullyRigid %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f $Composite %d %d; ',SpringID_R,Node40,Node04,I_RBS, SecDataB.d(idxB),SecDataB.h_tw(idxB),SecDataB.bf_tf(idxB), SecDataB.ry(idxB), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
                elseif Axis==NBay+1
                    fprintf(INP,'Spring_Connection_FullyRigid %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f $Composite %d %d; ',SpringID_L,Node02,Node20,I_RBS, SecDataB.d(idxB),SecDataB.h_tw(idxB),SecDataB.bf_tf(idxB), SecDataB.ry(idxB), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
            end
            else
                if Axis~=1 && Axis~=NBay+1
                    fprintf(INP,'Spring_SR_EEPCs %d %d %d %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f $E $mu %.3f %.3f %d %d %.3f $fyP $fuP $fy $fu $fub %d %d 1 $Composite 1 %d; ',SpringID_L, Node20, Node02, ConData.pt, ConData.g, ConData.tep, ConData.bep, SecDataCi.tf(idxCi), ConData.d_b, SecDataB.d(idxB), SecDataCi.d(idxCi), SecDataCi.tw(idxCi), SecDataCi.Ix(idxCi), ConData.tbp, ConData.DP,ConData.BP, ConData.tdp, ConData.StiffenerC, ConData.nrows, Units);
                    fprintf(INP,'Spring_SR_EEPCs %d %d %d %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f $E $mu %.3f %.3f %d %d %.3f $fyP $fuP $fy $fu $fub %d %d 1 $Composite 1 %d; ',SpringID_R, Node04, Node40, ConData.pt, ConData.g, ConData.tep, ConData.bep, SecDataCi.tf(idxCi), ConData.d_b, SecDataB.d(idxB), SecDataCi.d(idxCi), SecDataCi.tw(idxCi), SecDataCi.Ix(idxCi), ConData.tbp, ConData.DP,ConData.BP, ConData.tdp, ConData.StiffenerC, ConData.nrows, Units);                                          
                elseif Axis==1
                    fprintf(INP,'Spring_SR_EEPCs %d %d %d %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f $E $mu %.3f %.3f %d %d %.3f $fyP $fuP $fy $fu $fub %d %d 1 $Composite 1 %d; ',SpringID_R, Node04, Node40, ConData.pt, ConData.g, ConData.tep, ConData.bep, SecDataCi.tf(idxCi), ConData.d_b, SecDataB.d(idxB), SecDataCi.d(idxCi), SecDataCi.tw(idxCi), SecDataCi.Ix(idxCi), ConData.tbp, ConData.DP,ConData.BP, ConData.tdp, ConData.StiffenerC, ConData.nrows, Units);  
                elseif Axis==NBay+1
                    fprintf(INP,'Spring_SR_EEPCs %d %d %d %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f $E $mu %.3f %.3f %d %d %.3f $fyP $fuP $fy $fu $fub %d %d 1 $Composite 1 %d; ',SpringID_L, Node20, Node02, ConData.pt, ConData.g, ConData.tep, ConData.bep, SecDataCi.tf(idxCi), ConData.d_b, SecDataB.d(idxB), SecDataCi.d(idxCi), SecDataCi.tw(idxCi), SecDataCi.Ix(idxCi), ConData.tbp, ConData.DP,ConData.BP, ConData.tdp, ConData.StiffenerC, ConData.nrows, Units);
                end
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