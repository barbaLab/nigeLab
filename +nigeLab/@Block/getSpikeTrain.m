function idx = getSpikeTrain(blockObj,ch,clusterIndex)
%% GETSPIKETRAIN  Retrieve list of spike peak sample indices
%
%  idx = GETSPIKETRAIN(blockObj,ch);
%  idx = GETSPIKETRAIN(blockObj,ch,class);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class in orgExp package.
%
%    ch        :     Channel index (positive integer) for retrieving spikes
%                    -> If not specified, returns a cell array with spike
%                          indices for each channel.
%                    -> Can be given as a vector.
%
% clusterIndex :     (Optional) Specify the cluster of spikes to retrieve,
%                       based on sorting or clustering. If not specified,
%                       gets all spikes on channel. Otherwise, it will
%                       check to make sure that there are actually classes
%                       associated with the spike and issue a warning if
%                       that part hasn't been done yet.
%                       -> Can be given as a vector.
%                       -> Non-negative integer.
%
%  --------
%   OUTPUT
%  --------
%     idx      :     Vector of spike peak sample indices (integer).
%                    -> If ch is a vector, returns a cell array of
%                       corresponding spike sample times.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% CHECK ERRORS
if ~ParseMultiChannelInput(blockObj,ch)
   error('Check ''ch'' input argument.');
end

%% PARSE INPUTS
if nargin < 2
   ch = 1:blockObj(1).NumChannels;
end

if nargin < 3 % If only 2 arguments or less, class wasn't given
   clusterIndex = nan;
end

%% USE RECURSION TO ITERATE ON MULTIPLE CHANNELS
idx = [];
if (numel(ch) > 1) 
   idx = cell(size(ch));
   if numel(clusterIndex)==1
      clusterIndex = repmat(clusterIndex,1,numel(ch));
   elseif numel(clusterIndex) ~= numel(ch)
      error('Clusters (%d) must match number of channels (%d).');
   end
   for ii = 1:numel(ch)
      idx{ii} = getSpikeTrain(blockObj,ch(ii),clusterIndex(ii)); 
   end   
   return;
end

%% USE RECURSION TO ITERATE ON MULTIPLE BLOCKS
if numel(blockObj) > 1 
   idx = [];
   for ii = 1:numel(blockObj) % Concatenate all block contents together
      idx = [idx; getSpikeTrain(blockObj(ii),ch,clusterIndex)]; %#ok<AGROW>
   end
   return;
end

%% CHECK THAT THIS BLOCK WAS SORTED AND RETURN SPIKE INDICES
% Find peak occurrence indices and narrow by spike class if desired
if isnan(clusterIndex(1))
   idx = getEventData(blockObj,'Spikes','value',ch);
else
   idx = getEventData(blockObj,'Spikes','value',ch,'tag',clusterIndex);
end


end