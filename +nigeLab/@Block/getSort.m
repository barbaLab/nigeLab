function class = getSort(blockObj,ch)
%% GETSORT     Retrieve list of spike class indices for each spike
%
%  class = GETSORT(blockObj,ch);
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
%    class     :     Vector of spike classes (integers)
%                    -> If ch is a vector, returns a cell array of
%                       corresponding spike classes.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE INPUT
if nargin < 2
   ch = 1:blockObj(1).NumChannels;
end

%% USE RECURSION TO ITERATE ON MULTIPLE CHANNELS
if (numel(ch) > 1)
   class = cell(size(ch));
   for ii = 1:numel(ch)
      class{ii} = getSort(blockObj,ch(ii));
   end
   return;
end

%% USE RECURSION TO ITERATE ON MULTIPLE BLOCKS
if (numel(blockObj) > 1)
   class = [];
   for ii = 1:numel(blockObj)
      class = [class; getSort(blockObj,ch(ii))]; %#ok<AGROW>
   end 
   return;
end

%% CHECK TO BE SURE THAT THIS BLOCK/CHANNEL HAS BEEN SORTED
if isfield(blockObj.Channels,'Sorted')
   class = blockObj.Channels(ch).Sorted.class;
else
   class = [];
end

end