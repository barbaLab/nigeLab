classdef (ConstructOnLoad) barStopped < event.EventData
%%BARSTOPPED   Event issued by nigeLab.libs.nigelProgress when a "progress
%                bar" stops running.

%% Properties
   properties (Access = public)
      BarIndex            double   % Index of bar into remote monitor 'bars' array
      BlockSelectionIndex double   % Index of [animal block] from tank{} ref
      IsComplete          logical  % Was the job completed
      IsRemote            logical  % Was job run remotely?
      Name                char     % Name (AnimalID.RecID) of job
      Operation           char     % Name of `do` Operation being run
      Time                datetime % Stop time of job
      Type = 'Stop'                % "Type" of eventdata
   end
   
%% Methods
   methods (Access = public)
      function evt = barStopped(bar)
         %%BARSTOPPED   Event issued by nigeLab.libs.nigelProgress when a
         %                 "progress bar" stops running.
         %
         %  evt = nigeLab.evt.barStopped(bar);
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