function data = getEventsFromIndexing(obj,iRow,iCol)
%GETEVENTSFROMINDEXING  Return data based on row and column indexing
%
%  data = getEventsFromIndexing(obj,iRow,iCol);
%
%  obj : nigeLab.libs.DiskData object
%  iRow : Indexing into rows (each an event)
%  iCol : Indexing into columns (each col has different data)
%
%  data : Requested data from indexing arguments iRow and iCol
%  --> Typically called from subsref

data = [];
if isempty(iRow) % If no rows requested, then return empty double
   return;
end

if nargin < 3
   iCol = inf; % Returns all
elseif isempty(iCol)
   return; % If no columns requested, then return empty double
end

% Make sure that iRow and iCol are numeric
N = obj.size_(1); % Total number of events

if islogical(iRow)
   iRow = find(iRow);
elseif isinf(iRow)
   iRow = 1:N;
end

if islogical(iCol)
   iCol = find(iCol);
elseif isinf(iCol)
   iCol = 1:obj.size_(2);
end

%% optimized FB 2020/04/01
%     % First step: return full dataset using iCol
%     varname_ = ['/' obj.name_];
%     data = nan(obj.size_(1),numel(iCol));
%     for i = 1:numel(iCol)
%         data(:,i)=h5read(obj.diskfile_,varname_,[1 iCol(i)],[N 1]);
%     end

    
    % step 0. To speed up and avoid calling h5read too many times lets find
    % adjacent chunks of iCol
    iCol = iCol(:);
    clustIdx = find([1;diff(iCol)-1]); % this is the starting index of clusters
    stride = diff(clustIdx(:));
    ColBlocks = [iCol(clustIdx(:)) [stride;numel(iCol)-sum(stride)]];
    
    % First step: return full dataset using iCol
    varname_ = ['/' obj.name_];
    data = nan(obj.size_(1),sum(ColBlocks(:,2)));
    st = 0;
    for i = 1:size(ColBlocks,1)
        data(:,st+1:st+ColBlocks(i,2))=h5read(obj.diskfile_,varname_,[1 ColBlocks(i,1)],[N ColBlocks(i,2)]);
        st = st + ColBlocks(i,2);
    end

% Second step: return reduced subset using iRow
data = data(iRow,:);

end
