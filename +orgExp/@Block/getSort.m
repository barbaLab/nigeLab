function class = getSort(blockObj,ch)
%% GETSORT     Retrieve list of spike class indices for each spike
%
%  ts = GETSORT(blockObj,ch);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class in orgExp package.
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
   ch = 1:blockObj.NumChannels;
end

if ~ismember('Sorted',blockObj.Fields(blockObj.Status))
   class = nan;
   return;
end

%% GET SPIKE PEAK SAMPLES AND CONVERT TO TIMES
if numel(ch) > 1
   class = cell(size(ch));
   for ii = 1:numel(ch)
      class{ii} = blockObj.Channels(ch(ii)).Sorted.class;
   end 
else
   class = blockObj.Channels(ch).Sorted.class;
end


end