function setStreamsFromIndexing(obj,idx,data)
%SETSTREAMSFROMINDEXING  Return data based on indexing
%
%  setStreamsFromIndexing(obj,idx,data);
%
%  obj : nigeLab.libs.DiskData object
%  idx : Indexing vector (numeric)
%  data : Data to write to diskfile

if nargin < 2
   idx = inf;
elseif isempty(idx) % If no rows requested, then return empty double
   return;
elseif islogical(idx)
   idx = find(idx);
end

% Make sure that idx and iCol are numeric
N = obj.size_(2); % Length
if isinf(idx)
   idx = 1:N;
end

% First step: make a list of "chunks" to read
starts = idx([true, diff(idx) > 1]); % All "starts" of included indices
stops = idx([diff(idx) > 1, true]);  % All "stops" of runs of consecutive
counts = stops - starts + 1;         % Lengths of each "run"

% Second step: read out data in "chunks"
varname_ = ['/' obj.name_];
iCur = 1;
for i = 1:numel(starts)
   cur = iCur:(iCur+counts(i)-1);
   iCur = cur(end)+1;
   h5write(obj.diskfile_,varname_,data(1,cur),[1 starts(i)],[1 counts(i)]);
end

end
