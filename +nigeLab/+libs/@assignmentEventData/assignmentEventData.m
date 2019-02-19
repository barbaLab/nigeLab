classdef (ConstructOnLoad) assignmentEventData < event.EventData
   properties
      subs
      class
   end
   
   methods
      function evtData = assignmentEventData(subs,class)
         evtData.subs = subs;
         evtData.class = class;
      end
   end
   
end