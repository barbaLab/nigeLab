function [ts,b,tFinal] = getRC_ts(block)
%% GETRC_TS    Function to get epochs around grasps for SD (new version)
%
% By: Max Murphy  v1.0   09/04/2018    Original version (R2017b)

%%
try
   b = fullfile(block.folder,block.name);
   load(fullfile(b,[block.name '_Digital',],[block.name '_Scoring.mat']));
   info = load(fullfile(b,[block.name '_EpocSnipInfo.mat']),'block');
   tFinal = CPL_time2sec(info.block.info.duration);
catch
   fprintf(1,'\n\tBlock: %s not loaded.\n',block.name);
   ts = nan;
   b = nan;
   return
end

% This part just tries to remove epochs that are not around behavior of
% interest; this way spike detection and more importantly CLUSTERING is
% only done on the spikes of interest:
ts = [behaviorData.Grasp; ...
           behaviorData.Reach; ...
           behaviorData.Support];
        
% Remove invalid times
ts(isnan(ts)) = [];
ts(isinf(ts)) = [];

ts = sort(ts,'ascend');


end
