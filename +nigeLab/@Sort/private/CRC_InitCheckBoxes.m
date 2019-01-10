function CRC_InitCheckBoxes(obj)
%% CRC_INITCHECKBOXES   Initialize UI checkbox states for using L2 Norm

ch = obj.Data.UI.ch;
for iC = 1:obj.Data.NCLUS_MAX
   % Initialize cluster radius tickboxes (inf = don't restrict)
   if isinf(obj.Data.cl.num.rad{ch}(iC))
      obj.RadiusEnable{iC,1}.Value = 0;
      obj.SetRadius{iC,1}.Enable = 'inactive';
   else
      obj.RadiusEnable{iC,1}.Value = 1;
      obj.SetRadius{iC,1}.Enable = 'on';
      obj.SetRadius{iC,1}.Value = obj.Data.cl.num.rad{ch}(iC);
   end
end

end