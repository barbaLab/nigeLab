function idx = getEventsIndex(blockObj,field,eventName)
%% GETEVENTSINDEX  Returns index to correct element of Events.(field)
%
%  idx = blockObj.getEventsIndex(field,eventName);
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

%% Check input
if numel(blockObj) > 1
   idx = nan(size(blockObj));
   for i = 1:numel(blockObj)
      idx(i) = getEventsIndex(blockObj(i),field,eventName);
   end
   return;
end

blockObj.checkCompatibility({field});

%%
name = {blockObj.Events.(field).name}.';
idx = find(ismember(name,eventName),1,'first');
if isempty(idx)
   error('Should not get here. Check Events initialization or linking.');
end

end