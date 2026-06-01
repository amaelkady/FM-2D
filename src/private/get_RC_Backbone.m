%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function computes the backbone curve of an RC beam-column
% as per Haselton et al. (2008)
%
% Input units: mm & MPa
%
% Computed My is in kN.m units
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [My]=get_RC_Backbone(fc,Ec,fy,Es,b,h,d1,s,area_T,area_C,area_I,area_SH,PPc, bond_slip, Units)

if Units == 1
    c_unit=1.0;
else
    c_unit=6.895;
end

d       = h-d1;
delta1  = d1/d;
P       = PPc*b*d*fc;
n       = Es/Ec;
esy     = fy/Es;
ecu     = 0.003;

rho_T   = area_T/b/d;
rho_C   = area_C/b/d;
rho_I   = area_I/b/d;
rho_SH  = area_SH/b/s;

if fc<27.6
    beta1=0.85;
elseif fc>55.17
    beta1=0.65;
else
    beta1=1.05-0.05*(fc/6.9);
end

c  = (area_T*fy - area_C*fy + P)/(0.85*fc*beta1*b);
cb = (ecu*d)/(ecu+esy); % depth of compression block at balanced

if c<cb
    A       = rho_T+rho_C+rho_I +(P/b/d/fy);
    B       = rho_T+rho_C*delta1+0.5*rho_I*(1+delta1) +(P/b/d/fy);
    ky      = (n^2*A^2+2*n*B)^0.5-n*A;
    curv_y  = fy/Es/(1-ky)/d;
else
    A       = rho_T+rho_C+rho_I -(P/1.8/n/b/d/fc);
    B       = rho_T+rho_C*delta1+0.5*rho_I*(1+delta1);
    ky      = (n^2*A^2+2*n*B)^0.5-n*A;
    curv_y  = 1.8*fc/(Ec*d*ky);
end


term1   = Ec*ky^2/2*(0.5*(1+delta1)-ky/3);
term2   = Es/2*((1-ky)*rho_T+(ky-delta1)*rho_C+rho_I/6*(1-delta1))*(1-delta1);

My      = b*d^3*curv_y*(term1+term2)*10^-6;

%##################################################################
% Compute backbone parameters as per Haselton et al (2008)
%##################################################################

theta_p  	= 0.13*(1+0.55*bond_slip) 	* 0.130^PPc * (0.02+40*rho_SH)^0.65 * 0.57^(0.01*c_unit*fc);
theta_pc 	= 0.76 			    	* 0.031^PPc * (0.02+40*rho_SH)^1.02; if theta_pc  > 0.10; theta_pc= 0.1; end
theta_p_tot = 0.14*(1+0.40*bond_slip) 	* 0.190^PPc * (0.02+40*rho_SH)^0.54 * 0.62^(0.01*c_unit*fc);
theta_y  	= theta_p_tot - theta_p;
theta_u  	= theta_p_tot + theta_pc;
McMy     	= 1.25 	 				* 0.890^PPc 								*  0.91^(0.01*c_unit*fc);
Mc          = McMy * My;
lambda   	= 170.7	 				* 0.270^PPc * 0.10^(s/d);
Et   	 	=lambda * My * theta_y;
Ke   	 	=My / theta_y;


%% Plot

figure('position',[100 100 400 300],'color','white');
plot([0 theta_y theta_p_tot theta_u], ...
     [0 My      Mc          0], ...
     '-k');
 xlabel ('\theta [rad]');
 ylabel ('M [kN.m]');
 set(gca, 'fontname', 'times', 'fontsize',16);
