function idx = getSpikeTrain(blockObj,ch,class)
%% GETSPIKETRAIN  Retrieve list of spike peak sample indices
%
%  ts = GETSPIKETRAIN(blockObj,ch);
%  ts = GETSPIKETRAIN(blockObj,ch,class);
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

if nargin < 3
   class = nan;
elseif ~ismember('Sorted',blockObj.Fields(blockObj.Status))
   class = nan;
end

if any(ch < 1)
   error('Channel arg must be a positive integer (not %d).',ch);
end

if any(ch > blockObj.NumChannels)
   error('Channel arg must be <= %d (total # channels). Was %d.',...
      blockObj.NumChannels,ch);
end

%% FIND SPIKE SAMPLE INDICES
if numel(ch) > 1 % For an array of channels
   idx = cell(numel(ch),1);
   for ii = 1:numel(ch) % Return a cell array
      idx{ii} = find(blockObj.Channels(ch(ii)).Spikes.peak_train);
      if ~isnan(class(1))
         idx{ii} = idx{ii}(ismember(class,...
            blockObj.Channels(ch(ii)).Sorted.class));
      end
   end
   
else % Otherwise, only one channel index was given
   idx = find(blockObj.Channels(ch).Spikes.peak_train); % Return vector
   if ~isnan(class(1))
      idx = idx(ismember(class,blockObj.Channels(ch).Sorted.class));
   end
end

end