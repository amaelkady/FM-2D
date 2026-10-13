function Result = read_FM2D_RunOutcome(statusFile, expectedId, exitCode)
% Accept usable static nonconvergence outcomes; reject other incomplete runs.
if isfile(statusFile)
    timeoutLines=splitlines(string(fileread(statusFile)));
    if numel(timeoutLines)>=6 && timeoutLines(1)==string(expectedId) && timeoutLines(2)=="TIMEOUT"
        error('FM2D:Timeout','%s',timeoutLines(6));
    end
end
if exitCode ~= 0
    error('FM2D:ProcessFailed','OpenSees exited with status %d. See the run log.',exitCode);
end
if ~isfile(statusFile)
    error('FM2D:MissingRunStatus','OpenSees did not produce a run status file.');
end
lines = splitlines(string(fileread(statusFile)));
if numel(lines)<6 || lines(1)~=string(expectedId)
    error('FM2D:StaleRunStatus','Run status is incomplete or belongs to another run.');
end
Result.RunId=lines(1);
Result.State=lines(2);
Result.Stage=lines(3);
Result.Reached=str2double(lines(4));
Result.Target=str2double(lines(5));
Result.Message=lines(6);
if ~ismember(Result.State,["COMPLETED","COLLAPSE","NONCONVERGED"])
    error('FM2D:AnalysisFailed','%s: %s',Result.State,Result.Message);
end
if ~isfinite(Result.Reached) || ~isfinite(Result.Target) || Result.Target<=0
    error('FM2D:InvalidRunStatus','Invalid reached/target values in run status.');
end
if ~ismember(Result.Stage,["EIGEN","STATIC","DYNAMIC"])
    error('FM2D:InvalidRunStatus','Unexpected terminal analysis stage.');
end
tol=max(1e-10,1e-8*abs(Result.Target));
if Result.State=="NONCONVERGED"
    if Result.Stage~="STATIC" || Result.Reached<=0 || Result.Reached>=Result.Target-tol
        error('FM2D:InvalidRunStatus','Invalid static nonconvergence outcome.');
    end
elseif Result.State=="COLLAPSE"
    if Result.Stage~="DYNAMIC" || Result.Reached<0 || Result.Reached>Result.Target+tol
        error('FM2D:InvalidRunStatus','Invalid collapse outcome.');
    end
elseif Result.Stage=="DYNAMIC"
    if abs(Result.Reached-Result.Target)>tol
        error('FM2D:IncompleteRun','Dynamic analysis ended at %.8g; target was %.8g.',Result.Reached,Result.Target);
    end
elseif Result.Reached<Result.Target-tol
    error('FM2D:IncompleteRun','Analysis did not reach its target.');
end
end
