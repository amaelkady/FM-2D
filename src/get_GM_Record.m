function [time, acc, dt, velocity, displacement] = get_GM_Record(GM, recordNumber)
% Return the full imported ground-motion record with a zero-based time axis.
% Optional velocity/displacement outputs integrate acceleration in its stored
% units. No analysis free-vibration tail or scale factor is appended.
% Full imported record. Free vibration belongs to the analysis, not this data.
% Samples use the same t=0 origin as the OpenSees ground-motion path.

%% 1. Read and validate the selected record
acc = GM.acc{recordNumber};
dt = GM.dt{recordNumber};
validateattributes(acc, {'numeric'}, {'real', 'finite', 'vector', 'nonempty'});
validateattributes(dt, {'numeric'}, {'real', 'finite', 'scalar', 'positive'});
if numel(acc) < 2
    error('FM2D:ShortGroundMotion', 'At least two acceleration samples are required.');
end
acc = double(acc(:));
dt = double(dt);

%% 2. Build sample times and compute only the requested integrals
time = (0:numel(acc)-1)'*dt;
if nargout >= 4
    velocity = cumtrapz(time, acc);
end
if nargout >= 5
    displacement = cumtrapz(time, velocity);
end
end
