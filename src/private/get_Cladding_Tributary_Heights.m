function height = get_Cladding_Tributary_Heights(HStory)
% Return a column of cladding tributary heights for elevated floors.
% Each interior floor receives half the adjacent story heights; the roof
% receives half the top story. The lower half of story 1 belongs to ground.

% Cladding tributary heights for elevated floors, indexed by story below.
% Floors 2:NStory use half the stories below and above; the roof uses half
% the top story. The lower half of story 1 remains assigned to the ground,
% consistent with the application's existing elevated-floor convention.

%% 1. Validate positive story heights and normalize their orientation
validateattributes(HStory, {'numeric'}, {'real', 'finite', 'vector', 'nonempty', 'positive'});

HStory = double(HStory(:));

%% 2. Assign the roof share and adjacent-story shares
height = 0.5*HStory;

if numel(HStory) > 1
    height(1:end-1) = 0.5*(HStory(1:end-1)+HStory(2:end));
end

end
