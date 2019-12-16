classdef (ConstructOnLoad) jobCompleted < event.EventData
    % JOBCOMPLETED event class to notify the dashboard of any cmopleted
    % operation
    % Is very basic at this point, but other functionality can be added in
    % the future. What is needed right now is only the index of the block
    % that went through the processing. This is used to refresh the gui un
    % unlock the execution of the next processing step. 
    
    properties
         bar;
    end
    
    methods
        function evtData = jobCompleted(bar)
           evtData.bar = bar;
            
        end
    end
    
end

