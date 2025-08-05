function [Backbone] = get_backbone_Beam (E, fy, NStory, WBay, MF_COLUMNS, MF_BEAMS, Floor, Bay, MFconnection, a, b, c, k_beambracing,Units)

Axisi=Bay; Axisj=Bay+1;

Story=min(NStory,Floor);

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

if Units ==1
    convfactor=1000;
else
    convfactor = 6.89476;
end

if MFconnection == 0
    [Ke, Mye, Mc, Mres, theta_p, theta_pc, theta_u, Lmda] = Get_Model_Beam (SecDataB.h_tw(idxB), SecDataB.d(idxB),SecDataB.tw(idxB),SecDataB.bf(idxB),SecDataB.tf(idxB),SecDataB.Area(idxB), SecDataB.ry(idxB), a, b, c, SecDataB.Ix(idxB), SecDataB.Zx(idxB), E, fy, L_BEAM, 0.5, k_beambracing, "RBS", convfactor);

elseif MFconnection == 1

    [Ke, Mye, Mc, Mres, theta_p, theta_pc, theta_u, Lmda] = Get_Model_Beam (SecDataB.h_tw(idxB), SecDataB.d(idxB),SecDataB.tw(idxB),SecDataB.bf(idxB),SecDataB.tf(idxB),SecDataB.Area(idxB), SecDataB.ry(idxB), a, b, c, SecDataB.Ix(idxB), SecDataB.Zx(idxB), E, fy, L_BEAM, 0.5, k_beambracing, "non-RBS", convfactor);

end


Backbone.Ke=Ke;
Backbone.Mye=Mye;
Backbone.Mc=Mc;
Backbone.Mres=Mres;
Backbone.theta_p=theta_p;
Backbone.theta_pc=theta_pc;
Backbone.theta_u=theta_u;
Backbone.Lmda=Lmda;