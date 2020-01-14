classdef (ConstructOnLoad) barStarted < event.EventData
%BARSTARTED   Event issued by nigeLab.libs.nigelProgress when a "progress
%                bar" starts running.
%
%  This is issued by the `nigeLab.libs.nigelProgress` "progress bar" object
%  via the 'StateChanged' event notification. This notification occurs when
%  the `nigeLab.libs.nigelProgress/startBar()` method is invoked.
%
%  BARSTARTED Properties:
%     BarIndex  --  Index of bar into remote monitor 'bars' array
%
%     BlockSelectionIndex  --  Index of [animal block] from tank{} ref
%
%     IsRemote  --  Was job run remotely?
%
%     Name  --  Name ('AnimalID.RecID') of job
%
%     Operation  --  Name of `do` Operation being run
%
%     Time  --  Start time of job (datetime)
%
%     Type  --  'Start' (indicates the "type" of 'StateChanged' event)

   properties (Access = public)
      BarIndex            double   % Index of bar into remote monitor 'bars' array
      BlockSelectionIndex double   % Index of [animal block] from tank{} ref
      IsRemote            logical  % Was job run remotely?
      Name                char     % Name (AnimalID.RecID) of job
      Operation           char     % Name of `do` Operation being run
      Time                datetime % Start time of job
   end
   
   properties (GetAccess = public, SetAccess = immutable)
      Type char = 'Start'          % "Type" of eventdata
   end
   
   methods (Access = public)
      function evt = barStarted(bar)
         %BARSTARTED   Event issued by nigeLab.libs.nigelProgress when a
         %                 "progress bar" starts running.
         %
         %  evt = nigeLab.evt.barStarted(bar);
         %
         %  bar  --  nigeLab.libs.nigelProgress "progress bar" object
         %
         %  evt  --  EventData that can be passed via `notify` function
         
         evt.BarIndex = bar.BarIndex;
         evt.BlockSelectionIndex = bar.BlockSelectionIndex;
         evt.IsRemote = bar.IsRemote;
         strinfo = strsplit(bar.Name,'.');
         evt.Name = strjoin(strinfo(1:2),'.');
         evt.Operation = strinfo{3};
         evt.Time = datetime();
      end
   end
   
end