classdef (ConstructOnLoad) evtChanged < event.EventData
    % evtChanged  Event notifying the addition or deletion of an annotation on
    % the data
    %
    %  Issued when a new annotation is set, an annotation is deleted or an
    %  annotation is changed
    
    
    properties
        name                      % Annotation name
        time                      % Annotation TS
        data                      % other data
        idx                       % index of the annotation in the series
        trial                     % trial corresponding to the annotation
    end
    
    methods
        function obj = evtChanged(name,time,data,idx,trial)
            obj.name = name;
            obj.time = time;
            obj.data = data;
            obj.idx = idx;
            obj.trial = trial;
        end
        
        function str = toStruct(obj)
            str = struct();
            str.Name    = obj.name;
            str.Tag    = obj.name;
            str.Ts      = obj.time;
            str.Data = obj.data;
            str.Idx     = obj.idx;
            str.Trial   = obj.trial;
            str.Duration= 1;
        end
        
    end
end