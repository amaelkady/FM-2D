function Result = read_RunOutcome(statusFile, expectedId, exitCode, allowStaticTimeout)
% Read and validate the six-line status written by the Tcl run protocol.
% expectedId prevents stale results from another invocation being accepted.
% Completed, dynamic-collapse and usable nonconvergence outcomes have
% different reached/target rules. Final pushover timeouts may return partial results.
% Accept explicitly marked partial runs; reject other incomplete outcomes.

if nargin < 4, allowStaticTimeout = false; end

%% 1. Give a matching timeout status precedence over process exit
if isfile(statusFile)
    timeoutLines = splitlines(string(fileread(statusFile)));
    if numel(timeoutLines) >= 6 && timeoutLines(1) == string(expectedId) && timeoutLines(2) == "TIMEOUT"
        reached = str2double(timeoutLines(4)); target = str2double(timeoutLines(5));
        if allowStaticTimeout && timeoutLines(3)=="STATIC" && ...
                isfinite(reached) && reached>=0 && isfinite(target) && target>0 && ...
                reached<=target+max(1e-10,1e-8*abs(target))
            Result = struct('RunId',timeoutLines(1),'State',"TIMEOUT",'Stage',"STATIC", ...
                'Reached',reached,'Target',target,'Message',timeoutLines(6),'HasResults',reached>0);
            return;
        end
        error('FM2D:Timeout', '%s', timeoutLines(6));
    end
end

%% 2. Require a successful process exit and a fresh status file
if exitCode ~= 0
    error('FM2D:ProcessFailed', 'OpenSees exited with status %d. See the run log.', exitCode);
end
if ~isfile(statusFile)
    error('FM2D:MissingRunStatus', 'OpenSees did not produce a run status file.');
end
lines = splitlines(string(fileread(statusFile)));
if numel(lines) < 6 || lines(1) ~= string(expectedId)
    error('FM2D:StaleRunStatus', 'Run status is incomplete or belongs to another run.');
end

%% 3. Decode and validate the terminal state and analysis stage
Result.RunId = lines(1);
Result.State = lines(2);
Result.Stage = lines(3);
Result.Reached = str2double(lines(4));
Result.Target = str2double(lines(5));
Result.Message = lines(6);
if ~ismember(Result.State, ["COMPLETED", "COLLAPSE", "NONCONVERGED"])
    error('FM2D:AnalysisFailed', '%s: %s', Result.State, Result.Message);
end
if ~isfinite(Result.Reached) || ~isfinite(Result.Target) || Result.Target <= 0
    error('FM2D:InvalidRunStatus', 'Invalid reached/target values in run status.');
end
if ~ismember(Result.Stage, ["EIGEN", "STATIC", "DYNAMIC"])
    error('FM2D:InvalidRunStatus', 'Unexpected terminal analysis stage.');
end

%% 4. Apply the completion rules for each supported outcome
tol = max(1e-10, 1e-8*abs(Result.Target));
if Result.State == "NONCONVERGED"
    if ~ismember(Result.Stage,["STATIC","DYNAMIC"]) || Result.Reached <= 0 || ...
            Result.Reached >= Result.Target || Result.Stage=="STATIC" && Result.Reached>=Result.Target-tol
        error('FM2D:InvalidRunStatus', 'Invalid nonconvergence outcome.');
    end
elseif Result.State == "COLLAPSE"
    if Result.Stage ~= "DYNAMIC" || Result.Reached < 0 || Result.Reached > Result.Target+tol
        error('FM2D:InvalidRunStatus', 'Invalid collapse outcome.');
    end
elseif Result.Stage == "DYNAMIC"
    if abs(Result.Reached-Result.Target) > tol
        error('FM2D:IncompleteRun', 'Dynamic analysis ended at %.8g; target was %.8g.', Result.Reached, Result.Target);
    end
elseif Result.Reached < Result.Target-tol
    error('FM2D:IncompleteRun', 'Analysis did not reach its target.');
end
end
