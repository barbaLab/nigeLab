function out = loadSpikes(blockObj,ch)
%% LOADSPIKES  Load spikes file for a given channel.
%
%  out = blockObj.LOADSPIKES(ch)
%
%  --------
%   INPUTS
%  --------
%     ch    :  Channel number (scalar). If specified as a vector, out
%              returns a struct array of the same dimension. If not given,
%              tries to return an array struct containing spikes for all
%              the channels in blockObj.
%
%  --------
%   OUTPUT
%  --------
%     out   :  Data structure with the following fields:
%              -> artifact: [1 x # artifact samples double]
%              -> features: [K x # features matrix for K spikes]
%              -> pars: parameters structure for spike detection
%              -> peak_train: [N x 1 sparse vector of spike peaks]
%              -> pp: [K x 1 double vector of peak prominences]
%              -> pw: [K x 1 double vector of peak widths]
%              -> spikes: [K x M matrix of spike snippets for M
%                          samples per snippet.]
%              -> ch: Channel number
%              -> flag: False if no file is found.
%
% By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)
%                 v1.1  06/14/2018  Added flag to struct and made it return
%                                   out even if no files are there, just
%                                   with a false flag. Added recursion for
%                                   vector channel input. Added exception
%                                   handling for no channel specified.

%% PARSE INPUT
if nargin < 2
   ch = blockObj.Spikes.ch;
   if isempty(ch)
      ch = nan;
   end
end

%% USE RECURSION FOR VECTOR CHANNEL INPUT
if numel(ch) > 1
   out = struct('artifact',cell(size(ch)),...
                'features',cell(size(ch)),...
                'pars',cell(size(ch)),...
                'peak_train',cell(size(ch)),...
                'pp',cell(size(ch)),...
                'pw',cell(size(ch)),...
                'spikes',cell(size(ch)),...
                'ch',cell(size(ch)),...
                'flag',cell(size(ch)));
             
   for ii = 1:numel(ch)
      out(ii) = loadSpikes(blockObj,ch(ii));
   end 
   
   return;
end

%% CHECK IF FILE EXISTS
ind = find(abs(blockObj.Spikes.ch - ch) < eps,1,'first');
if isempty(ind)
   warning('No Spikes files currently in %s block.',blockObj.Name);
   out.artifact = nan;
   out.features = nan;
   out.pars = struct('fs',nan);
   out.peak_train = nan;
   out.pp = nan;
   out.pw = nan;
   out.spikes = nan;
   out.ch = ch;
   out.flag = false;
   return;
end

%% LOAD SPIKE DATA
out = load(fullfile(blockObj.Spikes.dir(ind).folder,...
                    blockObj.Spikes.dir(ind).name));
out.ch = ch;
out.flag = true;
end