classdef (ConstructOnLoad) toggleClusterVisible < event.EventData
%TOGGLECLUSTERVISIBLE  Event for toggling the visibility of a cluster
%
%  This event is typically issued during spike sorting when the checkbox of
%  a particular SpikeImage axes is toggled on or off. This removes the
%  corresponding points from being plotted on all the features axes, and
%  prevents them from being "circled" during any convex hull polygon
%  "cutting" that might otherwise trigger a change of clusters for those
%  spikes.
%
%  TOGGLECLUSTERVISIBLE Properties:
%
%     ind2D  --  Logical indexing vector to elements of 2D feature plot
%                 that belong to the cluster indexed by evt.clus
%
%     ind3D  --  Logical indexing vector to elements of 3D feature plot
%                 that belong to the cluster indexed by evt.clus
%
%     state  -- Visible state ('on' or 'off')
%
%     clus  --  Index of spike "class" (`nigeLab.libs.DiskData.Value`)
%
%     val  --  If > 0, state == 'on'
%
%  
%  TOGGLECLUSTERVISIBLE Methods:
%
%     toggleClusterVisible  -- Class constructor for vision event.
%        evt = ...
%           nigeLab.evt.toggleClusterVisible(ind2D,ind3D,state,clus,val);
%
%           or
%
%        togStruct = struct('ind2D',ind2D,'ind3D',ind3D,state,clus,val);
%        evt = nigeLab.evt.toggleClusterVisible(togStruct);

   properties (Access = public)
      ind2D       % Indexing vector of 2D scatter objects belonging to clus
      ind3D       % Indexing vector of 3D scatter objects belonging to clus
      state  char % Visible state ('on' or 'off')
      clus double % Index of spike "class" (`nigeLab.libs.DiskData.Value`)
      val         % If > 0, state == 'on'
   end
   
   methods (Access = public)
      function evt = toggleClusterVisible(ind2D,ind3D,state,clus,val)
         %TOGGLECLUSTERVISIBLE  Constructor for visibility event data
         %
         %  evt = ...
         %    nigeLab.evt.toggleClusterVisible(ind2D,ind3D,state,clus,val);
         %
         %  or
         %
         %  togStruct = struct('ind2D',ind2D,'ind3D',ind3D,state,clus,val);
         %  evt = nigeLab.evt.toggleClusterVisible(togStruct);
         
         switch nargin
            case 1 % If only 1, then must be struct
               if ~isstruct(ind2D)
                  error(['nigeLab:' mfilename ':BadInputType2'],...
                     ['Invalid number of input arguments.\n' ...
                      'If only 1 input, ''ind2D'' input argument must be ' ...
                      'a struct with the following fields:\n' ...
                      '{''ind3D'', ''state'', ''clus'', ''val''}']);
               end
               p = fieldnames(ind2D);
               for iP = 1:numel(p)
                  if isprop(evt,p{iP})
                     evt.(p{iP}) = ind2D.(p{iP});
                  end
               end            
            
            case 5
               evt.ind2D = ind2D;
               evt.ind3D = ind3D;
               evt.state = state;
               evt.clus = clus;
               evt.val = val;
            otherwise
               error(['nigeLab:' mfilename ':BadNumberInputs'],...
                  'Invalid number of input arguments (%g)',nargin);
         end
      end
   end
   
end