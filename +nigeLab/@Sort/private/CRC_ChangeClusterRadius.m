function CRC_ChangeClusterRadius(src,~,obj)
%% CRC_CHANGECLUSTERRADIUS Callback for slider to change cluster radius

ch = obj.Data.UI.ch;
for iC = 1:obj.Data.NCLUS_MAX
   if abs(obj.Data.cl.num.assign.cur{ch}(iC) - ...
         src.UserData) < eps
      % Update cluster radius
      obj.Data.cl.num.rad{ch}(iC) = src.Value;
      set(src,'TooltipString', ...
         sprintf(['Cluster %d Radius (Standard Deviations)\n'...
            'Min: %d    cur:%3.2g    Max: %d'],iC,...
            obj.Data.SDMIN, src.Value, obj.Data.SDMAX));
   end
end

% Update what spikes belong to what clusters
CRC_UpdateClusterAssignments(obj);
CRC_PlotSpikes(obj);
CRC_PlotFeatures(obj);

% If debugging, update handles in base workspace
if obj.Data.DEBUG
   handles = obj.Data;
   CRC_mtb(handles);
end

end