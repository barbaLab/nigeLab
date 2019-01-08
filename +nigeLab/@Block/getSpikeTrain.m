function idx = getSpikeTrain(blockObj,ch,class)
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
%   class      :     (Optional) Specify the class of spikes to retrieve,
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

%% PARSE INPUTS
if nargin < 2
   ch = 1:blockObj.NumChannels;
end

if nargin < 3 % If only 2 arguments or less, class wasn't given
   class = nan;
elseif ~getStatus(blockObj,'Sorted') % If sorting wasn't done, set to NaN
   class = nan;
end

% If class is not specified, but Sorting and Clustering was done...
if isnan(class(1)) && ...
      getStatus(blockObj,'Sorted') && ...
      getStatus(blockObj,'Clusters') && ...
      isfield(blockObj.SortPars,'SPIKETAGS')
   % Make class equal to all "good" spike classes
   class = find(blockObj.SortPars.SPIKETAGS);
end

if ~ParseMultiChannelInput(blockObj,ch)
   error('Check ''ch'' input argument.');
end

%% FIND SPIKE SAMPLE INDICES
if numel(ch) > 1 % For an array of channels
   idx = cell(size(ch));
   for ii = 1:numel(ch) % Return a cell array
      idx{ii} = find(blockObj.Channels(ch(ii)).Spikes.peak_train);
      if ~isnan(class(1))
         idx{ii} = idx{ii}(...
            ismember(blockObj.Channels(ch(ii)).Sorted.class,class));
      end
   end
   
else % Otherwise, only one channel index was given
   idx = find(blockObj.Channels(ch).Spikes.peak_train); % Return vector
   if ~isnan(class(1))
      idx = idx(ismember(blockObj.Channels(ch).Sorted.class,class));
   end
end

idx = reshape(idx,numel(idx),1);

end