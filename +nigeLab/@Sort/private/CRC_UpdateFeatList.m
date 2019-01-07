function CRC_UpdateFeatList(obj)
%% CRC_UPDATEFEATLIST Update the dropdown menu for features if there are 
%                     variable # of features depending on each channel.

ch = obj.Data.UI.ch;
obj.Data.featcomb = flipud(combnk(1:obj.Data.spk.nfeat(ch),2));
obj.Data.featname = cell(obj.Data.nfeatmax,1);
for ii = 1:size(obj.Data.featcomb,1)
   obj.Data.featname{ii,1} = sprintf('x: %s-%d || y: %s-%d',obj.Data.sc,...
      obj.Data.featcomb(ii,1),obj.Data.sc,obj.Data.featcomb(ii,2));
end

% Try and keep it as the same combination for the next channel
obj.FeatureCombos.String = obj.Data.featname;
obj.FeatureCombos.Value = min(obj.Data.feat.this,size(obj.Data.featcomb,1));

CRC_FeatPopCallback(obj.FeatureCombos,nan,obj);
end