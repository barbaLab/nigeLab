function [eventData,blockIdx] = getEventData(blockObj,field,prop,ch,matchProp,matchValue)
%GETEVENTDATA     Retrieve data for a given event
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

% PARSE INPUT
if nargin < 2 % field was not provided
   field = 'Spikes';
elseif isempty(field)
   blockObj.updateParams('Video');
   field = blockObj.Pars.Video.ScoringEventFieldName;
end

if nargin < 3 % prop was not provided
   prop = 'value'; % Equivalent to "cluster" for clusters/sorted data
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

% ITERATE ON MULTIPLE CHANNELS
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

% ITERATE ON MULTIPLE BLOCKS
if (numel(blockObj) > 1)
   [eventData,blockIdx] = nigeLab.utils.initEmpty;
   if isnumeric(ch)
      masterID = ChannelID(blockObj); % Gets "biggest" ChannelID matrix
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

blockObj.checkCompatibility(field);
% Events struct is not associated with channels, so handle differently
fieldType = blockObj.getFieldType(field);
switch fieldType
   case 'Channels' % Returns Events parsed from Channels
      eventData = blockObj.getChannelsEventData(field,prop,ch,...
         matchProp,matchValue);
   case {'Streams','Events'} % Returns Events parsed from Streams (go in .Events)
      eventName = ch;
      eventData = blockObj.getStreamsEventData(field,prop,eventName,...
         matchProp,matchValue);
   otherwise
      error(['nigeLab:' mfilename ':UnexpectedFieldType'],...
         'Unexpected FieldType: %s (%s)',fieldType,blockObj.Name);
end
blockIdx = ones(size(eventData,1),1);

end