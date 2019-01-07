function out = loadClusters(blockObj,ch)
%% LOADCLUSTERS  Load clusters file for a given channel.
%
%  out = blockObj.LOADCLUSTERS(ch)
%
%  --------
%   INPUTS
%  --------
%     ch    :  Channel number (scalar). If specified as a vector, out is
%              returned as a struct the size of ch. If not specified,
%              tries to return an array struct containing clusters for all
%              the channels in blockObj.
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
%              -> ch:   Channel number.
%              -> flag: True, if cluster files are present; otherwise,
%                       false.
%
% By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)
%                 v1.1  06/14/2018  Now returns a struct even if no file
%                                   is present. Added recursion to handle
%                                   vector inputs of ch. Added exception
%                                   handling for no channel specified.

%% PARSE INPUT
if nargin < 2
   ch = blockObj.Clusters.ch;
   if isempty(ch)
      ch = nan;
   end
end

%% USE RECURSION FOR VECTOR INPUT
if numel(ch) > 1
   out = struct('class',cell(size(ch)),...
                'clu',cell(size(ch)),...
                'pars',cell(size(ch)),...
                'tree',cell(size(ch)),...
                'ch',cell(size(ch)),...
                'flag',cell(size(ch)));
             
   for ii = 1:numel(ch)
      out(ii) = loadClusters(blockObj,ch(ii));
   end 
   
   return;
end

%% CHECK IF CLUSTERS FILE EXISTS
ind = find(abs(blockObj.Clusters.ch - ch) < eps,1,'first');
if isempty(blockObj.Clusters.ch)
   warning('No Clusters files currently in %s block.',blockObj.Name);
   out.class = nan;
   out.clu = nan;
   out.pars = struct('fs',nan);
   out.tree = nan;
   out.ch = ch;
   out.flag = false;
   return;
end

%% OTHERWISE, LOAD DATA AND SET FLAG TO TRUE
out = load(fullfile(blockObj.Clusters.dir(ind).folder,...
   blockObj.Clusters.dir(ind).name));
out.ch = ch;
out.flag = true;

end