%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% SDOF solution using Central Difference Method
%
% Peak pseudo-spectral acceleration, in the physical acceleration units of g.
% acc is a vector in units of g, sampled at t = 0, dt, ..., (N-1)*dt.
% Zero initial displacement/velocity; no free-vibration tail is added.
% Propagate the elastic oscillator exactly for linearly interpolated input.
% Substeps resolve response peaks; they do not impose a stability condition.
%
% Input Parameters:
%-------------------
% T1 	= Period
% dt    = time step (equal to time step of the earthquake
% zeta  = damping ratio
% acc   = acceleration history
% g     = gravity acceleration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Amax = get_SA_SDoF(T1, dt, zeta, acc, g)


validateattributes(T1, {'numeric'}, {'real','finite','scalar','positive'});
validateattributes(dt, {'numeric'}, {'real','finite','scalar','positive'});
validateattributes(zeta, {'numeric'}, {'real','finite','scalar','nonnegative'});
validateattributes(g, {'numeric'}, {'real','finite','scalar','positive'});
validateattributes(acc, {'numeric'}, {'real','finite','vector','nonempty'});
if numel(acc) < 2
    error('FM2D:SpectrumTooShort', 'At least two acceleration samples are required.');
end
acc = double(acc(:));
omega = 2*pi/double(T1);
nSub = max(1, ceil(20*double(dt)/double(T1)));
h = double(dt)/nSub;

% Scaled states: q = omega^2*u/g; r = omega*v/g.
% [q; r; a; slope]' = M*[q; r; a; slope], with a = -acc.
M = [0 omega 0 0; -omega -2*double(zeta)*omega omega 0; ...
     0 0 0 1; 0 0 0 0];
E = expm(M*h);
F = E(1:2,1:2);
Bnext = E(1:2,4)/h;
Bprev = E(1:2,3)-Bnext;

q = 0; r = 0; peak = 0;
for k = 1:numel(acc)-1
    aStart = -acc(k);
    da = -(acc(k+1)-acc(k))/nSub;
    for j = 1:nSub
        aPrev = aStart+(j-1)*da;
        aNext = aStart+j*da;
        qNext = F(1,1)*q+F(1,2)*r+Bprev(1)*aPrev+Bnext(1)*aNext;
        r = F(2,1)*q+F(2,2)*r+Bprev(2)*aPrev+Bnext(2)*aNext;
        q = qNext;
        peak = max(peak,abs(q));
    end
end
Amax = double(g)*peak;
if ~isfinite(Amax)
    error('FM2D:InvalidSpectrum', 'The computed spectral acceleration is not finite.');
end
end
