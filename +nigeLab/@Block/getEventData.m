function data = getEventData(blockObj,type,field,ch)
%% GETEVENTDATA     Retrieve data for a given event
%
%   data = GETEVENTDATA(blockObj);
%   data = GETEVENTDATA(blockObj,type);
%   data = GETEVENTDATA(blockObj,type,field);
%   data = GETEVENTDATA(blockObj,type,field,ch);
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
   ch = 1:blockObj(1).NumChannels;
else
   f = fieldnames(blockObj(1).Events);
   if iscell(ch)
      idx = [];
      for ii = 1:numel(ch)
         tmp = [tmp, find(strcmpi(f,ch{ii}))]; %#ok<AGROW>
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
   for ii = 1:numel(ch)
      data{ii} = getEventData(blockObj,ch(ii));
   end
   return;
end

%% USE RECURSION TO ITERATE ON MULTIPLE BLOCKS
if (numel(blockObj) > 1)
   data = [];
   for ii = 1:numel(blockObj)
      data = [data; getEventData(blockObj,ch(ii))]; %#ok<AGROW>
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
      data = blockObj.Channels(ch).(f{fIdx}).(field);
   elseif sum(fIdx)==0
      warning('Event type (%s) is missing. Returning empty array.',type);
      data = [];
   else
      warning('Event type (%s) is ambiguous. Returning empty array.',type);
      data = [];
   end
end


end