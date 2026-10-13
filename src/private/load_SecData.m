function [SecData, idx] = load_SecData(Section, Units)
% Load a section database and optionally return its exact-name row index.
% Cache raw data, unit conversions and name indices by canonical source path.
% File signatures invalidate cached entries when a database/project changes.
% Cache databases, unit conversions and exact-name row indices.
% Check file metadata on every call, including project-local built-up data.
% clear load_SecData explicitly clears the cache.

%% 1. Initialize the cache and validate the requested section
global ProjectPath ProjectName resource_root
persistent databases linkOptions
if isempty(databases)
    databases = containers.Map('KeyType', 'char', 'ValueType', 'any');
    linkOptions = javaArray('java.nio.file.LinkOption', 0);
end
validateattributes(Units, {'numeric'}, {'real', 'finite', 'scalar'});
section = string(Section);
if ~isscalar(section) || ismissing(section) || strlength(strtrim(section)) == 0
    error('FM2D:InvalidSection', 'A nonempty section name is required.');
end
section = char(strtrim(section));
family = upper(section);
isBuiltUp = contains(family, 'BU');

%% 2. Select the standard database or project-local built-up data
mainDir = fileparts(fileparts(mfilename('fullpath')));
if isBuiltUp
    source = fullfile(ProjectPath, ProjectName);
    variable = 'SecData_BU';
else
    if startsWith(family, 'HSS')
        filename = 'HSS_Sec_Database.mat';
    elseif startsWith(family, 'W')
        filename = 'AISC_WF_Sec_Database.mat';
    elseif any(startsWith(family, {'IP', 'HE', 'HD', 'UB', 'UC'}))
        filename = 'EURO_I_Sec_Database.mat';
    else
        error('FM2D:UnknownSectionFamily', 'Unrecognized section family: %s.', section);
    end
    if isempty(resource_root) || all(strlength(string(resource_root)) == 0)
        source = fullfile(mainDir, filename);
    else
        source = fullfile(mainDir, 'resources', 'database', filename);
    end
    variable = 'SecData';
end

%% 3. Resolve the source identity and high-resolution file signature
sourceFile = java.io.File(char(source));
source = char(sourceFile.getCanonicalPath());
try
    attributes = javaMethod('readAttributes', 'java.nio.file.Files', sourceFile.toPath(), ...
        'basic:lastModifiedTime,size', linkOptions);
    modified = attributes.get('lastModifiedTime');
    signature = [char(modified.toString()) ':' num2str(double(attributes.get('size')))];
catch ME
    error('FM2D:MissingSectionDatabase', 'Cannot read section database %s: %s', source, ME.message);
end

%% 4. Reload changed data and build exact-name indices
if ~isKey(databases, source) || ~strcmp(databases(source).Signature, signature)
    raw = readDatabase(source, variable);
    names = cellstr(strtrim(string(raw.Name(:))));
    if numel(unique(names)) ~= numel(names)
        error('FM2D:AmbiguousSection', 'Duplicate section names in %s.', source);
    end
    entry = struct('Signature', signature, 'Raw', raw, ...
        'Indices', containers.Map(names, num2cell(1:numel(names))), ...
        'Converted', {{[], []}});
    databases(source) = entry;
else
    entry = databases(source);
end

%% 5. Reuse or compute the requested unit conversion
unitIndex = 1+double(Units == 1);
if isempty(entry.Converted{unitIndex})
    if isBuiltUp
        % Built-up data is already stored in project units.
        entry.Converted{unitIndex} = entry.Raw;
    else
        entry.Converted{unitIndex} = convertDatabase(entry.Raw, Units, startsWith(family, 'HSS'));
    end
    databases(source) = entry;
end

%% 6. Return the database and optional row index
SecData = entry.Converted{unitIndex};
if nargout >= 2
    if ~isKey(entry.Indices, section)
        error('FM2D:UnknownSection', 'Section "%s" was not found in %s.', section, source);
    end
    idx = entry.Indices(section);
end
end

%% Local helper: load and validate the database structure
function data = readDatabase(source, variable)
loaded = load(source, variable);
if ~isfield(loaded, variable) || ~isstruct(loaded.(variable)) || ~isfield(loaded.(variable), 'Name')
    error('FM2D:InvalidSectionDatabase', 'Database %s must contain %s with a Name field.', source, variable);
end
data = loaded.(variable);
end

%% Local helper: preserve the existing unit and weight conventions
function data = convertDatabase(data, Units, isHSS)
% Preserve the existing conversions and weight convention.
if Units == 1
    dimensions = {'d', 'tw', 'bf', 'tf', 'rx', 'ry'};
    for k = 1:numel(dimensions)
        field = dimensions{k};
        data.(field) = data.(field)*25.4;
    end
    data.Area = data.Area*25.4^2;
    cubic = {'Sx', 'Sy', 'Zx', 'Zy'};
    for k = 1:numel(cubic)
        field = cubic{k};
        data.(field) = data.(field)*25.4^3;
    end
    data.Ix = data.Ix*25.4^4;
    data.Iy = data.Iy*25.4^4;
    if ~isHSS
        data.r = data.r*25.4;
        data.J = data.J*25.4^4;
        data.Cw = data.Cw*25.4^6;
    end
    data.W = data.Area*1000*7850/1000^3;
    if isHSS
        data.h = data.h*25.4;
        data.t = data.t*25.4;
    end
else
    data.W = data.Area*12*490/12^3;
end
end
