function [flag,idx] = setEventData(blockObj,fieldName,propName,eventName,value,rowIdx,colIdx)
%SETEVENTDATA  Set 'Event' file data (on disk file)
%
%  blockObj = nigeLab.Block();
%  flag = blockObj.SETEVENTDATA('fieldName','propName','eventName',value);
%  blockObj.SETEVENTDATA('fieldName','propName','eventName',value,rowIdx,);
%  blockObj.SETEVENTDATA('fieldName','propName','eventName',value,rowIdx,colIdx);
%
%  Inputs-
%  fieldName : Char array as the name of the "Events" Field. If specified
%              as empty array ([]), defaults to 
%              blockObj.Pars.Video.ScoringEventFieldName
%  propName : Char array as the name of the "Event" DiskData property:
%        --> 'type', 'value', 'tag', 'ts', 'snippet', or 'data'
%  eventName : Char array element of 'name' field of Events.(fieldName)
%  value : Value to assign
%  rowIdx : (Optional) Row indices for value assignment. Default is "all"
%                                                        --> (':')
%  colIdx : (Optional) Columns for value assignment. Default is "all"
%                                                        --> (':')
%
%  Output-
%  flag : Returns true if data was set successfully. Returns false if the
%           file does not exist, for example.
%  idx  : Events field struct array index (corresponds to eventName)

% Parse input
if nargin < 7
   colIdx = ':';
end

if nargin < 6
   rowIdx = ':';
end

if isempty(fieldName)
   fieldName = blockObj.ScoringField;
end

if numel(blockObj) > 1
   flag = false(1,numel(blockObj));
   for i = 1:numel(blockObj)
      flag(i) = setEventData(blockObj(i),fieldName,propName,eventName,value,rowIdx,colIdx);
   end
   return;
else
   flag = false;
end

checkCompatibility(blockObj,fieldName);

% Check propName
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

% Check fields
[idx,tmpName] = getEventsIndex(blockObj,fieldName,eventName);
if ~strcmp(tmpName,fieldName)
   warning(['nigeLab:' mfilename ':NameConflict'],...
      'Possible fieldName mismatch: requested "%s" but matched "%s"\n',...
      fieldName,tmpName);
   fieldName = tmpName;
end
if isnan(idx)
   error(['nigeLab:' mfilename ':BadEvent'],...
      ['Possible syntax error for input arguments. ' ...
          'No Event Name found: ''%s''\n'...
          '\t->\t(.Events Field: %s)\n'], eventName,fieldName);
end
S = substruct('.',propName,'()',{rowIdx, colIdx});

class_ = strrep(class(blockObj.Events.(fieldName)(idx).data),'DiskData.','');
if ~strcmp(class_,class(value))
   if blockObj.Verbose
      warning(['nigeLab:' mfilename ':BadClass'],...
         ['\t\t->\t[BLOCK/SETEVENTDATA]: Type mismatch! (Assigned data is ' ...
         '<strong>%s</strong> but should be <strong>%s</strong>)\n' ...
         '\t\t\t->\t(Data typecast as correct match, but should fix code)\n'],...
         class(value),class_);
   end
   value = cast(value,class_);
end

if ~isempty(blockObj.Events.(fieldName)(idx).data)
   unlockData(blockObj.Events.(fieldName)(idx).data);
end
blockObj.Events.(fieldName)(idx).data = subsasgn(...
   blockObj.Events.(fieldName)(idx).data,...
   S,...       % substruct (for indexing)
   value);     % values to assign
flag = true;
end