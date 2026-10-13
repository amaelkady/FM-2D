function idx = get_Section_Index(SecData, Section)
% Find exactly one trimmed section name in an already loaded database.
% Unknown or duplicate names raise errors rather than selecting an arbitrary row.
% Exact lookup for a database buffer already held by a caller.

%% 1. Match the complete section name
matches = find(strcmp(strtrim(string(SecData.Name)), strtrim(string(Section))));

%% 2. Reject missing or ambiguous matches
if isempty(matches)
    error('FM2D:UnknownSection', 'Section "%s" was not found in the section database.', Section);
elseif numel(matches) > 1
    error('FM2D:AmbiguousSection', 'Section "%s" appears more than once in the section database.', Section);
end
idx = matches;
end
