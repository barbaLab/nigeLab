function eventData = getChannelsEventData(blockObj,field,prop,ch,matchProp,matchValue)
%GETCHANNELSEVENTDATA  Returns event-data related to individual Channels
%
%  eventData =
%  blockObj.getChannelsEventData(field,prop,ch,matchProp,matchValue);
%
%  Should be called from blockObj.getEventData.

F = fieldnames(blockObj.Channels(ch));
iF = strcmpi(F,field);
if sum(iF)==1
   eventData = retrieveChannelData(blockObj,ch,F{iF},prop);
   if ~isnan(matchValue(1))
      dataSelector = retrieveChannelData(blockObj,ch,F{iF},matchProp);
      if strcmpi(matchProp,'ts')
         eventData = eventData((dataSelector >= matchValue(1)) &...
            (dataSelector < matchValue(2)));
      elseif strcmpi(matchProp,'snippet')
         dataMax = max(dataSelector,[],2);
         dataMin = min(dataSelector,[],2);
         eventData = eventData((dataMin >= matchValue(1)) & ...
            (dataMax < matchValue(2)));
      else
         eventData = eventData(ismember(dataSelector,matchValue));
      end
   end
elseif sum(iF)==0
   warning('Event type (%s) is missing. Returning empty array.',field);
   eventData = [];
else
   warning('Event type (%s) is ambiguous. Returning empty array.',field);
   eventData = [];
end

   % Helper function to try and make this reverse-compatible with CPLTools
   function out = retrieveChannelData(blockObj,ch,type,field)
      %RETRIEVECHANNELDATA  Attempt to get data assuming it is a "standard"
      %                     nigeLab.libs.DiskData 'Events' file type; if it
      %                     is not, try to retrieve the desired field under
      %                     assumption it is in "old" CPLTools spikes files
      %                     format.
      
      try
         nonEmpty = blockObj.Channels(ch).(type).checkSize();
         if nonEmpty
            out = blockObj.Channels(ch).(type).(field);
         else
            out = [];
         end
      catch me % Parse for old file format
         if strcmp(me.identifier,'MATLAB:MatFile:VariableNotInFile')
            switch field
               case 'value'
                  out = blockObj.Channels(ch).(type).class;
                  
               case 'snippet'
                  out = blockObj.Channels(ch).(type).spikes;
                  
               case 'ts'
                  pk = blockObj.Channels(ch).Spikes.peak_train;
                  out = find(pk)./blockObj.SampleRate;
                  
               otherwise
                  warning('Unsure how to handle variable: %s',field);
                  rethrow(me);
            end
         else
            rethrow(me);
         end
      end
   end

end