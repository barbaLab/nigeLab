function CRC_PlotSpikes(obj)
%% CRC_PLOTSPIKES Plot spikes in CRC UI for each cluster.

% Get ALL spikes from this channel
ch = obj.Data.UI.ch;
obj.SpikeImage = CRC_SpikeImage(obj);

% Loop through and plot spikes
for iC = 1:obj.Data.NCLUS_MAX
   
   % Isolate this subset of spikes
   spk_ind= find(obj.Data.cl.num.class.cur{ch}==iC & ...
                 obj.Data.spk.include.cur{ch});
   
   % Get the corresponding cluster # (may have been updated)
   tempCLNUM = obj.Data.cl.num.assign.cur{ch}(iC);
   
   % Dummy variable for graphics UserData
   tempUD = [tempCLNUM,... % "Current" assigned cluster
      iC, ...              % Indexing placeholder
      tempCLNUM];          % "Previous" assigned cluster
   
   % Assign UserData for this axes
   obj.SpikePlot{iC,1}.UserData = tempUD; 
   
   % Update this label
   if iC <= 1
      str = sprintf('Ch %d OUT        N = %d',...
         ch,size(obj.SpikeImage.Clusters{iC},1));
      obj.ClusterLabel{iC}.String = str;
      
   else
      str = sprintf('Ch %d Cluster %d        N = %d',...
         ch,iC-1,size(obj.SpikeImage.Clusters{iC},1));
      obj.ClusterLabel{iC}.String = str;
   end
end



end