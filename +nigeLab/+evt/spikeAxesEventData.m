classdef (ConstructOnLoad) spikeAxesEventData < event.EventData
%%ASSIGNMENTEVENTDATA   Event for clicking on a spike axes
   properties
      visible % 0: Scatter is hidden (unchecked); 1: Scatter is shown
      class   % Cluster class index
   end
   
   methods
      function evtData = spikeAxesEventData(class,visible)
         evtData.class = class;
         evtData.visible = visible;
      end
   end
   
end