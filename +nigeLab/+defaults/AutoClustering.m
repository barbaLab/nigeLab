function par = AutoClustering()
%% defaults.AutoClustering  Sets default parameters for AutoClustering operation
%
%  par = nigeLab.defaults.AutoClustering();
%
% By: MAECI 2019 collaboration (Federico Barban & Max Murphy)

par.MethodName = 'KMEANS';
par.NMaxClus = 9;

%% Load all the method specific parameters stored as individual files in ~/+Autoclusters
AutoClustPath = fullfile(nigeLab.utils.getNigelPath,'+nigeLab','+defaults','+AutoClustering');
AutoClusteringConfigFiles = dir(fullfile(AutoClustPath,'*.m'));

for ff = AutoClusteringConfigFiles(:)'
    parName = ff.name(1:end-2); % dropping .m
    par.(parName) = eval(sprintf('nigeLab.defaults.AutoClustering.%s',parName));
end

%% DO ERROR PARSING
%  not needed at this time
end