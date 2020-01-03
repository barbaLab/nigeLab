classdef (ConstructOnLoad) jobCompleted < event.EventData
%JOBCOMPLETED   Event issued by nigeLab.libs.remoteMonitor on job complete
%
%  This is used to update the status of graphical progress bars
%  (`nigeLab.libs.nigelProgress`) that are used in the "Queue" panel of
%  `nigeLab.libs.DashBoard` (nigelDash). 
%
%  The `nigeLab.libs.remoteMonitor` issues the `JobCompleted` event
%  notification, which triggers this event data.
%
%  JOBCOMPLETED Properties:
%
%     Bar  --  nigeLab.libs.nigelProgress associated progress bar for job
%
%     BarIndex  --  Index of bar into remote monitor 'bars' property array
%
%     BlockSelectionIndex  --  Index of [animal block] from tank{} ref
%
%     IsComplete  --  Was the job completed?
%
%     IsRemote  --  Was job run on remote worker?
%
%
%  JOBCOMPLETED Methods:
%
%     jobCompleted  --  Constructor for job completion event data
%        evt = nigeLab.evt.jobCompleted(bar);

   properties (Access = public)
      Bar                 nigeLab.libs.nigelProgress  % nigelProgressObj
      BarIndex            double   % Index of bar into remote monitor 'bars' array
      BlockSelectionIndex double   % Index of [animal block] from tank{} ref
      IsComplete          logical  % Was the job completed
      IsRemote            logical  % Was job run remotely?
   end

   methods (Access = public)
      function evt = jobCompleted(bar)
         %JOBCOMPLETED   Class constructor for job completion event data
         %
         %  evt = nigeLab.evt.jobCompleted(bar);
         %
         %  bar  --  nigeLab.libs.nigelProgress "progress bar" object
         %
         %  evt  --  EventData that can be passed via `notify` function
         
         evt.Bar = bar;
         evt.BarIndex = bar.BarIndex;
         evt.BlockSelectionIndex = bar.BlockSelectionIndex;
         evt.IsComplete = bar.IsComplete;
         evt.IsRemote = bar.IsRemote;
      end
   end
   
end