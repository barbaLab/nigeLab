function out = LoadClusters(obj,ch)
%% LOADCLUSTERS  Load clusters file for a given channel.
%
%  out = obj.LOADCLUSTERS(ch)
%
%  --------
%   INPUTS
%  --------
%     ch    :  Channel number (scalar)
%
%  --------
%   OUTPUT
%  --------
%     out   :  Data structure with the following fields:
%              -> class: [K x 1 unsupervised class labels for K
%                               spikes from SPC output]
%              -> clu: [# temps x # clust matrix of SPC cluster
%                       assignments for all temperatures used in
%                       SW iterative procedure]
%              -> pars: parameters structure used for SPC
%              -> tree: tree showing how many members each cluster
%                       was assigned for each temperature. Used in
%                       determining which temperature to select
%                       from the SPC procedure.
%
% By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)

%%
if isempty(obj.Clusters.ch)
   error('No Clusters files currently in %s block.',obj.Name);
end

ind = find(abs(obj.Clusters.ch - ch) < eps,1,'first');
out = load(fullfile(obj.Clusters.dir(ind).folder,...
   obj.Clusters.dir(ind).name));
out.ch = ch;
end