classdef (ConstructOnLoad) jobCompletedEventData < event.EventData
%%JOBCOMPLETEDEVENTDATA   Event issued by nigeLab.libs.remoteMonitor when a
%                         JOB is completed.

%% Properties
   properties (Access = public)
      Bar                 nigeLab.libs.nigelProgress  % nigelProgressObj
      BarIndex            double   % Index of bar into remote monitor 'bars' array
      BlockSelectionIndex double   % Index of [animal block] from tank{} ref
      IsComplete          logical  % Was the job completed
      IsRemote            logical  % Was job run remotely?
   end
   
%% Methods
   methods (Access = public)
      function evt = jobCompletedEventData(bar)
         %%JOBCOMPLETEDEVENTDATA   Event issued by 
         %                         nigeLab.libs.remoteMonitor when a
         %                         JOB is completed.
         %
         %  evt = nigeLab.evt.jobCompletedEventData(bar);
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