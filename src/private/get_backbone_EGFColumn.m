
function [Backbone] = get_backbone_EGFColumn  (E, fy, SectionC, L_Col, PgPy, Units)


[SecDataC]=Load_SecData (SectionC, Units);
idx=min(find(contains(SecDataC.Name,SectionC)));

Ls_Col =  L_Col*0.5;
Lb_Col =  L_Col;

Py                  = SecDataC.Area(idx) * fy;

[Ke, Mye, Mc, Mres, theta_p, theta_pc, theta_u, Lmda] = Get_Model_Column (SecDataC.h_tw(idx), SecDataC.d(idx),SecDataC.tw(idx),SecDataC.bf(idx),SecDataC.tf(idx),SecDataC.Area(idx), SecDataC.ry(idx), SecDataC.Ix(idx), SecDataC.Zx(idx), E, fy, Ls_Col, Lb_Col, PgPy, 0.5, "monotonic backbone");

Backbone.Ke=Ke;
Backbone.Mye=Mye;
Backbone.Mc=Mc;
Backbone.Mres=Mres;
Backbone.theta_p=theta_p;
Backbone.theta_pc=theta_pc;
Backbone.theta_u=theta_u;
Backbone.Lmda=Lmda;
