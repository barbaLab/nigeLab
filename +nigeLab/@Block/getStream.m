function stream = getStream(blockObj,streamName,source,scaleOpts)
% GETSTREAM  Returns stream struct field corresponding to streamName
%
%  stream = blockObj.getStream('streamName'); 
%
%  streamName  :  Char array e.g. 'Paw' or 'Beam' etc. that is the name of
%                    some Stream.
%
%  source      :  (Optional) -- If it's a Video, specify the camera angle
%                          (source); e.g. 'Front' etc.
%
%  scaleOpts   :  (Optional) -- Struct with fields:
%                          --> 'do_scale'  (set false to skip scaling)
%                          --> 'range'     ('normalized' or 'fixed_scale')
%                          --> 'fixed_min' (fixed/known min. value)
%                          --> 'fixed_range' (only used if range is
%                                               'fixed_scale'; flat value
%                                               that range should be scaled
%                                               to). 

if nargin < 2
   error('Must supply at least two arguments.');
end

if ~iscell(streamName)
   streamName = {streamName};
end

if nargin < 4
   scaleOpts = nigeLab.utils.initScaleOpts();
elseif isempty(scaleOpts)
   scaleOpts = nigeLab.utils.initScaleOpts();
elseif ~isstruct(scaleOpts)
   scaleOpts = nigeLab.utils.initScaleOpts();
end

if nargin < 3
   source = [];
end

if numel(blockObj) > 1
   stream = cell(size(blockObj));
   for i = 1:numel(blockObj)
      stream{i} = blockObj(i).getStream(streamName,source);
   end
   return;
end

if numel(streamName) > 1
   stream = [];
   for i = 1:numel(streamName)
      stream = [stream; blockObj.getStream(streamName(i),source)];
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
if sum(iStream) < 1 % No stream in blockObj.Streams; check blockObj.Videos
   stream_ = [];
elseif sum(iStream) > 1
   error('Multiple streams with the same name.');
else
   stream_ = blockObj.Streams.(f{idx(iStream)})(streamIdx(iStream));
end

if isempty(stream_) && ~isempty(source)
   stream = getStream(blockObj.Videos,streamName{1},source,scaleOpts);
elseif ~isempty(stream_)
   if isempty(stream_.data)
      stream = [];
      return;
   end
   stream_.data = double(stream_.data.data);
   % Return stream in standardized "substream" format
   stream = nigeLab.utils.initChannelStruct('substream',stream_);
   stream.data = nigeLab.utils.applyScaleOpts(stream.data,scaleOpts);
   stream.t = (0:(numel(stream.data)-1))/stream.fs;
   
else
   stream = []; % Return empty stream because can't find anything
   fprintf(1,'No stream named %s in %s\n',streamName{1},blockObj.Name);
end

   

   

end