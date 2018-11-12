function [ts,b,tFinal] = getRC_grasp_sf(block)
%% GETRC_GRASP_SF    Function to get epochs around grasps for SD (from old video scoring)
%
% By: Max Murphy  v1.0   09/04/2018    Original version (R2017b)

%%
try
   load(fullfile('C:\MyRepos\_M\180212 RC LFADS Multiunit\aligned',...
      [block.name '_aligned.mat']),'grasp');
   b = fullfile(block.folder,block.name);
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
ts = sort([grasp.s, grasp.f],'ascend');


end
