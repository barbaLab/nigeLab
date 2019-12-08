classdef (ConstructOnLoad) jobCompletedEventData < event.EventData
%%JOBCOMPLETEDEVENTDATA   Event issued by nigeLab.libs.remoteMonitor when a
%                         JOB is completed.

%% Properties
   properties
      progBar   nigeLab.libs.nigelProgress  % nigelProgressObj
      data                                  % UserData from nigelProgressObj
   end
   
%% Methods
   methods
      function evtData = jobCompletedEventData(nigelProgressObj)
         %%JOBCOMPLETEDEVENTDATA   Event issued by 
         %                         nigeLab.libs.remoteMonitor when a
         %                         JOB is completed.
         
         evtData.bar = nigelProgressObj;
         evtData.data = nigelProgressObj.UserData;
      end
   end
   
end