function CRC_FeatPopCallback(src,~,obj)
%% CRC_FEATPOPCALLBACK  Callback function from FEATURES popup box
obj.Data.feat.this = src.Value;
CRC_PlotFeatures(obj);
CRC_ResetFeatureAxes(obj);
end