function postConstructFcn(cluster)
%POSTCONSTRUCTFCN Perform custom configuration after call to PARCLUSTER
%
% POSTCONSTRUCTFCN(CLUSTER) execute code on cluster object CLUSTER.
%
% See also parcluster.

% Copyright 2023 The MathWorks, Inc.

persistent DONE
mlock

if DONE
    % We've already warned to correctly set the AdditionalProperties
    return
else
    % Only want to check once per MATLAB session
    DONE = true;
end

ap = cluster.AdditionalProperties;
profile = upper(split(cluster.Profile));

if isempty(validatedPropValue(ap, 'AccountName', 'char', ''))
    fprintf(['\n\tMust set AccountName before submitting jobs to %s.  E.g.\n\n', ...
             '\t>> c = parcluster;\n', ...
             '\t>> c.AdditionalProperties.AccountName = ''your budget-name'';\n', ...
             '\t>> c.saveProfile\n'], profile{1})
end

if isempty(validatedPropValue(ap, 'WallTime', 'char', ''))
    fprintf(['\n\tMust set WallTime before submitting jobs to %s.  E.g.\n\n', ...
             '\t>> c = parcluster;\n', ...
             '\t>> %% 5 hour, 30 minute walltime\n', ...
             '\t>> c.AdditionalProperties.WallTime = ''05:30:00'';\n', ...
             '\t>> c.saveProfile\n'], profile{1})
end

end
