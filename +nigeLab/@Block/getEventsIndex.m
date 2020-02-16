function [idx,field] = getEventsIndex(blockObj,field,eventName)
% GETEVENTSINDEX  Returns index to correct element of Events.(field)
%
%  [idx,field] = blockObj.getEventsIndex('field','eventName');
%  --> Searches blockObj.Events.('field') for first instance of 'eventName'
%  --> If no such field of .Events, looks in ALL .Events fields, returning
%  the new value of 'field' in the second output argument.
%
%  [idx,field] = getEventsIndex(blockObj,'eventName');
%  --> Searches all fields of .Events for first instance of sub-field
%  'eventName'
%
%  >> [idx,field] = getEventsIndex(blockObj,[],'eventName');
%  --> Searches all fields of .Events for the first instance of sub-field
%     'eventName'
%
%  --------
%   INPUTS
%  --------
%  blockObj       :     nigeLab.Block class object
%
%   field         :     Name of Events field (blockObj.Events.(field))
%
%  eventName      :     Name of event type to return 
%                       (blockObj.Events.(field)(idx).name == eventName)

% Handle only 2 input args
if nargin < 3
   eventName = field;
   field = fieldnames(blockObj.Events);
end

% Check input, iterate on multiple blocks
if numel(blockObj) > 1
   idx = nan(size(blockObj));
   for i = 1:numel(blockObj)
      [idx(i),tmp] = getEventsIndex(blockObj(i),field,eventName);
      if ~isnan(idx(i))
         field = tmp;
      end
   end
   return;
end

% Iterate on multiple given fieldnames
if iscell(field)
   idx = nan; 
   i = 0;
   while isnan(idx) && (i < numel(field))
      i = i + 1;
      [idx,tmp] = getEventsIndex(blockObj,field{i},eventName);      
   end
   if ~isempty(idx)
      field = tmp;
   end
   return;
else
   % Check that 'field' is valid
   if isempty(field)
      field = fieldnames(blockObj.Events);
   elseif ~ismember(field,fieldnames(blockObj.Events))
      eventName = field;
      field = fieldnames(blockObj.Events);
   end
end

checkCompatibility(blockObj,{field});

name = {blockObj.Events.(field).name}.';
idx = find(ismember(name,eventName),1,'first');
if isempty(idx)
   idx = nan;
end

end