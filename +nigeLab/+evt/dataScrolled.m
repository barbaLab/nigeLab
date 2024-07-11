classdef (ConstructOnLoad) dataScrolled < event.EventData
   properties
      ROI
   end
   
   methods
       function data = dataScrolled(newRoi,newRoiIDX)
         data.ROI   = newRoi;
         dataROIidx = newRoiIDX;
      end
   end
end