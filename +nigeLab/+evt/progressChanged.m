classdef (ConstructOnLoad) progressChanged < event.EventData
   %PROGRESSCHANGED  Event data with "progress" property that reflects the 
   % current processing status of anything that is "reported on" by the 
   % `nigeLab.Block/reportProgress()` method.
   %
   %  The 'ProgressChanged' event notification is issued by reportProgress
   %  when the relative completion progress (ranging between 0 and 100) of
   %  a particular `doMethod` (or any method that uses `reportProgress`)
   %  has increased by some fixed minimum increment. 
   %
   %  This primarily interacts with `nigeLab.libs.nigelProgress`, where the
   %  value of evt.progress is used to fill the "%" value on the right, and
   %  the value of evt.status is used to fill the middle text of the
   %  progress bar.
   %
   %  PROGRESSCHANGED Properties:
   %
   %     status  --  Char array associated with notification status
   %
   %     progress  --  Number from 0 to 100 (or NaN) for task completion %
   %
   %  PROGRESSCHANGED Methods:
   %
   %     progressChanged  --  Class constructor
   %        evt = nigeLab.evt.progressChanged(status,progress);
   
   properties (GetAccess = public, SetAccess = immutable)
      status    char     % Char array associated with notification status
      progress  double   % Number from 0 to 100 (or NaN) for % completion
   end
   
   methods
      function evt = progressChanged(status,progress)
         % PROGRESSCHANGED  Constructor for "bar % updater" event data
         %
         %  evtData = nigeLab.evt.progressChanged(pct);
         %  --> Creates event data that can be passed via `notify` during a
         %      'ProgressChanged' event notification to give the listener
         %      information about current percent completion.
         %
         %  e.g.
         %  ...
         %  % Some processing
         %  ...
         %  % Compute percent completion
         %  ...
         %  evt = nigeLab.evt.progressChanged('Done.',pct);
         %  notify(blockObj,'ProgressChanged',evt);
         
         evt.status = status;
         evt.progress = progress;
      end
   end
   
end

