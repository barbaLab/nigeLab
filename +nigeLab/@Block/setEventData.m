function flag = setEventData(blockObj,fieldName,propName,eventName,value,rowIdx,colIdx)
% SETEVENTDATA  Set 'Event' file data (on disk file)
%
%  blockObj = nigeLab.Block();
%  flag = blockObj.SETEVENTDATA('fieldName','propName','eventName',value);
%  blockObj.SETEVENTDATA('fieldName','propName','eventName',value,rowIdx,);
%  blockObj.SETEVENTDATA('fieldName','propName','eventName',value,rowIdx,colIdx);
%
%  Inputs-
%  fieldName : Char array as the name of the "Events" Field
%  eventName : Char array element of 'name' field of Events.(fieldName)
%  propName : Char array as the name of the "Event" DiskData property:
%        --> 'type', 'value', 'tag', 'ts', 'snippet', or 'data'
%  value : Value to assign
%  rowIdx : (Optional) Row indices for value assignment. Default is "all"
%                                                        --> (':')
%  colIdx : (Optional) Columns for value assignment. Default is "all"
%                                                        --> (':')
%
%  Output-
%  flag : Returns true if data was set successfully. Returns false if the
%           file does not exist, for example.

%% Parse input
if nargin < 7
   colIdx = ':';
end

if nargin < 6
   rowIdx = ':';
end

if numel(blockObj) > 1
   flag = false(1,numel(blockObj));
   for i = 1:numel(blockObj)
      flag(i) = blockObj(i).setEventData(fieldName,propName,eventName,value,rowIdx,colIdx);
   end
   return;
end

blockObj.checkCompatibility(fieldName);

%% Check propName
propName = lower(propName);
switch propName % Define some things to make it easier to avoid typo etc
   case {'times','timestamps','t'}
      propName = 'ts';
   case {'index','id','val','clus','clu','cluster','group'}
      propName = 'value';
   case {'snip','snips','waves','wave','waveform','features','feat', ...
         'rate','lfp','aligned','x','meta','metadata'}
      propName = 'snippet';
   case {'mask','label','name'}
      propName = 'tag';
   otherwise
      % do nothing
end

%% Check fields
eventName_ = {blockObj.Events.(fieldName).name}.';
idx = find(ismember(eventName_,{eventName}),1,'first');
if isempty(idx)
   error(['Possible syntax error for input arguments. ' ...
          'No Event Name found: ''%s'''], eventName);
end
S = substruct('.',propName,'()',{rowIdx, colIdx});

unlockData(blockObj.Events.(fieldName)(idx).data);
blockObj.Events.(fieldName)(idx).data = subsasgn(...
   blockObj.Events.(fieldName)(idx).data,...
   S,...       % substruct (for indexing)
   value);     % values to assign
lockData(blockObj.Events.(fieldName)(idx).data);


end