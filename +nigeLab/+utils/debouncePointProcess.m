function ts = debouncePointProcess(ts,debounce)
% DEBOUNCEPOINTPROCESS  Remove point process events that are too close
%                       together and return reduced set (list) of times.
%
%  ts = nigeLab.utils.debouncePointProcess(ts,debounce);
%
%  ts  --  List of times or sample indices
%  debounce  --  Debounce threshold, in units that correspond to ts.

%Handle input
if nargin < 2
   error('Must supply two inputs');
end

if isempty(debounce) || isnan(debounce)
   % Do nothing
   return;
end

if isinf(debounce)
   if ~isempty(ts)
      ts = ts(1); % Remove all times except first
   end
   return;
end

%Use loop to iteratively remove ts based on time differences
ts = sort(ts,'ascend');
ts = reshape(ts,numel(ts),1); % Get fixed orientation
idx = 1;
while (idx < numel(ts))
   if (ts(idx+1)-ts(idx)) < debounce
      ts(idx+1) = [];
   else
      idx = idx + 1;
   end
end

end