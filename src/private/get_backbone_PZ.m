function [Backbone] = get_backbone_PZ (MF_COLUMNS, MF_BEAMS, Doubler, Story, Axis, Floor, Bay, E, fy, Units)


Section=MF_COLUMNS{Story,Axis};
[SecDataC]=Load_SecData (Section,Units);
idxC=min(find(contains(SecDataC.Name,Section)));

Section=MF_BEAMS{Floor-1,Bay};
[SecDataB]=Load_SecData (Section,Units);
idxB=min(find(contains(SecDataB.Name,Section)));

tdp = Doubler(Floor-1,Axis);

[Ke, Vy, Vp_4gamma, Vp_6gamma, gamma_y, gamma4_y, gamma6_y] = Get_Model_PZ (SecDataC.d(idxC), SecDataB.d(idxB), SecDataC.tw(idxC), tdp, SecDataC.bf(idxC), SecDataC.tf(idxC), SecDataC.Ix(idxC), E, fy);

Backbone.Ke =Ke*SecDataB.d(idxB);
Backbone.Vy =Vy*SecDataB.d(idxB);
Backbone.Vp_4gamma = Vp_4gamma*SecDataB.d(idxB);
Backbone.Vp_6gamma =Vp_6gamma*SecDataB.d(idxB);
Backbone.gamma_y =gamma_y;
Backbone.gamma4_y =gamma4_y;
Backbone.gamma6_y =gamma6_y;