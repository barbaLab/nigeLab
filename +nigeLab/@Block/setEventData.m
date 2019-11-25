function flag = setEventData(blockObj,fieldName,eventName,propName,value,rowIdx,colIdx)
% SETEVENTDATA  Set 'Event' file data (on disk file)
%
%  blockObj = nigeLab.Block();
%  flag = blockObj.SETEVENTDATA('fieldName','eventName','propName',value);
%  blockObj.SETEVENTDATA('fieldName','eventName','propName',value,rowIdx,);
%  blockObj.SETEVENTDATA('fieldName','eventName','propName',value,rowIdx,colIdx);
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
      flag(i) = blockObj(i).setEventData(fieldName,eventName,propName,value,rowIdx,colIdx);
   end
   return;
end

blockObj.checkCompatibility(fieldName);

%%
% Override colIdx if 'prop' is member of {'type','value','tag','ts'}
eventName_ = {blockObj.Events.(fieldName).name}.';
idx = find(ismember(eventName_,{eventName}),1,'first');
S = substruct('.',propName,'()',{rowIdx, colIdx});

unlockData(blockObj.Events.(fieldName)(idx).data);
blockObj.Events.(fieldName)(idx).data = subsasgn(...
   blockObj.Events.(fieldName)(idx).data,...
   S,...       % substruct (for indexing)
   value);     % values to assign
lockData(blockObj.Events.(fieldName)(idx).data);


end