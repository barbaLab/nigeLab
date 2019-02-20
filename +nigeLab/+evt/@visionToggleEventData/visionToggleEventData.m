classdef (ConstructOnLoad) visionToggleEventData < event.EventData
%% VISSIONTOGGLEEVENTDATA  Event for clicking on a spike axes
   properties
      ind2D
      ind3D
      state
      clus
      val
   end
   
   methods
      function evtData = visionToggleEventData(ind2D,ind3D,state,clus,val)
         if nargin == 1
            if ~isstruct(ind2D)
               error('Invalid number of input arguments. If only 1 input, must be a struct with relevant properties.');
            end
            p = fieldnames(ind2D);
            for iP = 1:numel(p)
               if isprop(evtData,p{iP})
                  evtData.(p{iP}) = ind2D.(p{iP});
               end
            end            
            
         elseif nargin == 5
            evtData.ind2D = ind2D;
            evtData.ind3D = ind3D;
            evtData.state = state;
            evtData.clus = clus;
            evtData.val = val;
         else
            error('Invalid number of input arguments.');
         end
      end
   end
   
end