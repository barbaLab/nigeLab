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

%% CHECK ERRORS
if ~ParseMultiChannelInput(blockObj,ch)
   error('Check ''ch'' input argument.');
end

%% PARSE INPUTS
if nargin < 2
   ch = 1:blockObj.NumChannels;
end

if nargin < 3 % If only 2 arguments or less, class wasn't given
   class = nan;
end

%% USE RECURSION TO ITERATE ON MULTIPLE CHANNELS
idx = [];
if (numel(ch)>1) 
   idx = cell(size(ch));
   for ii = 1:numel(ch)
      idx{ii} = getSpikeTrain(blockObj,ch(ii),class); 
   end   
   return;
end

%% USE RECURSION TO ITERATE ON MULTIPLE BLOCKS
if numel(blockObj) > 1 
   idx = [];
   for ii = 1:numel(blockObj) % Concatenate all block contents together
      idx = [idx; getSpikeTrain(blockObj(ii),ch,class)]; %#ok<AGROW>
   end
   return;
end

%% CHECK THAT THIS BLOCK WAS SORTED AND RETURN SPIKE INDICES
if ~getStatus(blockObj,'Sorted') % If sorting wasn't done, set to NaN
   class = nan;
end

% Find peak occurrence indices and narrow by spike class if desired
idx = find(blockObj.Channels(ch).Spikes.peak_train); % Return vector
if ~isnan(class(1))
   idx = idx(ismember(blockObj.Channels(ch).Sorted.class,class));
end

% Make sure it is shaped in a consistent output dimension
idx = reshape(idx,numel(idx),1);

end