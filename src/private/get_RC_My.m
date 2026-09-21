%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function computes My as per Panagiotakos and Fardis (2001)
%
% Input units: mm & MPa
%
% Computed My is in kN.m units
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [My]=get_RC_My(fc,Ec,fy,Es,b,h,d1,area_T,area_C,area_S,PPc)

d       = h-d1;
delta1  = d1/d;
P       = PPc*b*d*fc;
n       = Es/Ec;
esy     = fy/Es;
ecu     = 0.003;

rho_T   = area_T/b/d;
rho_C   = area_C/b/d;
rho_S   = area_S/b/d;

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
    A       = rho_T+rho_C+rho_S +(P/b/d/fy);
    B       = rho_T+rho_C*delta1+0.5*rho_S*(1+delta1) +(P/b/d/fy);
    ky      = (n^2*A^2+2*n*B)^0.5-n*A;
    curv_y  = fy/Es/(1-ky)/d;
else
    A       = rho_T+rho_C+rho_S -(P/1.8/n/b/d/fc);
    B       = rho_T+rho_C*delta1+0.5*rho_S*(1+delta1);
    ky      = (n^2*A^2+2*n*B)^0.5-n*A;
    curv_y  = 1.8*fc/(Ec*d*ky);
end


term1   = Ec*ky^2/2*(0.5*(1+delta1)-ky/3);
term2   = Es/2*((1-ky)*rho_T+(ky-delta1)*rho_C+rho_S/6*(1-delta1))*(1-delta1);

My      = b*d^3*curv_y*(term1+term2)*10^-6;

