function ts = binaryStream2ts(stream,fs,threshold,transition_type,debounce)
% BINARYSTREAM2TS  Returns list of transition times for a signal
%
%  ts = nigeLab.utils.binaryStream2ts(stream);
%  --> Returns ts as sample indices. 
%     * Note: `ts` is always returned as a column vector
%     * Note: if no event times are detected, `ts` returns as empty double
%
%  ts = nigeLab.utils.binaryStream2ts(stream,fs);
%  --> Converts ts based on sample rate of stream (fs)
%  --> If fs is empty, returns sample indices instead.
%
%  ts = nigeLab.utils.binaryStream2ts(stream,fs,threshold);
%  --> Sets threshold value
%      * Stream is binarized as follows:
%        + stream >  threshold -> 1
%        + stream <= threshold -> 0
%  --> Default value is set in nigeLab.defaults.Event (if empty)
%  
%  ts = nigeLab.utils.binaryStream2ts(stream,fs,threshold,transition_type);
%  --> Sets transition type: must be 'All', 'Rising', or 'Falling'.
%      'Rising' limits to transitions from LOW to HIGH, while 'Falling'
%      limits to transitions from HIGH to LOW.
%  --> Default value is set in nigeLab.defaults.Event (if empty)
%
%  ts = nigeLab.utils.binaryStream2ts(stream,fs,...,debounce);
%  --> Sets debounce period (seconds)
%  --> Default value is set in nigeLab.defaults.Event (if empty)
%
%  `stream` should be a row vector, or a `nigeLab.libs.nigelStream` object
%
%  If stream is given as a matrix, then rows are treated as individual
%  streams. For each row of stream, a cell array of ts is returned.

% Handle inputs
if nargin < 5
   debounce = [];
end

if nargin < 4
   transition_type = 'Both';
elseif isempty(transition_type)
   transition_type = 'Both';
end

if nargin < 3
   threshold = [];
end

if ~isa(stream,'nigeLab.libs.nigelStream')
   if nargin < 2
      fs = [];
   end

   % If multiple streams, iterate on rows
   if size(stream,1) > 1
      ts = cell(1,size(stream,1));
      for i = 1:size(stream,1)
         ts{i} = nigeLab.utils.binaryStream2ts(stream(i,:),fs,...
            threshold,transition_type,debounce);
      end
      return;
   end
else
   if numel(stream) > 1
      ts = cell(1,numel(stream));
      for i = 1:numel(stream)
         ts{i} = nigeLab.utils.binaryStream2ts(stream(i).data,stream(i).fs,...
            threshold,transition_type,debounce);
      end
      return;
   else
      fs = stream.fs;
      stream = stream.data;
   end
end
if isempty(threshold)
   threshold = std(stream) * 2;
end
x = stream > threshold;
x = reshape(x,1,numel(stream)); % Make sure it's a row vector

switch lower(transition_type)
   % First sample is always "false" because don't know previous
   case {'rise','rising'}
      ts = [false, (diff(x) > 0)];
      
   case {'fall','falling'}
      ts = [false, (diff(x) < 0)];
      
   case {'all','any'}
      ts = [false, ((diff(x) < 0) | (diff(x) > 0))];
      
   otherwise
      error('Invalid transition_type: %s',transition_type);
end
ts = find(ts);                % Get actal sample indices
ts = reshape(ts,numel(ts),1); % Get proper orientation

if ~isempty(fs)
   ts = ts./fs; % Return time in seconds
   ts = nigeLab.utils.debouncePointProcess(ts,debounce);  
   return;
else
   % Does nothing if debounce is empty
   ts = nigeLab.utils.debouncePointProcess(ts,debounce);  
   return;
end


end