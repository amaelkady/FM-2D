function [Ke, Mye, Mc, Mres, theta_p, theta_pc, theta_u, Lmda] = Get_Model_Beam (htw, h, tw, bf, tf, A, ry, a, b, c, Ix, Zx, E, fy, L, k, k_beambracing, type, convfactor)

G = E/2/(1+0.3);

bftf = bf/2/tf;

L_RBS   = a * bf + b * h/2;
L_BEAM  =  L - 2*L_RBS;
Ls = (L - 2*L_RBS)*k;
Lb = (L)          *k_beambracing;

if type == "RBS"
    A_RBS  =     A - 4 * c * bf*tf;
    I_RBS  =     Ix - 4 * c * bf *tf*((h-tf)/2)^2 - 4 *c * bf*tf^3/12;
    Z_RBS  = 2 * (bf - 2 * c * bf) * tf *(h/2-tf/2) + 2 * (h/2-tf)*tw*(h/2-tf)/2;
else
    A_RBS = A;
    I_RBS = Ix;
    Z_RBS = Zx;
end

Ks = G*A_RBS*k*L_BEAM/(0.85+2.32*bf*tf/h/tw);
Kb = 3 * E * I_RBS / (k*L_BEAM);
Ke = 1 / (1/Ks+1/Kb);

Mye = 1.1 * Z_RBS * fy;

if type == "RBS"

    McMy = 1.1;
    Mc = McMy * Mye;

    MresMye = 0.4;
    Mres = MresMye * Mye;

    theta_p  = 0.19 * htw^-0.314 * bftf^-0.100 * (Lb/ry)^-0.185 * (Ls/h)^0.113 * (h/533)^-0.76 * (fy*1000/355)^-0.070;
    theta_pc = 9.52 * htw^-0.513 * bftf^-0.863 * (Lb/ry)^-0.108                                * (fy*1000/355)^-0.360;
    Lmda     = 585  * htw^-1.14  * bftf^-0.632 * (Lb/ry)^-0.205                                * (fy*1000/355)^-0.391;

    theta_u  =	0.2;

end

if type == "non-RBS"

    McMy = 1.1;
    Mc = McMy * Mye;

    MresMye = 0.4;
    Mres = MresMye * Mye;

    if h > 25.4*21
        theta_p  = 0.318  * htw^-0.550 * bftf^-0.345 * (Lb/ry)^-0.023 * (Ls/h)^0.090 * (h/533)^-0.330 * (fy*convfactor/355)^-0.130;
        theta_pc = 7.500  * htw^-0.610 * bftf^-0.710 * (Lb/ry)^-0.110                * (h/533)^-0.161 * (fy*convfactor/355)^-0.320;
        Lmda     = 536    * htw^-1.260 * bftf^-0.525 * (Lb/ry)^-0.130                                 * (fy*convfactor/355)^-0.291;
    else
        theta_p  = 0.0865 * htw^-0.365 * bftf^-0.140                  * (Ls/h)^0.340 * (h/533)^-0.721 * (fy*convfactor/355)^-0.230;
        theta_pc = 5.630  * htw^-0.565 * bftf^-0.800                                 * (h/533)^-0.281 * (fy*convfactor/355)^-0.430;
        Lmda     = 495    * htw^-1.340 * bftf^-0.595                                                  * (fy*convfactor/355)^-0.360;
    end

    theta_u  =	0.2;

end

