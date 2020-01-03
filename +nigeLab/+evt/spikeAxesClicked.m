classdef (ConstructOnLoad) spikeAxesClicked < event.EventData
%SPIKEAXESCLICKED   Event for clicking on a spike axes
%
%  Issued when the user clicks on a graphical axes object that is related
%  to a given spike cluster index; typically mediated by
%  `nigeLab.libs.SpikeImage`, which has all the spike axes in it.
%
%  SPIKEAXESCLICKED Properties:
%  
%     visible  --  0: Scatter is hidden (unchecked); 1: Scatter is shown
%  
%     class  --  Cluster class index (`nigeLab.libs.DiskData` .Value prop)
%
%  
%  SPIKEAXESCLICKED Methods:
%
%     spikeAxesClicked  --  Event data class constructor
%        evt = nigeLab.evt.spikeAxesClicked(class,visible);

   properties
      visible % 0: Scatter is hidden (unchecked); 1: Scatter is shown
      class   % Cluster class index
   end
   
   methods
      function evt = spikeAxesClicked(class,visible)
         %SPIKEAXESCLICKED  Constructor for spike axes click event data
         %
         %  evt = nigeLab.evt.spikeAxesClicked(class,visible);
         
         evt.class = class;
         evt.visible = visible;
      end
   end
   
end