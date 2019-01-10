function CRC_MakeDistanceExclusions(obj,ch,clus,these)
%% CRC_MAKEDISTANCEEXCLUSIONS Exclude spikes with deviant features.

switch obj.Data.DISTANCE_METHOD
   case 'L2'
      if clus > 1
         obj.Data.spk.include.cur{ch}(these) = ...
                  sqrt(sum(obj.Data.spk.feat{ch}(these,:).^2 - ...
                  obj.Data.cl.num.centroid{ch,clus}.^2,2)) ...
                  < obj.Data.cl.num.rad{ch,1}(clus);
      end
      
   otherwise
      warning([obj.Data.DISTANCE_METHOD 'not supported. Switching to L2']);
      obj.Data.DISTANCE_METHOD = 'L2';
      CRC_MakeDistanceExclusions(obj,ch,these);
end

end