function CRC_ToggleVision(src,~,obj)
%% CRC_TOGGLEVISION  Toggle on/off the display of feature plots 

if src.UserData
   src.UserData = false;
   src.EdgeColor = [0.66 0.66 0.66];
   src.LineWidth = 2;
else
   src.UserData = true;
   src.EdgeColor = 'w';
   src.LineWidth = 3;
end

CRC_PlotFeatures(obj);


end