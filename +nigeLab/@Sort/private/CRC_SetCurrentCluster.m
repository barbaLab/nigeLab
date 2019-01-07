function CRC_SetCurrentCluster(src,~,obj)
%% CRC_SETCURRENTCLUSTER  Radiobutton UI callback for toggling cluster

% Get current channel
ch = obj.Data.UI.ch;

% Update value of current cluster
obj.Data.UI.cl = src.UserData(1);
obj.ZoomSlider.BackgroundColor = obj.Data.COLS{obj.Data.UI.cl};
obj.ZoomSlider.Value = obj.Data.UI.zm(obj.Data.UI.cl);

% Highlight spikes in panels assigned to current cluster
for iC = 1:obj.Data.NCLUS_MAX
   if abs(obj.Data.cl.num.assign.cur{ch}(iC)-...
            obj.Data.UI.cl) <eps
      set(obj.SpikePlot{iC},'XColor','w');
      set(obj.SpikePlot{iC},'YColor','w');
      if iC==1
         set(obj.ClusterLabel{iC},'Color','k');
         set(obj.ClusterLabel{iC},'BackgroundColor','w');
      else
         set(obj.ClusterLabel{iC},'Color','k');
         set(obj.ClusterLabel{iC},'BackgroundColor',obj.Data.COLS{iC});
      end
   else
      set(obj.SpikePlot{iC},'XColor','k');
      set(obj.SpikePlot{iC},'YColor','k');
      set(obj.ClusterLabel{iC},'Color',[0.66 0.66 0.66]);
      set(obj.ClusterLabel{iC},'BackgroundColor',[0.06 0.06 0.06]);
   end
end

% If debugging, update obj.Data in base workspace
if obj.Data.DEBUG
   handles = obj.Data;
   CRC_mtb(handles);
end

end