function par = AutoClustering()
%AutoClustering  Sets default parameters for AutoClustering operation
%
%  par = nigeLab.defaults.AutoClustering();

%% PARAMS YOU MIGHT CHANGE
par.MethodName = 'KMEANS'; % Can be: 'KMEANS' or 'SPC'
par.NMaxClus = 9;          % Maximum # of clusters

%% UNLIKELY TO CHANGE
% Parameters for each type stored as individual files in ~/+Autoclusters
AutoClustPath = fullfile(nigeLab.utils.getNigelPath,...
   '+nigeLab','+defaults','+AutoClustering');
% Load all the method-specific parameters:
AutoClusteringConfigFiles = dir(fullfile(AutoClustPath,'*.m'));
for ff = AutoClusteringConfigFiles(:)'
   parName = ff.name(1:end-2); % dropping .m
   par.(parName) = eval(sprintf('nigeLab.defaults.AutoClustering.%s',...
      parName));
end

end