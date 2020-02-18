function setEventsFromIndexing(obj,iRow,iCol,data)
%SETEVENTSFROMINDEXING  Return data based on row and column indexing
%
%  setEventsFromIndexing(obj,iRow,iCol,data);
%
%  obj : nigeLab.libs.DiskData object
%  iRow : Indexing into rows (each an event)
%  iCol : Indexing into columns (each col has different data)
%  data : Data to assign using indexing arguments iRow and iCol
%
%  --> Typically called from subsasgn

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

if isscalar(data)
   data = repmat(data,numel(iRow),numel(iCol));
end

% Do the H5 assignment
varname_ = ['/' obj.name_];

% Iterate on columns, reading in the full column and then overwriting the
% relevant rows. There should in general be many fewer Columns than rows,
% unless the number of rows is so small that it becomes a trivial tradeoff
for i = 1:numel(iCol)
   a = h5read(obj.diskfile_,varname_,[1 iCol(i)],[N 1]);
   assigned_data = data(:,i);
   a(iRow,1) = assigned_data;
   h5write(obj.diskfile_,varname_,a,[1 iCol(i)],[N 1]);
end



end
