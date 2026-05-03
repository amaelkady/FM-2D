%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% SDOF solution using Central Difference Method
%
% Input Parameters:
%-------------------
% T1 	= Period
% dt    = time step (equal to time step of the earthquake
% zeta  = damping ratio
% acc   = acceleration history
% g     = gravity acceleration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Amax] =  Get_SA_SDoF(T1, dt, zeta, acc, g)

mass = 1.0;

p=acc*g;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now have an array p() which contains L acceleration values
% at an interval of dt sec

% omega = natural frequency
% stf = stiffness
% damping = "c"

omega   = 2.0*pi/T1;
stf     = mass*omega*omega;
damp    = 2.0*mass*omega*zeta;


%% Initial Conditions of Central Difference Method
a_prev  = p(1)/mass;
u_prev  = 0.0;
v_prev  = 0.0;
u_pp    = a_prev*dt*dt/2.0;

consA   = mass/dt/dt - damp/(2*dt);
consB   = stf - 2*mass/(dt*dt);
kbar    = mass/dt/dt + damp/(2*dt);
time(1) = 0.0;


%% Calculations for time step i
for i = 2:length(p)
    p_curr = p(i) - consA*u_pp - consB*u_prev;
    u_curr = p_curr/kbar;
    v_curr = (u_curr - u_pp)/(2*dt);
    a_curr = (u_curr - 2*u_prev + u_pp)/(dt^2);
    
    dis(i)  = 1.*u_curr;
    vv(i)   = (2*pi/T1)*u_curr;
    aa(i)   = ((2*pi/T1)^2)*u_curr;  % Spectral Ordinate

    % store current values into (i-1) for next step
    u_pp    = u_prev;
    u_prev  = u_curr;
    v_prev  = v_curr;
    a_prev  = a_curr;
    
    time(i) = time(i-1) + dt;
    
end

Amax = max(abs(aa));