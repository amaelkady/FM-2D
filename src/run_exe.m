function [RunTime, Result] = run_exe(OpenSEESFileName, ShowOpenseesStatus, timeoutMinutes, Job)
%RUN_EXE Run an OpenSees model and validate its terminal analysis status.
%   OpenSEESFileName   : Model Tcl file, resolved from the current folder or
%                       the application folder.
%   ShowOpenseesStatus : Set to 1 to display captured OpenSees console output.
%   timeoutMinutes     : Optional positive runtime limit in minutes. Inf
%                       disables the limit. If omitted, use MaxRunTime from
%                       temp_unpacked.mat, or ten minutes as the fallback.
%   Job               : Optional GM/realization metadata and sampling Seed.
%
%   RunTime is elapsed process time in seconds. Result contains the validated
%   outcome, reached/target values, run identity and log location. Each call
%   retains its diagnostics in a separate RunLogs folder.

%% 1. Resolve and validate the runtime limit
mainDir = fileparts(mfilename('fullpath'));
if nargin < 4
    Job = struct();
end
seeded = isfield(Job,'Seed') && ~isempty(Job.Seed);
if seeded
    validateattributes(Job.Seed, {'numeric'}, ...
        {'scalar','integer','positive','<=',2147483646});
end

if nargin < 3
    timeoutMinutes = 10;
    configFile = fullfile(mainDir, 'temp_unpacked.mat');

    if isfile(configFile)
        config = load(configFile, 'MaxRunTime');
        if isfield(config, 'MaxRunTime') && config.MaxRunTime > 0
            timeoutMinutes = config.MaxRunTime;
        end
    end
end

validateattributes(timeoutMinutes, {'numeric'}, ...
    {'real', 'scalar', 'positive', 'nonnan'});
timeoutSeconds = 60 * timeoutMinutes;

%% 2. Resolve the model and create an isolated run folder
model = char(strtrim(string(OpenSEESFileName)));
if ~isfile(model)
    model = fullfile(mainDir, model);
end
if ~isfile(model)
    error('FM2D:MissingModel', 'Model Tcl file was not found.');
end

[ok, info] = fileattrib(model);
if ~ok
    error('FM2D:MissingModel', 'Cannot resolve model file.');
end
model = info.Name;

logRoot = fullfile(mainDir, 'RunLogs');
if ~isfolder(logRoot)
    mkdir(logRoot);
end
runFolder = tempname(logRoot);
mkdir(runFolder);
[~, runId] = fileparts(runFolder);

statusFile = fullfile(runFolder, 'status.txt');
logFile = fullfile(runFolder, 'OpenSees.log');
driver = fullfile(runFolder, 'driver.tcl');
protocol = fullfile(mainDir, 'FM2D_RunProtocol.tcl');

%% 3. Write the per-run Tcl driver
% The driver supplies a unique identity, status/collapse paths and deadline,
% then invokes the model through the shared error/status protocol.
if ~isfile(protocol)
    error('FM2D:MissingProtocol', ...
        'Install FM2D_RunProtocol.tcl beside run_exe.m.');
end

f = fopen(driver, 'w');
if f < 0
    error('FM2D:FileError', 'Cannot write the run driver.');
end
cleanup = onCleanup(@() fclose(f));

fprintf(f, 'set FM2D_RunId %s\n', tclString(runId));
fprintf(f, 'set FM2D_StatusFile %s\n', tclString(statusFile));
fprintf(f, 'set FM2D_CollapseDir %s\n', tclString(runFolder));
if seeded
    fprintf(f, 'expr {srand(%d)}\n', Job.Seed);
end

if isfinite(timeoutSeconds)
    fprintf(f, 'set FM2D_DeadlineMs [expr {[clock milliseconds]+%.0f}]\n', ...
        ceil(timeoutSeconds * 1000));
else
    fprintf(f, 'set FM2D_DeadlineMs Inf\n');
end

fprintf(f, 'source %s\n', tclString(protocol));
fprintf(f, 'exit [FM2D_RunModel %s]\n', tclString(model));
clear cleanup % Close the driver before OpenSees reads it.

%% 4. Launch and supervise the OpenSees process
% Preserve the caller's working directory for existing model-relative paths.
% The supervisor captures output and terminates this child on timeout.
exe = fullfile(mainDir, 'OpenSees.exe');
try
    ProcessResult = run_Process_WithDeadline( ...
        exe, ['"' driver '"'], pwd, timeoutSeconds, ...
        ShowOpenseesStatus == 1, logFile);
catch ME
    % A launch/supervision exception may occur before Tcl writes any status.
    failure = struct('RunId', runId, 'State', 'FAILED', ...
        'LogFile', logFile, 'Error', ME.message);
    failure.Job = Job;
    save(fullfile(runFolder, 'Failure.mat'), 'failure');
    rethrow(ME)
end

RunTime = ProcessResult.RunTime;
exitCode = ProcessResult.ExitCode;

%% 5. Record a forced timeout in the shared status format
% A terminated child may leave STARTED or no status at all. Replace it with
% TIMEOUT, retaining the last known stage only when its run identity matches.
if ProcessResult.TimedOut
    stage = 'MODEL';
    if isfile(statusFile)
        lines = splitlines(string(fileread(statusFile)));
        if numel(lines) >= 3 && lines(1) == string(runId)
            stage = char(lines(3));
        end
    end

    f = fopen(statusFile, 'w');
    if f < 0
        error('FM2D:FileError', 'Cannot save timeout status.');
    end
    fprintf(f, '%s\nTIMEOUT\n%s\nNaN\nNaN\nAnalysis runtime limit exceeded\n', ...
        runId, stage);
    fclose(f);
end

%% 6. Validate the terminal outcome and retain failure diagnostics
% The reader checks process exit, run identity, stage and reached/target
% values. It accepts completed runs, dynamic collapse and usable static
% NONCONVERGED outcomes under their respective validation rules.
try
    Result = read_RunOutcome(statusFile, runId, exitCode);
catch ME
    failure = struct('RunId', runId, 'ExitCode', exitCode, ...
        'LogFile', logFile, 'Error', ME.message, ...
        'ProcessResult', ProcessResult);
    failure.State = 'FAILED';
    failure.Job = Job;
    if strcmp(ME.identifier, 'FM2D:Timeout')
        failure.State = 'TIMEOUT';
    end
    save(fullfile(runFolder, 'Failure.mat'), 'failure');

    % Keep timeout identifiable; attach the underlying cause for other errors.
    if strcmp(ME.identifier, 'FM2D:Timeout')
        error('FM2D:Timeout', '%s\nRun log: %s', ME.message, logFile);
    end
    wrapped = MException('FM2D:RunFailed', '%s\nRun log: %s', ...
        ME.message, logFile);
    throw(addCause(wrapped, ME));
end

%% 7. Save and return the validated run result
Result.RunTime = RunTime;
Result.LogFile = logFile;
if ~isempty(fieldnames(Job))
    Result.Job = Job;
end
save(fullfile(runFolder, 'RunResult.mat'), 'Result');
end

%% Local helper: quote values safely in the generated Tcl driver
function literal = tclString(value)
% Normalize Windows paths and escape Tcl substitutions inside double quotes.
value = strrep(char(value), '\', '/');
value = strrep(value, '"', '\"');
value = strrep(value, '$', '\$');
value = strrep(value, '[', '\[');
value = strrep(value, ']', '\]');
literal = ['"' value '"'];
end
