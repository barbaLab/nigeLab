classdef  (ConstructOnLoad) splitCompleted < event.EventData
   % SPLITCOMPLETED  Event class to notify the DashBoard and any other
   %                 objects involved in splitting a "multi-animal" block.
   %
   %  This event should be associated with the 'splitCompleted' Event that
   %  is issued once the "split multi-animal blocks" procedure is completed
   %  using the `nigeLab.libs.splitMultiAnimalsUI` 
   %
   %  SPLITCOMPLETED Properties:
   %     nigelObj  -  An array of `nigelObjects` such as `Block`
   %        It should contain all the `Block` and `Animal` handles that
   %        will be split by separating the corresponding sub-elements
   %        (such as individual Raw Channels files for example) to the
   %        correctly-associated `Block`
    
   properties
      nigelObj  % An array of `nigelObjects`
   end
   
   methods
      function evtData = splitCompleted(nigelObj)
      % SPLITCOMPLETED Event class to notify the DashBoard and any other
      %                objects involved in splitting a "multi-animal" block
      %
      %  evtData = nigeLab.evt.splitCompleted(blockObjArray);
      %  evtData = nigeLab.evt.splitCompleted(animalObjArray);
      
         evtData.nigelObj = nigelObj;   
      end
   end
end