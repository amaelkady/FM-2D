function [groundAcc, groundVel] = get_GM_Kinematics(acc, dt, queryTime, g)
% Evaluate unscaled ground acceleration and velocity at recorder times.
% acc is sampled every dt seconds in g; g supplies physical acceleration units.
% The default OpenSees path convention determines acceleration outside the record.
% Unscaled ground acceleration in g; ground velocity in the units of g*seconds.
% Uniform samples at 0,dt,...,(N-1)*dt, with zero acceleration outside the path.
% Matches the default PathSeries final-boundary convention (no -useLast).
% Velocity integrates the piecewise-linear input from t=0, not queryTime(1).

%% 1. Validate inputs and normalize vectors
validateattributes(acc, {'numeric'}, {'real', 'finite', 'vector', 'nonempty'});
validateattributes(dt, {'numeric'}, {'real', 'finite', 'scalar', 'positive'});
validateattributes(g, {'numeric'}, {'real', 'finite', 'scalar', 'positive'});
if numel(acc) < 2
    error('FM2D:ShortGroundMotion', 'At least two acceleration samples are required.');
end
if isempty(queryTime)
    groundAcc = zeros(0, 1);
    groundVel = zeros(0, 1);
    return;
end
validateattributes(queryTime, {'numeric'}, {'real', 'finite', 'vector'});
acc = double(acc(:));
t = double(queryTime(:));
dt = double(dt);
g = double(g);
knots = (0:numel(acc)-1)'*dt;
lastTime = knots(end);

%% 2. Interpolate acceleration with the default path boundary behavior
groundAcc = interp1(knots, acc, t, 'linear', 0);
% Current default OpenSees PathSeries returns zero at the last-data boundary.
groundAcc(t >= lastTime) = 0;

%% 3. Integrate from the record origin, including any free-vibration tail
velocityAtKnots = cumtrapz(knots, acc*g);
groundVel = zeros(size(t));
groundVel(t >= lastTime) = velocityAtKnots(end);

%% 4. Evaluate the exact integral within each linear input segment
inside = t >= 0 & t < lastTime;
if any(inside)
    ti = t(inside);
    segment = min(floor(ti/dt)+1, numel(acc)-1);
    offset = ti-knots(segment);
    slope = (acc(segment+1)-acc(segment))/dt;
    groundVel(inside) = velocityAtKnots(segment)+g*(acc(segment).*offset+0.5*slope.*offset.^2);
end
end
