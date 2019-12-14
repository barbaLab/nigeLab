classdef  (ConstructOnLoad) splitCompleted < event.EventData
% SPLITCOMPLETED event class to notify the dashboard and whoever else is
% involved that a block splitting procedure has completed. 
% Properties are a nigelObjs array. It is meant to carry the splitted
% blocks/Animals to a new destination.

 
    
    properties
         nigelObj;
    end
    
    methods
        function evtData = splitCompleted(nigelObj)
           evtData.nigelObj = nigelObj;
            
        end
    end
end