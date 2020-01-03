classdef (ConstructOnLoad) assignClus < event.EventData
% ASSIGNCLUS  Event for assigning subset of spikes to a cluster
%
%  Issued when a subset of spikes from one cluster is assigned to a
%  new cluster, typically in the `nigeLab.Sort` spike sorting interface
%
%  ASSIGNCLUS Properties:
%
%     subs  -  Subscripts of spikes to assign
%
%     class -  Class assignment ("Value" property of DiskData)
%  
%     otherClassToUpdate  -  For interface, use this to remove the spikes
%        from a cluster with the given class index.
%
%  ASSIGNCLUS Methods:
%     assignClus - Event data constructor. 
%        evt = nigeLab.evt.assignClus(subs,class,otherClassToUpdate);

   properties
      subs                       % Subscripts of spikes to assign
      class                      % Class assignment index
      otherClassToUpdate = nan;  % Other class to update in addition
   end

   methods
      function evt = assignClus(subs,class,otherClassToUpdate)
         % ASSIGNCLUS  Cluster assignment event class constructor.
         %
         %  evt = nigeLab.evt.assignClus(subs,class,otherClassToUpdate);
         %
         %  Issued when a subset of spikes from one cluster is assigned to 
         %  a new cluster, typically in the `nigeLab.Sort` spike sorting 
         %  interface
         
         evt.subs = subs;
         if numel(class) < numel(subs)
            if numel(class) == 1
               evt.class = repmat(class,numel(subs),1);
            else
               error('Class assignment must have same number as subset index');
            end
         else
            evt.class = class;
            
         end
         
         if nargin < 3
            return;
         end
         
         evt.otherClassToUpdate = reshape(otherClassToUpdate,1,...
            numel(otherClassToUpdate));
         
      end
   end
   
end