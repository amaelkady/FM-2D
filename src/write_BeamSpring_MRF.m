function write_BeamSpring_MRF (INP)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'NStory','NBay', 'WBay','ModelELOption','MF_COLUMNS','MF_BEAMS','MFconnection','a','b','c','k_beambracing','fy','Units','BeamElementOption','MF_EEPCs');


fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                           MF BEAM SPRINGS                                       #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

if ModelELOption==1 && BeamElementOption==1
fprintf(INP,'# Command Syntax \n');
if MFconnection~=3
    fprintf(INP,'# Spring_Connection_FullyRigid SpringID iNode jNode E fy Ix d htw bftf ry L Ls Lb My CompositeFLAG MFconnection Units; \n');
else
    fprintf(INP,'# Spring_Connection_SR_EEPC SpringID NodeI NodeJ  pt g tep bep tcf d_b hb hc tcw Ic tbp DP BP tdp E mu0 fyP fuP fyC fuC fub StiffenerC nrows ampfactor CompositeFlag PZ_remove_flag Units; \n');
end
fprintf(INP,'\n');
else
fprintf(INP,'# Command Syntax \n');
fprintf(INP,'# Spring_Rigid SpringID iNode jNode; \n');
fprintf(INP,'\n');
end

for Floor=NStory+1:-1:2
    Story=min(NStory,Floor);
    % Define both ends of each bay using its beam and the local end columns.
    for Bay=1:NBay
        Axisi=Bay; Axisj=Bay+1;
        Section=MF_BEAMS{Floor-1,Bay};
        [SecDataB,idxB]=load_SecData(Section,Units);

        Section=MF_COLUMNS{Story,Axisi};
        [SecDataCi,idxCi]=load_SecData(Section,Units);

        Section=MF_COLUMNS{Story,Axisj};
        [SecDataCj,idxCj]=load_SecData(Section,Units);

        if MFconnection==3
            ConnectionID=1; % extended endplate
            EEPC=MF_EEPCs{Floor-1,Bay};
            [ConData] = load_PRConnParams(EEPC,ConnectionID); 
        end

        L_RBS   = a *  SecDataB.bf(idxB)+ b * SecDataB.d(idxB)/2;
        L_BEAM  =  WBay(Bay) - 0.5*SecDataCi.d(idxCi) - 0.5*SecDataCj.d(idxCj) - 2*L_RBS;
        Ls_BEAM = (WBay(Bay) - 0.5*SecDataCi.d(idxCi) - 0.5*SecDataCj.d(idxCj) - 2*L_RBS)*0.5;
        Lb_BEAM = (WBay(Bay) - 0.5*SecDataCi.d(idxCi) - 0.5*SecDataCj.d(idxCj))          *k_beambracing;

        I_RBS  =     SecDataB.Ix(idxB)   - 4 * c * SecDataB.bf(idxB) *SecDataB.tf(idxB)*((SecDataB.d(idxB)-SecDataB.tf(idxB))/2)^2 - 4 *c * SecDataB.bf(idxB)*SecDataB.tf(idxB)^3/12;

        if MFconnection ==2
            Z_RBS = SecDataB.Zx(idxB);
            My = Z_RBS*fy;
        elseif MFconnection ==1
            Z_RBS = 2 * (SecDataB.bf(idxB)   - 2 * c * SecDataB.bf(idxB))*SecDataB.tf(idxB)*(SecDataB.d(idxB)/2-SecDataB.tf(idxB)/2) + 2 * (SecDataB.d(idxB)/2-SecDataB.tf(idxB))*SecDataB.tw(idxB)*(SecDataB.d(idxB)/2-SecDataB.tf(idxB))/2;
            My = Z_RBS*fy;
        end

        % The left beam end is right of Axisi; the right end is left of Axisj.
        SpringID_i=900000+Floor*1000+Axisi*100+04;
        SpringID_j=900000+Floor*1000+Axisj*100+02;

        Node04 = 100 *Floor+10 *Axisi+04;
        Node40 = 1000*Floor+100*Axisi+40;
        Node02 = 100 *Floor+10 *Axisj+02;
        Node20 = 1000*Floor+100*Axisj+20;

        if ModelELOption==1 && BeamElementOption==1
            if MFconnection~=3
                fprintf(INP,'Spring_Connection_FullyRigid %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f $Composite %d %d; ',SpringID_i,Node40,Node04,I_RBS, SecDataB.d(idxB),SecDataB.h_tw(idxB),SecDataB.bf_tf(idxB), SecDataB.ry(idxB), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
                fprintf(INP,'Spring_Connection_FullyRigid %d %d %d $E $fy [expr $Comp_I*%.3f] %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f $Composite %d %d; ',SpringID_j,Node02,Node20,I_RBS, SecDataB.d(idxB),SecDataB.h_tw(idxB),SecDataB.bf_tf(idxB), SecDataB.ry(idxB), L_BEAM, Ls_BEAM, Lb_BEAM, My, MFconnection, Units);
            else
                fprintf(INP,'Spring_Connection_SR_EEPC %d %d %d %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %d %d %.3f $E $mu $fyP $fuP $fy $fu $fub %d %d 1 $Composite 1 %d; ',SpringID_i, Node04, Node40, ConData.pt, ConData.g, ConData.tep, ConData.bep, SecDataCi.tf(idxCi), ConData.d_b, SecDataB.d(idxB), SecDataCi.d(idxCi), SecDataCi.tw(idxCi), SecDataCi.Ix(idxCi), ConData.tbp, ConData.DP,ConData.BP, ConData.tdp, ConData.StiffenerC, ConData.nrows, Units);
                fprintf(INP,'Spring_Connection_SR_EEPC %d %d %d %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %d %d %.3f $E $mu $fyP $fuP $fy $fu $fub %d %d 1 $Composite 1 %d; ',SpringID_j, Node20, Node02, ConData.pt, ConData.g, ConData.tep, ConData.bep, SecDataCj.tf(idxCj), ConData.d_b, SecDataB.d(idxB), SecDataCj.d(idxCj), SecDataCj.tw(idxCj), SecDataCj.Ix(idxCj), ConData.tbp, ConData.DP,ConData.BP, ConData.tdp, ConData.StiffenerC, ConData.nrows, Units);
            end
        else
            fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_i,Node40,Node04);
            fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_j,Node02,Node20);
        end
    end
    fprintf(INP,'\n');
end

fprintf(INP,'\n');
