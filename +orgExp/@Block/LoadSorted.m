function out = LoadSorted(obj,ch)
%% LOADSORTED  Load sorted file for a given channel.
%
%  out = obj.LOADSORTED(ch)
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
%              -> class: [K x 1 manually assigned class labels for
%                               K spikes using CRC]
%              -> tag: [K x 1 manually assigned label tags for K
%                             spikes using CRC]
%
% By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)

%%
if isempty(obj.Sorted.ch)
   error('No Sorted files currently in %s block.',obj.Name);
end

ind = find(abs(obj.Sorted.ch - ch) < eps,1,'first');
out = load(fullfile(obj.Sorted.dir(ind).folder,...
   obj.Sorted.dir(ind).name));
out.ch = ch;
end