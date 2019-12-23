classdef (ConstructOnLoad) progressChangedEventData < event.EventData
   % PROGRESSCHANGEDEVENTDATA  Event data with "pct" property that
   %                           reflects the current processing status of
   %                           anything that is "reported on" by the block
   %                           method "reportProgress," which has been
   %                           updated to issue the Block
   %                           'ProgressChanged' event notification when
   %                           the progress has changed by a minimum
   %                           increment.
   
   properties
      status    char     % Char array associated with notification status
      progress  double   % Number from 0 to 100 (or NaN) for % completion
   end
   
   methods
      function evtData = progressChangedEventData(s,p)
         % PROGRESSCHANGEDEVENTDATA  Event data with "pct" property that
         %                           reflects the current processing status of
         %                           anything that is "reported on" by the block
         %                           method "reportProgress," which has been
         %                           updated to issue the Block
         %                           'ProgressChanged' event notification when
         %                           the progress has changed by a minimum
         %                           increment.
         %
         %  evtData = nigeLab.evt.progressChangedEventData(pct);
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
         %  evtData = nigeLab.evt.progressChangedEventData('Done.',pct);
         %  notify(blockObj,'ProgressChanged',evtData);
         
         evtData.status = s;
         evtData.progress = p;
      end
   end
   
end

