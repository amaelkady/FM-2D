function [Ke, Vy, Vp_4gamma, Vp_6gamma, gamma_y, gamma4_y, gamma6_y] = Get_Model_PZ (hc, hb, tcw, tdp, bcf, tcf, IxC, E, fy)


tpz = tcw + tdp;

G = E/2/(1+0.3);

Ks = tpz * (hc - tcf) * G;   							    % PZ Stiffness: Shear Contribution
Kb = 12 * E * (IxC + tdp * (hc - 2*tcf)^3/12) /hb^3 * hb;  % PZ Stiffness: Bending Contribution
Ke = (Ks * Kb) / (Ks + Kb);   							   % PZ Stiffness: Total

Ksf = 2 * (bcf * tcf) * G;   							% Flange Stiffness: Shear Contribution
Kbf = 2 * 12 * E * bcf * tcf^3/12. /hb^3 * hb;          % Flange Stiffness: Bending Contribution
Kef = (Ksf * Kbf) / (Ksf + Kbf);   						% Flange Stiffness: Total

ay = (0.58 * Kef / Ke  + 0.88) / (1 - Kef / Ke);

aw_eff_4gamma = 1.10;
aw_eff_6gamma = 1.15;

af_eff_4gamma = 0.93 * Kef / Ke  + 0.015;
af_eff_6gamma = 1.05 * Kef / Ke  + 0.020;

Vy 		    = 0.577 * fy *  ay			  * (hc - tcf) * tpz;  										  % Yield Shear Force
Vp_4gamma 	= 0.577 * fy * (aw_eff_4gamma * (hc - tcf) * tpz + af_eff_4gamma * (bcf - tcw) * 2*tcf);  % Plastic Shear Force @ 4 gammaY
Vp_6gamma 	= 0.577 * fy * (aw_eff_6gamma * (hc - tcf) * tpz + af_eff_6gamma * (bcf - tcw) * 2*tcf);  % Plastic Shear Force @ 6 gammaY

gamma_y  = Vy/Ke; 
gamma4_y = 4.0 * gamma_y;  
gamma6_y = 6.0 * gamma_y;