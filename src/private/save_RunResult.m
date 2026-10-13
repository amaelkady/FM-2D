function save_RunResult(folder, RunResult)
% Save validated run metadata alongside its ground-motion recorder output.
% The expected results directory must already have been created by the model.

%% 1. Require the result directory before saving metadata
if ~isfolder(folder)
    error('FM2D:MissingResults', 'Expected results folder was not created.');
end
save(fullfile(folder, 'RunResult.mat'), 'RunResult');
end
