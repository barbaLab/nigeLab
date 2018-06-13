function out = LoadSpikes(obj,ch)
%% LOADSPIKES  Load spikes file for a given channel.
%
%  out = obj.LOADSPIKES(ch)
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
%              -> artifact: [1 x # artifact samples double]
%              -> features: [K x # features matrix for K spikes]
%              -> pars: parameters structure for spike detection
%              -> peak_train: [N x 1 sparse vector of spike peaks]
%              -> pp: [K x 1 double vector of peak prominences]
%              -> pw: [K x 1 double vector of peak widths]
%              -> spikes: [K x M matrix of spike snippets for M
%                          samples per snippet.]
%
% By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)

%%
if isempty(obj.Spikes.ch)
   error('No Spikes files currently in %s block.',obj.Name);
end

ind = find(abs(obj.Spikes.ch - ch) < eps,1,'first');
out = load(fullfile(obj.Spikes.dir(ind).folder,...
   obj.Spikes.dir(ind).name));
out.ch = ch;
end