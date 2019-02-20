classdef (ConstructOnLoad) assignmentEventData < event.EventData
%% ASSIGNMENTEVENTDATA   Event for assigning subset of spikes to a cluster
   properties
      subs                       % Subscripts of spikes to assign
      class                      % Class assignment index
      otherClassToUpdate = nan;  % Other class to update in addition
   end

   methods
      function evtData = assignmentEventData(subs,class,otherClassToUpdate)
         evtData.subs = subs;
         
         
         if numel(class) < numel(subs)
            if numel(class) == 1
               evtData.class = repmat(class,numel(subs),1);
            else
               error('Class assignment must have same number as subset index');
            end
         else
            evtData.class = class;
            
         end
         
         if nargin < 3
            return;
         end
         
         evtData.otherClassToUpdate = reshape(otherClassToUpdate,1,...
            numel(otherClassToUpdate));
         
      end
   end
   
end