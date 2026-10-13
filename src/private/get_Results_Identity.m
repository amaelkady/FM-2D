function identity = get_Results_Identity(RFpath, SubRFname)
% Describe the source files used to validate a visualization cache.
% The identity includes the canonical folder, optional run ID, sorted filenames,
% file sizes and high-resolution modification times; legacy runs are supported.
% Identity of the current recorder set; supports runs without RunResult.mat.

%% 1. Resolve the results directory and require recorder output
folder = fullfile(RFpath, 'Results', SubRFname);
if ~isfolder(folder)
    error('FM2D:MissingResults', 'Results folder was not found: %s.', folder);
end
folder = char(java.io.File(folder).getCanonicalPath());
files = dir(fullfile(folder, '*.out'));
if isempty(files)
    error('FM2D:MissingResults', 'No recorder files were found in %s.', folder);
end

%% 2. Include optional run metadata in the source identity
runFile = fullfile(folder, 'RunResult.mat');
runId = '';
if isfile(runFile)
    saved = load(runFile);
    if isfield(saved, 'RunResult') && isstruct(saved.RunResult) && isfield(saved.RunResult, 'RunId')
        runId = char(string(saved.RunResult.RunId));
    end
    files = [files;dir(runFile)];
end

%% 3. Sort sources and collect stable file metadata
[~, order] = sort({files.name});
files = files(order);
identity = struct('Version', 1, 'Folder', folder, 'RunId', runId, 'Files', []);
metadata = repmat(struct('Name', '', 'Bytes', 0, 'Modified', ''), numel(files), 1);
options = javaArray('java.nio.file.LinkOption', 0);
for k = 1:numel(files)
    file = java.io.File(fullfile(folder, files(k).name));
    attributes = javaMethod('readAttributes', 'java.nio.file.Files', file.toPath(), ...
        'basic:lastModifiedTime,size', options);
    modified = attributes.get('lastModifiedTime');
    metadata(k).Name = files(k).name;
    metadata(k).Bytes = double(attributes.get('size'));
    metadata(k).Modified = char(modified.toString());
end
identity.Files = metadata;
end
