function eventData = getStreamsEventData(blockObj,field,prop,eventName,matchProp,matchValue)
%GETCHANNELSEVENTDATA  Returns the event data for a 'Streams' Event
%
%  eventData =
%  blockObj.getStreamsEventData(field,prop,eventName,matchProp,matchValue);
%
%  Should be called from blockObj.getEventData.


propName = lower(prop);
switch propName % Define some things to make it easier to avoid typo etc
   case {'times','timestamps','t','ts'}
      propName = 'ts';
   case {'index','id','val','group','value'}
      propName = 'value';
   case {'snip','snips','rate','lfp','aligned','x','snippet'}
      propName = 'snippet';
   case {'mask','label','name','tag'}
      propName = 'tag';
   otherwise
      % do nothing
end


idx = getEventsIndex(blockObj,field,eventName);

% Note that .data is STRUCT field; .data.data would be DiskData "data"
eventData = [];
if isfield(blockObj.Events,field)
   if numel(blockObj.Events.(field)) >= idx
      if isfield(blockObj.Events.(field)(idx),'data')
         % Do not need to check if it is .DiskData due to validator
         if size(blockObj.Events.(field)(idx).data,2)>=5 % Then it exists and has been initialized correctly
            tmp = blockObj.Events.(field)(idx).data;
            eventData = tmp.(propName);
         else
            warning(['nigeLab:' mfilename ':BadInit'],...
               ['DiskData for Events.%s(%g) exists, but is ' ...
               'not initialized correctly (too small -- ' ...
               'only %g columns).'],field,idx,...
               size(blockObj.Events.(field)(idx).data,2));
            return;
         end
      else
         warning(['nigeLab:' mfilename ':BadField'],...
            '''data'' is not a field of Events.%s(%g) yet.',...
            field,idx);
         return;
      end
   else
      warning(['nigeLab:' mfilename 'BadIndex'],...
         'Events.%s(%g) exceeds array dimensions.',field,idx);
      return;
   end
else
   warning(['nigeLab:' mfilename ':BadField'],...
      '%s is not a field of Block.Events.',field);
   return;
end

% If a value to match is given, then
if ~isnan(matchValue(1))
   dataSelector = tmp.(matchProp);
   if strcmpi(matchProp,'ts')
      eventData = eventData(...
         (dataSelector >= matchValue(1)) &...
         (dataSelector < matchValue(2)));
   elseif strcmpi(matchProp,'snippet')
      dataMax = max(dataSelector,[],2);
      dataMin = min(dataSelector,[],2);
      eventData = eventData(...
         (dataMin >= matchValue(1)) & ...
         (dataMax < matchValue(2)));
   else
      eventData = eventData(ismember(dataSelector,matchValue),:);
   end
end

end