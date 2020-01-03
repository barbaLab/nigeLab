classdef (ConstructOnLoad) barCleared < event.EventData
%BARCLEARED   Event issued by nigeLab.libs.nigelProgress when a "progress
%                bar" is cleared from the queue
% 
%  This is issued by the `nigeLab.libs.nigelProgress` "progress bar" object
%  via the 'StateChanged' event notification when the progress bar is
%  cleared from the queue by the user clicking the "red X" on the right of
%  the status bar (or if it is otherwise removed).
%
%  BARCLEARED Properties:
%
%     BarIndex  --  Index of bar into remote monitor 'bars' array
%
%     BlockSelectionIndex  --  Index of [animal block] from tank{} ref
%
%     IsComplete  --  Job was completed if true.
%
%     IsRemote  --  Job was run remotely if true.
%
%     Name  --  Name ('AnimalID.RecID') of job
%
%     Operation  --  Name of `do` Operation that was run for this job
%
%     Time  --  Start time of job (datetime)
%
%     Type  --  'Clear' (indicates the "type" of 'StateChanged' event)

   properties (Access = public)
      BarIndex            double   % Index of bar into remote monitor 'bars' array
      BlockSelectionIndex double   % Index of [animal block] from tank{} ref
      IsComplete          logical  % Was the job completed?
      IsRemote            logical  % Was job run remotely?
      Name                char     % Name (AnimalID.RecID) of job
      Operation           char     % Name of `do` Operation being run
      Time                datetime % Stop time of job
   end
   
   properties (GetAccess = public, SetAccess = immutable)
      Type char = 'Clear'          % "Type" of 'StateChanged' eventdata
   end
   

   methods (Access = public)
      function evt = barCleared(bar)
         %BARCLEARED   Event issued by nigeLab.libs.nigelProgress when a
         %                 "progress bar" is cleared from visual queue.
         %
         %  evt = nigeLab.evt.barCleared(bar);
         %
         %  bar  --  nigeLab.libs.nigelProgress "progress bar" object
         %
         %  evt  --  EventData that can be passed via `notify` function
         
         evt.BarIndex = bar.BarIndex;
         evt.BlockSelectionIndex = bar.BlockSelectionIndex;
         evt.IsComplete = bar.IsComplete;
         evt.IsRemote = bar.IsRemote;
         strinfo = strsplit(bar.Name,'.');
         evt.Name = strjoin(strinfo(1:2),'.');
         evt.Operation = strinfo{3};
         evt.Time = datetime();
      end
   end
   
end