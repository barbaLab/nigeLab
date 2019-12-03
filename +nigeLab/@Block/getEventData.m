function [eventData,blockIdx] = getEventData(blockObj,field,prop,ch,matchProp,matchValue)
%% GETEVENTDATA     Retrieve data for a given event
%
%  eventData = GETEVENTDATA(blockObj);
%  eventData = GETEVENTDATA(blockObj,field);
%  eventData = GETEVENTDATA(blockObj,field,prop);
%  eventData = GETEVENTDATA(blockObj,field,prop,ch);
%  eventData = GETEVENTDATA(blockObj,field,prop,ch,matchProp);
%  eventData = GETEVENTDATA(blockObj,field,prop,ch,matchProp,matchValue);
%  [eventData,blockIdx] = GETEVENTDATA(blockObj,___);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object.
%
%   field      :     Code for classifying different Events(char)
%                    ---- RECORDING-ASSOCIATED ----
%                    -> Any FIELD of blockObj.Events
%                       --> e.g. 'ScoredEvents'; 'DigEvents'
%                    ---- CHANNEL-ASSOCIATED ----
%                    -> 'Sorted'
%                    -> 'Clusters'
%                    -> 'Spikes'
%                    -> 'SpikeFeatures'
%                    -> 'Artifact'
%
%                    NOTE: If this is left empty, it defaults to
%                    blockObj.Pars.Video.ScoringEventFieldName.
%
%   prop      :     Name of event data field (char):
%                    -> 'value' (def) // code for quantifying different
%                                    events. for example an event could
%                                    have two different values, but the
%                                    same tag.
%                    -> 'tag'     // code for qualitative descriptor of
%                                    event. all events of the same value
%                                    should have the same tag.
%                    -> 'ts'      // time (sec) of event
%                    -> 'snippet' // waveforms associated with event ts
%
%    ch        :     Channel index for retrieving spikes (int)
%                    -> If not specified, returns a cell array with spike
%                          indices for each channel.
%                    -> Can be given as a vector.
%                    -> If type is 'Events' this is the index of the
%                       desired Event Type. In this case, can also be given
%                       as a char or cell array of chars.
%                       --> e.g. 'Grasp'; 'Trial'; 'Reach'...
%
%  matchProp   :     Name of match data property (char)
%                    -> Must fit ismember() criterion:
%                    --> 'value' (def)
%                    --> 'tag'
%                    -------------------------
%                    -> Must fit >= matchValue(1) && < matchValue(2)
%                    --> 'ts'
%                    --> 'snippet' (all values must be within bounds)
%
%  matchValue  :     Value given that must be matched in the field given by
%                       matchField in order to select a data subset.
%                    -> Can be given as an array
%                    -> For 'ts' or 'snippet' value in matchField, must be
%                       given as an 2-element array where the first element
%                       is the lower (inclusive) bound and the second
%                       element is the upper (exclusive) bound.
%
%
%  --------
%   OUTPUT
%  --------
%  eventData   :     Data stored in field for a specific channel.
%
%  blockIdx    :     Index of the block that matches each element of data.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE INPUT
if nargin < 2 % field was not provided
   field = 'Spikes';
elseif isempty(field)
   blockObj.updateParams('Video');
   field = blockObj.Pars.Video.ScoringEventFieldName;
end

if nargin < 3 % prop was not provided
   prop = 'value';
else
   prop = lower(prop);
end

if nargin < 4 % ch was not provided
   if isempty(blockObj(1).Mask)
      warning('No channel mask set for %s, using all channels.',...
         blockObj.Name);
      ch = 1:blockObj(1).NumChannels;
   else
      ch = blockObj(1).Mask;
   end
end

if nargin < 5 % matchField was not provided
   matchProp = 'value';
else
   if strcmpi(matchProp,'ts') || strcmpi(matchProp,'snippet')
      if numel(matchValue) ~= 2
         error('For ''ts'' or ''snippet'' matches, val must be 1x2.');
      end
   end
end

if nargin < 6 % matchValue was not provided
   matchValue = nan;
end



