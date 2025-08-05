%% get_Tsunami_Force evaluates tsunami force according to Bahmanpour et al. (2016)
%
% INPUT
%----------------------
%
% TTH_Data      matrix containing the tsunami time history
% HBuilding     building height [m]
% TD_MF         frame tributary width [m]
% ro_water      water density [t/m3]
% Drag_Coeff    drag coefficient
%
% OUTPUT
%----------------------
%
% TTH_dt        tsunami time-history time step [sec]
% TTHpoints     tsunami time-history number of data points
% F             total tsunami force history [kN]
% Hinundation   inundation depth history [m]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [TTH_dt, TTHpoints, F, Hinundation] = get_Tsunami_Force(TTH_Data, TD_MF, ro_water, Drag_Coeff, Units)

time           = TTH_Data(:,1);
Hinundation    = TTH_Data(:,2);
Vflow          = TTH_Data(:,3);

if Units ==1
    TD_MF=TD_MF/1000;
end

F = 0.5 * ro_water * Drag_Coeff * Vflow.^2.* Hinundation.* TD_MF; % kN or Kips

F = sign(Vflow).*F;

TTH_dt = time(2)-time(1);

TTHpoints = size(time,1);