function out = loadSorted(blockObj,ch)
%% LOADSORTED  Load sorted file for a given channel.
%
%  out = blockObj.LOADSORTED(ch)
%
%  --------
%   INPUTS
%  --------
%     ch    :  Channel number (scalar). If given as an array, out returns
%              an array struct of the same dimension. If not specified,
%              tries to return an array struct containing sort data for all
%              the channels in blockObj.
%
%  --------
%   OUTPUT
%  --------
%     out   :  Data structure with the following fields:
%              -> class: [K x 1 manually assigned class labels for
%                               K spikes using CRC]
%              -> tag: [K x 1 manually assigned label tags for K
%                             spikes using CRC]
%              -> ch: Channel number (scalar)
%              -> flag: False if no files are present.
%
% By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)
%                 v1.1  06/14/2018  Changed to output struct even if no
%                                   files are present, added flag field.
%                                   Added recursion to handle vector input.
%                                   Added exception handling for no channel
%                                   specified.

%% PARSE INPUT
if nargin < 2
   ch = blockObj.Sorted.ch;
   if isempty(ch)
      ch = nan;
   end
end

%% RECURSION IF VECTOR OF CHANNELS IS GIVEN
if numel(ch) > 1
   out = struct('class',cell(size(ch)),...
                'tag',cell(size(ch)),...
                'ch',cell(size(ch)),...
                'flag',cell(size(ch)));
             
   for ii = 1:numel(ch)
      out(ii) = loadSorted(blockObj,ch(ii));
   end 
   
   return;
end

%% CHECK IF SORTED FILE EXISTS
ind = find(abs(blockObj.Sorted.ch - ch) < eps,1,'first');

if isempty(ind)
   warning('No Sorted files currently in %s block.',blockObj.Name);
   out.class = nan;
   out.tag = nan;
   out.ch = ch;
   out.flag = false;
   return;
end

out = load(fullfile(blockObj.Sorted.dir(ind).folder,...
                    blockObj.Sorted.dir(ind).name));
out.ch = ch;
out.flag = true;
end