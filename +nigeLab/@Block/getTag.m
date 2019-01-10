function [tag,str] = getTag(blockObj,ch)
%% GETTAG     Retrieve list of spike tags for each spike on a channel
%
%  tag = GETTAG(blockObj,ch);
%  tag = GETTAG(blockObj,ch,type);
%  [tag,str] = GETTAG(blockObj,___);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object.
%
%    ch        :     Channel index for retrieving spikes.
%                    -> If not specified, returns a cell array with spike
%                          indices for each channel.
%                    -> Can be given as a vector.
%
%  --------
%   OUTPUT
%  --------
%    tag       :     Vector of spike tag indices (integers)
%                    -> If ch is a vector, returns a cell array of
%                       corresponding tag ID indices
%
%    str       :     Strings corresponding to each unique tag.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE INPUT
if nargin < 2
   ch = 1:blockObj(1).NumChannels;
end

%% USE RECURSION FOR MULTIPLE CHANNELS
if (numel(ch) > 1)
   tag = cell(size(ch));
   str = cell(size(ch));
   for ii = 1:numel(ch)
      [tag{ii},str{ii}] = getSort(blockObj,ch(ii));
   end
   return;
end

%% USE RECURSION FOR MULTIPLE BLOCK OBJECTS
if numel(blockObj) > 1
   tag = [];
   for ii = 1:numel(blockObj)
      tag = [tag; getTag(blockObj(ii),ch)]; %#ok<AGROW>
   end 
   str = blockObj.SortPars.TAG(unique(tag));
   return;
end

%% RETURN VALUES FROM SINGLE BLOCK OBJECT
if isempty(blockObj.SortPars)
   tag = [];
   str = [];
   return;
end
tag = blockObj.Channels(ch).Sorted.tag;

% If it's old format, convert it properly:
if ~isnumeric(tag)
   tag = parseSpikeTagIdx(blockObj,tag);
end

str = blockObj.SortPars.TAG(unique(tag));

end