function CRC_UpdateClusterAssignments(obj)
%% CRC_UPDATECLUSTERASSIGNMENTS  Update UI Data with new cluster assignment

set(obj.Figure,'Pointer','watch');

ch = obj.Data.UI.ch;

% Go through all cluster lists and update which spikes belong
for iC = 1:obj.Data.NCLUS_MAX
   obj.Data.cl.num.class.cur{ch}(obj.Data.cl.sel.cur{ch,iC})=iC;
   CRC_UpdateTag(obj.TagLabels{iC},nan,obj);
end


% With all "selections" re-arranged, go through and make exclusions
obj.Available = nan;
set(obj.ReCluster,'Enable','off');

for iC = 1:obj.Data.NCLUS_MAX
   these = obj.Data.cl.num.class.cur{ch}==iC;
   if sum(these)<1
      obj.Data.cl.num.centroid{ch,iC} = nan(1,...
         obj.Data.spk.nfeat(ch));
   else
      obj.Data.cl.num.centroid{ch,iC} = median(...
         obj.Data.spk.feat{ch}(these,:));  
      
      % In the future, add different distance metrics
      CRC_MakeDistanceExclusions(obj,ch,iC,these);
   end
   
   % Update which clusters are "available"
   if isempty(obj.Data.cl.sel.cur{ch,iC})
      if isnan(obj.Available)
         obj.Available = iC;
         set(obj.ReCluster,'Enable','on');
      else
         obj.Available = [obj.Available; iC];
      end
   end
end

% OUT cluster does not have restrictions
obj.Data.cl.sel.cur{ch,1} = sort([obj.Data.cl.sel.cur{ch,1}; ...
   find(~obj.Data.spk.include.cur{ch})],...
   'ascend');
obj.Data.spk.include.cur{ch}(~obj.Data.spk.include.cur{ch})=true;


for iC = 1:obj.Data.NCLUS_MAX
   % Update cluster assignments
   obj.SpikeImage.Clusters{iC} = obj.SpikeImage.CRC_UpdateAssignments(iC);

   % Update actual image to plot
   [obj.SpikeImage.C{iC}, obj.SpikeImage.Assignments{iC}] = ...
      obj.SpikeImage.CRC_UpdateImage(iC);

   % Redraw this axis
   obj.SpikeImage.CRC_ReDraw(iC,obj.SpikePlot{iC}.UserData(1));

   % Update this label
   if iC <= 1
      str = sprintf('OUT    | %s      N = %d',...
         obj.TagLabels{iC}.String{obj.TagLabels{iC}.Value},...
         size(obj.SpikeImage.Clusters{iC},1));
         obj.ClusterLabel{iC}.String = str;

   else
      str = sprintf('CLU %d | %s      N = %d',...
         iC-1, ...
         obj.TagLabels{iC}.String{obj.TagLabels{iC}.Value},...
         size(obj.SpikeImage.Clusters{iC},1));
      obj.ClusterLabel{iC}.String = str;
   end
end

set(obj.Figure,'Pointer','arrow');

end