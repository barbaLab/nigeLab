function CRC_UpdateTag(src,~,obj)
%% CRC_UPDATETAG  Updates tag associated with each spike cluster

% Get channel
ch = obj.Data.UI.ch;

% Set cluster tag for this channel/cluster
obj.Data.cl.tag.name{ch}(obj.Data.cl.num.class.cur{ch}==src.UserData) = ...
   src.String(src.Value);

% Set memory of uicontrol value in case you come back to this channel later
obj.Data.cl.tag.val{ch}(src.UserData) = src.Value;

% Update the cluster label in SpikePanel
if src.UserData <= 1
   str = sprintf('OUT    | %s      N = %d',...
      obj.TagLabels{src.UserData}.String{obj.TagLabels{src.UserData}.Value},...
      size(obj.SpikeImage.Clusters{src.UserData},1));
   obj.ClusterLabel{src.UserData}.String = str;
   
else
   str = sprintf('CLU %d | %s      N = %d',...
      src.UserData-1, ...
      obj.TagLabels{src.UserData}.String{obj.TagLabels{src.UserData}.Value},...
      size(obj.SpikeImage.Clusters{src.UserData},1));
   obj.ClusterLabel{src.UserData}.String = str;
end



end