classdef (ConstructOnLoad) dataScrolled < event.EventData
   properties
      ROI
   end
   
   methods
      function data = dataScrolled(newRoi)
         data.ROI = newRoi;
      end
   end
end