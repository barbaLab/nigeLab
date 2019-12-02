function stream = getStream(blockObj,streamName)
% GETSTREAM  Returns stream struct field corresponding to streamName
%
%  stream = blockObj.getStream('streamName'); 
%
%  streamName  :  Char array e.g. 'Paw' or 'Beam' etc. that is the name of
%                    some Stream.

if nargin < 2
   error('Must supply two arguments.');
end

if ~iscell(streamName)
   streamName = {streamName};
end

if numel(blockObj) > 1
   stream = cell(size(blockObj));
   for i = 1:numel(blockObj)
      stream{i} = blockObj(i).getStream(streamName);
   end
   return;
end

if numel(streamName) > 1
   stream = [];
   for i = 1:numel(streamName)
      stream = [stream; blockObj.getStream(streamName(i))];
   end
   return;
end

% Make 3 lists: 
%  name -- list of all streams names from all fields of block.Streams
%  idx  -- Matched indexing from name into fieldnames of Streams
%  streamIdx  --  Matched indexing from name into corresponding array
%                 element of that fieldtype in Streams
f = fieldnames(blockObj.Streams);
name = [];
idx = [];
streamIdx = [];
for iF = 1:numel(f)
   fn = {blockObj.Streams.(f{iF}).name}.';
   idx = [idx; ones(numel(fn),1)*iF];
   streamIdx = [streamIdx; (1:numel(fn)).'];
   name = [name; fn]; %#ok<*AGROW>
end

% Match the name. Handle cases where zero or more than one name are
% matched.
iStream = ismember(name,streamName);
if sum(iStream) < 1
   stream = [];
   fprintf(1,'No stream named %s in %s\n',streamName{1},blockObj.Name);
elseif sum(iStream) > 1
   error('Multiple streams with the same name.');
else
   stream_ = blockObj.Streams.(f{idx(iStream)})(streamIdx(iStream));
end
stream = nigeLab.utils.initChannelStruct('substream',stream_);

end