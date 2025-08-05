
function [Backbone] = get_backbone_Column  (E, fy, HStory, MF_COLUMNS, MF_BEAMS, Splice, NStory, NBay, Floor, Axis, Pred, Units)

Story=min(NStory,Floor);

Bay = Axis;

Section=MF_COLUMNS{Story,Axis}; if Splice(max(1,Floor-1),1)==1; Section = MF_COLUMNS{Floor,Axis}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel
[SecDataC]=Load_SecData (Section, Units);
idx=min(find(contains(SecDataC.Name,Section)));

Section=MF_BEAMS{min(Story,Floor),min(NBay,Bay)};
[SecDataB1]=Load_SecData (Section, Units);
idxB1=min(find(contains(SecDataB1.Name,Section)));

Section=MF_BEAMS{max(1,Floor-1),min(NBay,Bay)};
[SecDataB2]=Load_SecData (Section, Units);
idxB2=min(find(contains(SecDataB2.Name,Section)));

L_Col  =  HStory(Story) - 0.5*SecDataB1.d(idxB1) - 0.5*SecDataB2.d(idxB2);
Ls_Col =  L_Col*0.5;
Lb_Col =  L_Col;

Py                  = SecDataC.Area(idx) * fy;
PgPy                = Pred(Story,Axis)/Py;

[Ke, Mye, Mc, Mres, theta_p, theta_pc, theta_u, Lmda] = Get_Model_Column (SecDataC.h_tw(idx), SecDataC.d(idx),SecDataC.tw(idx),SecDataC.bf(idx),SecDataC.tf(idx),SecDataC.Area(idx), SecDataC.ry(idx), SecDataC.Ix(idx), SecDataC.Zx(idx), E, fy, Ls_Col, Lb_Col, PgPy, 0.5, "monotonic backbone");

Backbone.Ke=Ke;
Backbone.Mye=Mye;
Backbone.Mc=Mc;
Backbone.Mres=Mres;
Backbone.theta_p=theta_p;
Backbone.theta_pc=theta_pc;
Backbone.theta_u=theta_u;
Backbone.Lmda=Lmda;
