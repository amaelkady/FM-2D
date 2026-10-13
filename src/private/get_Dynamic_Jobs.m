function Jobs = get_Dynamic_Jobs(config)
% Enumerate GM/realization pairs in summary order, with stable sampling seeds.
nReal = 1;
if config.Uncertainty
    nReal = config.nRealizations;
end
validateattributes(nReal, {'numeric'}, {'scalar','integer','positive','finite'});
validateattributes(config.GM_Start, {'numeric'}, {'scalar','integer','positive','finite'});
validateattributes(config.GM_Last, {'numeric'}, {'scalar','integer','>=',config.GM_Start,'finite'});
[~, base] = fileparts(config.OpenSEESFileName);
Jobs = repmat(struct('GM_No',0,'Ri',0,'Seed',[],'SF',0, ...
    'ModelFile','','MotionFile','','ResultFolder',''), ...
    (config.GM_Last-config.GM_Start+1)*nReal, 1);
k = 0;
for GM_No = config.GM_Start:config.GM_Last
    for Ri = 1:nReal
        k = k+1;
        suffix = sprintf('_%d', GM_No);
        if config.Uncertainty
            suffix = sprintf('_%d_%d', GM_No, Ri);
            pair = (GM_No+Ri-2)*(GM_No+Ri-1)/2+Ri;
            Jobs(k).Seed = 1+mod(104729*pair, 2147483646);
        end
        name = config.GM.name{GM_No};
        if config.Parallel || config.Uncertainty
            name = sprintf('%s_%d', name, Ri);
        end
        SF = config.SF;
        if config.Dynamic_TargetSA
            SF = config.TargetSA/config.GM.sa{GM_No};
        end
        validateattributes(SF, {'numeric'}, {'scalar','real','finite','nonnegative'});
        Jobs(k).GM_No = GM_No;
        Jobs(k).Ri = Ri;
        Jobs(k).SF = SF;
        Jobs(k).ModelFile = fullfile(config.MainDirectory, [base suffix '.tcl']);
        Jobs(k).MotionFile = fullfile(config.MainDirectory, sprintf('GM_%d_%d.txt', GM_No, Ri));
        Jobs(k).ResultFolder = fullfile(config.RFpath, 'Results', name);
    end
end
if numel(unique(lower(string({Jobs.ResultFolder})))) ~= numel(Jobs) || ...
        (config.Uncertainty && numel(unique([Jobs.Seed])) ~= numel(Jobs))
    error('FM2D:DuplicateJobs','Parallel jobs must have unique result folders and seeds.');
end
end
