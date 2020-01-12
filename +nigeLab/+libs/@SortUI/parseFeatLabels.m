function featLabel = parseFeatLabels(obj)
%PARSEFEATLABELS  Get all possible 2D scatter pairwise labels
%
%  featLabel = sortObj.parseFeatLabels();
%  --> featLabel depends on features extracted during `doSpikeDetection`
%      method of `nigelObj`
%
% Get feature name combinations for all possible 2D scatter
% combinations, which will be used on the "features" plot axis to
% visualize separation of clusters.
featLabel = cell(obj.feat.n,1);
for i = 1:obj.feat.n
   featLabel{i} = sprintf('x: %s || y: %s',...
      obj.feat.name{obj.feat.combo(i,1)},...
      obj.feat.name{obj.feat.combo(i,2)});
   
end
end