classdef (ConstructOnLoad) timeUpdated < event.EventData
%TIMEUPDATED   Event for clicking on nigeLab.libs.TimeScrollerAxes
%
%  Issued when the user clicks on a graphical axes object that allows
%  "jumping" to different video frames by issuing an **AxesClicked** event
%  notification to any potential listeners.
%
%  timeUpdated Properties:
%  
%     time  --  Time corresponding to xData of clicked axes point
%
%  
%  timeUpdated Methods:
%
%     timeUpdated  --  Event data class constructor
%        evt = nigeLab.evt.timeUpdated(timepoint);

   properties
      time  (1,1) double  % Scalar double of new value from update
   end
   
   methods
      function evt = timeUpdated(timepoint)
         %TIMEUPDATED  Constructor for time axes click event data
         %
         %  evt = nigeLab.evt.timeUpdated(timepoint);
         
         evt.time = timepoint;
      end
   end
   
end