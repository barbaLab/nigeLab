classdef (ConstructOnLoad) vidstreamAdded < event.EventData
% vidstreamAdded issued when a new stream is added
properties
    name
    signal
    Key
    fs
    data
end

   methods
      function evt = vidstreamAdded(stream)
         %TIMEUPDATED  Constructor for time axes click event data
         %
         %  evt = nigeLab.evt.timeUpdated(timepoint);
         
         evt.name = stream.name;
         evt.signal = stream.signal;
         evt.Key = stream.Key;
         evt.fs = stream.fs;
         evt.data = stream.data;
      end
   end
   
end