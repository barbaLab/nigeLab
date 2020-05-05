classdef  (ConstructOnLoad) splitCompleted < event.EventData
   % SPLITCOMPLETED  Event class to notify the DashBoard and any other
   %                 objects involved in splitting a "multi-animal" block.
   %
   %  This event should be associated with the 'splitCompleted' Event that
   %  is issued once the "split multi-animal blocks" procedure is completed
   %  using the `nigeLab.libs.splitMultiAnimalsUI` 
   %
   %  SPLITCOMPLETED Properties:
   %     obj  --  An array of `nigelObjects` such as `Block`
   %        It should contain all the `Block` and `Animal` handles that
   %        will be split by separating the corresponding sub-elements
   %        (such as individual Raw Channels files for example) to the
   %        correctly-associated `Block`
   %
   %     type  --  {'Block', 'Animal', or 'Tank'} (type of nigelObj)
   %
   %     n  --  Number of nigelObjects in array
   %
   %  SPLITCOMPLETED Methods:
   %     splitCompleted  --  Constructor for 'multiAnimals' split eventdata
   %        evt = nigeLab.evt.splitCompleted(nigelObjArray);
    
   properties (GetAccess = public, SetAccess = immutable)
%       nigelObj         % An array of `nigelObjects`
%       type    char     % Type of `nigelObject`
%       n       double   % Number of nigelObjects in array
   end
   
   methods (Access = public)
      function evt = splitCompleted()
      % SPLITCOMPLETED Event class to notify the DashBoard and any other
      %                objects involved in splitting a "multi-animal" block
      %
      %  evt = nigeLab.evt.splitCompleted(blockObjArray);
      %  evt = nigeLab.evt.splitCompleted(animalObjArray);
      
%          evt.nigelObj = nigelObj;
%          clInfo = strsplit(class(nigelObj),'.');
%          evt.type = clInfo{2};
%          evt.n = numel(nigelObj);
      end
   end
end