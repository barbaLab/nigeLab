function [eventData,blockIdx] = getEventData(blockObj,type,field,ch,matchField,matchValue)
%% GETEVENTDATA     Retrieve data for a given event
%
%  eventData = GETEVENTDATA(blockObj);
%  eventData = GETEVENTDATA(blockObj,type);
%  eventData = GETEVENTDATA(blockObj,type,field);
%  eventData = GETEVENTDATA(blockObj,type,field,ch);
%  eventData = GETEVENTDATA(blockObj,type,field,ch,matchField);
%  eventData = GETEVENTDATA(blockObj,type,field,ch,matchField,matchValue);
%  [eventData,blockIdx] = GETEVENTDATA(blockObj,___);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object.
%
%   type       :     Code for classifying different Events(char)
%                    ---- RECORDING-ASSOCIATED ----
%                    -> 'Stim'
%                    -> 'Sync'
%                    -> 'User'
%                    -> 'LPellet'
%                    -> 'LButtonDown'
%                    -> 'LButtonUp'
%                    -> 'RPellet'
%                    -> 'RButtonDown'
%                    -> 'RButtonUp'
%                    -> 'Beam'
%                    -> 'Nose'
%                    -> 'Epoch'
%                    ---- CHANNEL-ASSOCIATED ----
%                    -> 'Sorted'
%                    -> 'Clusters'
%                    -> 'Spikes'
%                    -> 'SpikeFeatures'
%                    -> 'Artifact'
%
%   field      :     Name of event data field (char):
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
%
%  matchField  :     Name of match data field (char)
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
if nargin < 2 % type was not provided
   type = 'Spikes';
end

if nargin < 3 % field was not provided
   field = 'value';
else
   field = lower(field);
end

if nargin < 4 % ch was not provided
   if isempty(blockObj(1).Mask)
      warning('No channel mask set for %s, using all channels.',...
         blockObj.Name);
      ch = 1:blockObj(1).NumChannels;
   else
      ch = blockObj(1).Mask;
   end
else
   F = {blockObj(1).Events.name};
   if iscell(ch)
      idx = [];
      for iCh = 1:numel(ch)
         tmp = [tmp, find(strcmpi(F,ch{iCh}))];  %#ok<*AGROW>
      end
      ch = tmp;
   elseif ischar(ch)
      ch = find(strcmpi(F,ch));
   end
   if isempty(ch)
      warning('Invalid channel fieldname.');
      eventData = [];
      return;
   end
end

if nargin < 5 % matchField was not provided
   matchField = 'value';
else
   if strcmpi(matchField,'ts') || strcmpi(matchField,'snippet')
      if numel(matchValue) ~= 2
         error('For ''ts'' or ''snippet'' matches, val must be 1x2.');
      end
   end
end

if nargin < 6 % matchValue was not provided
   matchValue = nan;
end



%% USE RECURSION TO ITERATE ON MULTIPLE CHANNELS
if (numel(ch) > 1)
   eventData = cell(size(ch));
   blockIdx = cell(size(ch));
   for iCh = 1:numel(ch)
      [eventData{iCh},blockIdx{iCh}] = getEventData(blockObj,...
         type,field,ch(iCh));
   end
   return;
end

%% USE RECURSION TO ITERATE ON MULTIPLE BLOCKS
if (numel(blockObj) > 1)
   eventData = [];
   blockIdx = [];
   masterID = parseChannelID(blockObj(1));
   masterIdx = matchChannelID(blockObj,masterID);
   for iBk = 1:numel(blockObj)
      [tmpData,tmpBlockIdx] = getEventData(blockObj(iBk),type,field,...
         masterIdx(ch,iBk));
      eventData = [eventData; tmpData];
      blockIdx = [blockIdx; tmpBlockIdx.*iBk];
   end
   return;
end

%% SHOULD ADD ERROR CHECKING HERE FOR IF THE FIELD IS UNAVAILABLE
% Events struct is not associated with channels, so handle differently
if ~any(strncmpi({'Spikes','SpikeFeatures','Clusters','Sorted'},type,7)) 
   eventData = blockObj.Events(ch).data.(field); 
   
   % If a value to match is given, then 
   if ~isnan(matchValue(1))
      dataSelector = blockObj.Events(ch).data.(matchField);
      if strcmpi(matchField,'ts')
         eventData = eventData((dataSelector >= matchValue(1)) &...
            (dataSelector < matchValue(2)));
      elseif strcmpi(matchField,'snippet')
         dataMax = max(dataSelector,[],2);
         dataMin = min(dataSelector,[],2);
         eventData = eventData((dataMin >= matchValue(1)) & ...
            (dataMax < matchValue(2)));
      else
         eventData = eventData(ismember(dataSelector,matchValue));
      end
   end
   
else % Otherwise, channel "events" (e.g. spikes etc.)
   F = fieldnames(blockObj.Channels(ch));
   iF = strncmpi(F,type,7);
   if sum(iF)==1
      eventData = retrieveChannelData(blockObj,ch,F{iF},field);
      if ~isnan(matchValue(1))
         dataSelector = retrieveChannelData(blockObj,ch,F{iF},matchField);
         if strcmpi(matchField,'ts')
            eventData = eventData((dataSelector >= matchValue(1)) &...
               (dataSelector < matchValue(2)));
         elseif strcmpi(matchField,'snippet')
            dataMax = max(dataSelector,[],2);
            dataMin = min(dataSelector,[],2);
            eventData = eventData((dataMin >= matchValue(1)) & ...
               (dataMax < matchValue(2)));
         else
            eventData = eventData(ismember(dataSelector,matchValue));
         end
      end
   elseif sum(iF)==0
      warning('Event type (%s) is missing. Returning empty array.',type);
      eventData = [];
   else
      warning('Event type (%s) is ambiguous. Returning empty array.',type);
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