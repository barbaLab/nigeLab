function [data,blockIdx] = getEventData(blockObj,type,field,ch,matchValue,matchField)
%% GETEVENTDATA     Retrieve data for a given event
%
%  data = GETEVENTDATA(blockObj);
%  data = GETEVENTDATA(blockObj,type);
%  data = GETEVENTDATA(blockObj,type,field);
%  data = GETEVENTDATA(blockObj,type,field,ch);
%  data = GETEVENTDATA(blockObj,type,field,ch,matchValue);
%  data = GETEVENTDATA(blockObj,type,field,ch,matchValue,matchField);
%  [data,blockIdx] = GETEVENTDATA(blockObj,___);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object.
%
%   type       :     Code for classifying different (char)
%                    -> 'Events' (def; experiment-associated)
%                    ---- Anything else is CHANNEL-ASSOCIATED ----
%                    -> 'Sorted'
%                    -> 'Clusters'
%                    -> etc...
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
%  matchValue  :     Value given that must be matched in the field given by
%                       matchField in order to select a data subset.
%                    -> Can be given as an array
%
%  matchField  :     Name of match data field (char)
%                    -> Must fit ismember() criterion:
%                    --> 'value' (def)
%                    --> 'tag'
%                    -------------------------
%                    -> Must fit >= matchValue(1) && <= matchValue(2)
%                    --> 'ts'
%                    --> 'snippet' (all values must be within bounds)
%
%
%  --------
%   OUTPUT
%  --------
%    data      :     Data stored in field for a specific channel.
%
%  blockIdx    :     Index of the block that matches each element of data.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE INPUT
if nargin < 2 % type was not provided
   type = 'Events';
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
   F = fieldnames(blockObj(1).Events);
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
      data = [];
      return;
   end
end

if nargin < 5 % matchValue was not provided
   matchValue = nan;
end

if nargin < 6 % matchField was not provided
   matchField = 'value';
else
   if strcmpi(matchField,'ts') || strcmpi(matchField,'snippet')
      if numel(matchValue) ~= 2
         error('For ''ts'' or ''snippet'' matches, val must be 1x2.');
      end
   end
end

%% USE RECURSION TO ITERATE ON MULTIPLE CHANNELS
if (numel(ch) > 1)
   data = cell(size(ch));
   blockIdx = cell(size(ch));
   for iCh = 1:numel(ch)
      [data{iCh},blockIdx{iCh}] = getEventData(blockObj,...
         type,field,ch(iCh));
   end
   return;
end

%% USE RECURSION TO ITERATE ON MULTIPLE BLOCKS
if (numel(blockObj) > 1)
   data = [];
   blockIdx = [];
   masterID = parseChannelID(blockObj(1));
   masterIdx = matchChannelID(blockObj,masterID);
   for iBk = 1:numel(blockObj)
      [tmpData,tmpBlockIdx] = getEventData(blockObj(iBk),type,field,...
         masterIdx(ch,iBk));
      data = [data, tmpData];
      blockIdx = [blockIdx, tmpBlockIdx.*iBk];
   end
   return;
end

%% SHOULD ADD ERROR CHECKING HERE FOR IF THE FIELD IS UNAVAILABLE
if strnmpi(type,'Events',5)
   data = blockObj.Events(ch).(field);
   if ~isnan(matchValue(1))
      dataSelector = blockObj.Events(ch).(matchField);
      if strcmpi(matchField,'ts')
         data = data((dataSelector >= matchValue(1)) &...
            (dataSelector <= matchValue(2)));
      elseif strcmpi(matchField,'snippet')
         dataMax = max(dataSelector,[],2);
         dataMin = min(dataSelector,[],2);
         data = data((dataMin >= matchValue(1)) & ...
            (dataMax <= matchValue(2)));
      else
         data = data(ismember(dataSelector,matchValue));
      end
   end
else
   F = fieldnames(blockObj.Channels(ch));
   iF = strncmpi(F,type,4);
   if sum(iF)==1
      data = retrieveChannelData(blockObj,ch,F{iF},field);
      if ~isnan(matchValue(1))
         dataSelector = retrieveChannelData(blockObj,ch,F{iF},matchField);
         if strcmpi(matchField,'ts')
            data = data((dataSelector >= matchValue(1)) &...
               (dataSelector <= matchValue(2)));
         elseif strcmpi(matchField,'snippet')
            dataMax = max(dataSelector,[],2);
            dataMin = min(dataSelector,[],2);
            data = data((dataMin >= matchValue(1)) & ...
               (dataMax <= matchValue(2)));
         else
            data = data(ismember(dataSelector,matchValue));
         end
      end
   elseif sum(iF)==0
      warning('Event type (%s) is missing. Returning empty array.',type);
      data = [];
   else
      warning('Event type (%s) is ambiguous. Returning empty array.',type);
      data = [];
   end
end
blockIdx = ones(size(data,1),1);

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