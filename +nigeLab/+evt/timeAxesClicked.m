classdef (ConstructOnLoad) timeAxesClicked < event.EventData
%TIMEAXESCLICKED   Event for clicking on nigeLab.libs.TimeScrollerAxes
%
%  Issued when the user clicks on a graphical axes object that allows
%  "jumping" to different video frames by issuing an **AxesClicked** event
%  notification to any potential listeners.
%
%  TIMEAXESCLICKED Properties:
%  
%     time  --  Time corresponding to xData of clicked axes point
%
%  
%  TIMEAXESCLICKED Methods:
%
%     timeAxesClicked  --  Event data class constructor
%        evt = nigeLab.evt.timeAxesClicked(timepoint);

   properties
      time  (1,1) double  % Time corresponding to xData of clicked point
   end
   
   methods
      function evt = timeAxesClicked(timepoint)
         %TIMEAXESCLICKED  Constructor for time axes click event data
         %
         %  evt = nigeLab.evt.timeAxesClicked(timepoint);
         
         evt.time = timepoint;
      end
   end
   
end