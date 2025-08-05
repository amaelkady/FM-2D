function [Ke, Mye, Mc, Mres, theta_p, theta_pc, theta_u, Lmda] = Get_Model_Column (htw, h,tw,bf,tf,A, ry, Ix, Zx, E, fy, L, Lb, PgPye, k, type)

G = E/2/(1+0.3);

Ks = G*A*k*L/(0.85+2.32*bf*tf/h/tw);
Kb = 3 * E * Ix / (k*L);
Ke = 1 / (1/Ks+1/Kb);

if PgPye <= 0.2
    Mye = 1.15*fy * Zx*(1-PgPye/2);
else
    Mye = 1.15*fy * Zx*(9/8)*(1-PgPye);
end

if type == "monotonic backbone"

    McMy = 12.5 * (htw)^-0.2 * (Lb/ry)^-0.4 * (1-PgPye)^0.4;
    McMy = max(McMy, 1);
    McMy = min(McMy, 1.3); 
    Mc = McMy * Mye;

    MresMye = 0.5-0.4*PgPye;
    Mres    = MresMye * Mye;
    
    theta_p  = 294 * htw^-1.7 * (Lb/ry)^-0.7 * (1-PgPye)^1.6;
    theta_pc = 90  * htw^-0.8 * (Lb/ry)^-0.8 * (1-PgPye)^2.5;

    theta_p  = min(theta_p,  0.2);
    theta_pc = min(theta_pc, 0.3);

    theta_u  =	0.15;

end

if type == "first-cycle envelope"

    McMy = 9.5 * (htw)^-0.4 * (Lb/ry)^-0.16 * (1-PgPye)^0.2;
    McMy = max(McMy, 1);
    McMy = min(McMy, 1.3); 
    Mc = McMy * Mye;

    MresMye = 0.4-0.4*PgPye;
    Mres = MresMye * Mye;

    theta_p  = 15 * htw^-1.6 * (Lb/ry)^-0.3 * (1-PgPye)^2.3;
    theta_pc = 14 * htw^-0.8 * (Lb/ry)^-0.5 * (1-PgPye)^3.2;

    theta_p  = min(theta_p, 0.1);
    theta_pc = min(theta_pc, 0.1);
    
    theta_u  =	0.08 * (1-0.6*PgPye);

end

if PgPye <= 0.35
    Lmda = 25500 * (htw)^-2.14 * (Lb/ry)^-0.53 * (1-PgPye)^4.92;
else
    Lmda = 268000* (htw)^-2.30 * (Lb/ry)^-1.30 * (1-PgPye)^1.19;
end
Lmda = min(Lmda, 3); 
