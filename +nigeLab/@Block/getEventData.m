function [data,blockIdx] = getEventData(blockObj,type,field,ch)
%% GETEVENTDATA     Retrieve data for a given event
%
%  data = GETEVENTDATA(blockObj);
%  data = GETEVENTDATA(blockObj,type);
%  data = GETEVENTDATA(blockObj,type,field);
%  data = GETEVENTDATA(blockObj,type,field,ch);
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
%    ch        :     Channel index for retrieving spikes (int)
%                    -> If not specified, returns a cell array with spike
%                          indices for each channel.
%                    -> Can be given as a vector.
%                    -> If type is 'Events' this is the index of the
%                       desired Event Type. In this case, can also be given
%                       as a char or cell array of chars.
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
%  --------
%   OUTPUT
%  --------
%    data      :     Data stored in field for a specific channel.
%
%  blockIdx    :     Index of the block that matches each element of data.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% PARSE INPUT
if nargin < 2
   type = 'Events';
end

if nargin < 3
   field = 'value';
else
   field = lower(field);
end

% Would be good to add something here that links up the channels from
% unique Blocks, similar to as is done in the nigeLab.Sort object.
if nargin < 4
   if isempty(blockObj(1).Mask)
      warning('No channel mask set for %s, using all channels.',...
         blockObj.Name);
      ch = 1:blockObj(1).NumChannels;
   else
      ch = blockObj(1).Mask;
   end
   
else
   f = fieldnames(blockObj(1).Events);
   if iscell(ch)
      idx = [];
      for ii = 1:numel(ch)
         tmp = [tmp, find(strcmpi(f,ch{ii}))];  %#ok<*AGROW>
      end
      ch = tmp;
   elseif ischar(ch)
      ch = find(strcmpi(f,ch));
   end
   if isempty(ch)
      warning('Invalid channel fieldname.');
      data = [];
      return;
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
else
   f = fieldnames(blockObj.Channels(ch));
   fIdx = strncmpi(f,type,4);
   if sum(fIdx)==1
      try
         data = blockObj.Channels(ch).(f{fIdx}).(field);
      catch me % Parse for old file format
         if strcmp(me.identifier,'MATLAB:MatFile:VariableNotInFile')
            switch field
               case 'value'
                  data = blockObj.Channels(ch).(f{fIdx}).class;
                  
               case 'snippet'
                  data = blockObj.Channels(ch).(f{fIdx}).spikes;
                  
               case 'ts'
                  idx = blockObj.Channels(ch).(f{fIdx}).peak_train;
                  data = find(idx)./blockObj.SampleRate;
                  
               otherwise
                  warning('Unsure how to handle variable: %s',field);
                  rethrow(me);
            end
         else
            rethrow(me);
         end
      end
   elseif sum(fIdx)==0
      warning('Event type (%s) is missing. Returning empty array.',type);
      data = [];
   else
      warning('Event type (%s) is ambiguous. Returning empty array.',type);
      data = [];
   end
end
blockIdx = ones(size(data,1),1);

end