%% USE RECURSION TO ITERATE ON MULTIPLE CHANNELS
if isnumeric(ch)
   if (numel(ch) > 1)
      eventData = cell(size(ch));
      blockIdx = cell(size(ch));
      for iCh = 1:numel(ch)
         [eventData{iCh},blockIdx{iCh}] = getEventData(blockObj,...
            field,prop,ch(iCh));
      end
      return;
   end
elseif iscell(ch)
   eventData = cell(size(ch));
   blockIdx = cell(size(ch));
   for iCh = 1:numel(ch)
      [eventData{iCh},blockIdx{iCh}] = getEventData(blockObj,...
         field,prop,ch{iCh});
   end
   return;
end

%% USE RECURSION TO ITERATE ON MULTIPLE BLOCKS
if (numel(blockObj) > 1)
   [eventData,blockIdx] = nigeLab.utils.initEmpty;
   if isnumeric(ch)
      masterID = parseChannelID(blockObj(1));
      masterIdx = matchChannelID(blockObj,masterID);
      for iBk = 1:numel(blockObj)
         [tmpData,tmpBlockIdx] = getEventData(blockObj(iBk),field,prop,...
            masterIdx(ch,iBk));
         eventData = [eventData; tmpData]; %#ok<*AGROW>
         blockIdx = [blockIdx; tmpBlockIdx.*iBk];
      end
   else
      for iBk = 1:numel(blockObj)
         [tmpData,tmpBlockIdx] = getEventData(blockObj(iBk),field,prop,ch);
         eventData = [eventData; tmpData];
         blockIdx = [blockIdx; tmpBlockIdx.*iBk];
      end
   end
   return;
end

%% SHOULD ADD ERROR CHECKING HERE FOR IF THE FIELD IS UNAVAILABLE
blockObj.checkCompatibility(field);
% Events struct is not associated with channels, so handle differently
if ~any(strncmpi({'Spikes','SpikeFeatures','Clusters','Sorted'},field,7)) 
   propName = lower(prop);
   switch propName % Define some things to make it easier to avoid typo etc
      case {'times','timestamps','t'}
         propName = 'ts';
      case {'index','id','val','group'}
         propName = 'value';
      case {'snip','snips','rate','lfp','aligned','x'}
         propName = 'snippet';
      case {'mask','label','name'}
         propName = 'tag';
      otherwise
         % do nothing
   end
   
   
   idx = blockObj.getEventsIndex(field,ch);
   
   % Note that .data is STRUCT field; .data.data would be DiskData "data"
   eventData = [];
   if isfield(blockObj.Events,field)
      if numel(blockObj.Events.(field)) >= idx
         if isfield(blockObj.Events.(field)(idx),'data')
            if isa(blockObj.Events.(field)(idx).data,'nigeLab.libs.DiskData')
               if size(blockObj.Events.(field)(idx).data,2)>=5 % Then it exists and has been initialized correctly
                  tmp = blockObj.Events.(field)(idx).data;
                  eventData = tmp.(propName); 
               else
                  warning(['DiskData for Events.%s(%g) exists, but is ' ...
                           'not initialized correctly (too small -- ' ...
                           'only %g columns).'],field,idx,...
                           size(blockObj.Events.(field)(idx).data,2));
                  return;
               end
            else
               warning(['Events.%s(%g) exists, but is not a DiskData ' ...
                        '(current class is %g).'],field,idx,...
                        class(blockObj.Events.(field)(idx).data));
               return;
            end
         else
            warning('''data'' is not a field of Events.%s(%g) yet.',...
               field,idx);
            return;
         end
      else
         warning('Events.%s(%g) exceeds array dimensions.',field,idx);
         return;
      end
   else
      warning('%s is not a field of Block.Events.',field);
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
   
else % Otherwise, channel "events" (e.g. spikes etc.)
   F = fieldnames(blockObj.Channels(ch));
   iF = strncmpi(F,field,7);
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
end
blockIdx = ones(size(eventData,1),1);

   function out = retrieveChannelData(blockObj,ch,type,field)
      try
         out = blockObj.Channels(ch).(type).(field);
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