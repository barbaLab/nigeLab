function CRC_ChannelPopCallback(src,~,obj)
%% CRC_CHANNELPOPCALLBACK  Callback function for CHANNEL popup listbox

% Update current channel #
obj.Data.UI.ch = src.Value;

% Update the Spike Panel title
obj.SpikePanel.Title = src.String(src.Value);

% Default to working with cluster 1
obj.Data.UI.cl = 1;

% Set confirm button weight to bold if not yet pushed
if ~obj.Data.files.submitted(obj.Data.UI.ch)
   obj.Confirm.FontWeight = 'bold';
   obj.Confirm.ForegroundColor = 'k';
   obj.Confirm.BackgroundColor = 'y';
else
   obj.Confirm.FontWeight = 'normal';
   obj.Confirm.ForegroundColor = 'w';
   obj.Confirm.BackgroundColor = 'b';
end

% Plot spike cluster panels and features for this channel.
CRC_PlotSpikes(obj);   
CRC_UpdateFeatList(obj);

CRC_SetCurrentCluster(obj.ClusterLabel{obj.Data.UI.cl,1},nan,obj);

% Get the "first available" channel
obj.Available = nan;
set(obj.ReCluster,'Enable','off');
for iC = 1:obj.Data.NCLUS_MAX
   if isempty(obj.Data.cl.sel.cur{obj.Data.UI.ch,iC})
      if isnan(obj.Available)
         obj.Available = iC;
         set(obj.ReCluster,'Enable','on');
      else
         obj.Available = [obj.Available; iC];
      end
   end
   obj.TagLabels{iC}.Value = obj.Data.cl.tag.val{obj.Data.UI.ch}(iC);
end


% If debugging, update handles in base workspace
if obj.Data.DEBUG
   handles = obj.Data;
   CRC_mtb(handles);
end

end