function CRC_EnableClusterRadiusRestrict(src,~,obj)
%% CRC_ENABLECLUSTERRADIUSRESTRICT Checkbox callback for enabling L2 Norm

% Get current channel
ch = obj.Data.UI.ch;

if src.Value==1
   obj.SetRadius{src.UserData,1}.Enable = 'on';
   for iC = 1:obj.Data.NCLUS_MAX
      if abs(obj.Data.cl.num.assign.cur{ch}(iC)- ...
            src.UserData) < eps
         CRC_ChangeClusterRadius(obj.SetRadius{src.UserData},nan,obj);
      end
   end
else
   obj.SetRadius{src.UserData,1}.Enable = 'inactive';
   for iC = 1:obj.Data.NCLUS_MAX
      if abs(obj.Data.cl.num.assign.cur{ch}(iC)- ...
            src.UserData) < eps
         obj.Data.cl.num.rad{ch}(iC) = inf;
      end
   end
end

CRC_UpdateClusterAssignments(obj);
% CRC_PlotSpikes(obj);
CRC_PlotFeatures(obj);

% If debugging, update obj.Data in base workspace
if obj.Data.DEBUG
   handles = obj.Data;
   CRC_mtb(handles);
end


end