function CRC_ZoomSlide(src,~,obj)
%% CRC_ZOOMSLIDE  Callback function for zooming in or out on axes

clu = obj.Data.UI.cl;
obj.Data.UI.zm(clu) = src.Value;
obj.Data.UI.spk_ylim(clu,:) = obj.Data.SPK_YLIM.*(100/obj.Data.UI.zm(clu));
               
obj.SpikeImage.CRC_UpdateImage(clu);
obj.SpikeImage.CRC_ReDraw(clu,obj.SpikePlot{clu}.UserData(1));


% Update tracked assignments and features
CRC_UpdateClusterAssignments(obj);
CRC_PlotFeatures(obj);

% If debugging, update handles in base workspace
if obj.Data.DEBUG
   handles = obj.Data;
   CRC_mtb(handles);
end

end