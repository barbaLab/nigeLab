classdef (ConstructOnLoad) saveData < event.EventData
% SAVEDATA  Event for to signal saving of data has begun
%
%  Tipycally issued during spike sorting (Sort Interface)
%
%  ASSIGNCLUS Properties:
%
%     ch  -  Subscripts of channels to save
%
%  ASSIGNCLUS Methods:
%     assignClus - Event data constructor. 
%        evt = nigeLab.evt.assignClus(ch);

   properties
       ch                       % Subscripts of channels to save
   end

   methods
      function evt = saveData(ch)
         % SAVEDATA  Cluster assignment event class constructor.
         %
         %  evt = nigeLab.evt.assignClus(subs,class,otherClassToUpdate);
         %
         %  Issued when a subset of spikes from one cluster is assigned to 
         %  a new cluster, typically in the `nigeLab.Sort` spike sorting 
         %  interface
         
         evt.ch = ch;
      end
   end
   
end