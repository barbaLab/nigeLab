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
%                       corresponding spike classes.
%
%    str       :     Strings corresponding to each unique tag.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE INPUT
if nargin < 2
   ch = 1:blockObj.NumChannels;
end

% Use recursion if array of blockObj is given
if (numel(blockObj)>1)
   [tag,str] = getTag(blockObj(1),ch);
   for ii = 2:numel(blockObj)
      tag = [tag; getSort(blockObj(ii),ch)]; %#ok<AGROW>
   end
   return;
end
   
if isempty(blockObj,'SortPars')
   tag = [];
   str = [];
   return;
end

%% GET SPIKE PEAK SAMPLES AND CONVERT TO TIMES
if numel(ch) > 1
   tag = cell(size(ch));
   str = [];
   for ii = 1:numel(ch)
      [tag{ii},tmp] = getTag(blockObj,ch(ii));
      str = unique(str,tmp);
   end 
else
   tag = blockObj.Channels(ch).Sorted.tag;
   str = blockObj.SortPars.TAG(unique(tag));
end


end