function varargout = AutoClustering(varargin)
%AutoClustering  Sets default parameters for AutoClustering operation
%
%  par = nigeLab.defaults.AutoClustering();

%% PARAMS YOU MIGHT CHANGE
pars = struct;
pars.MethodName = 'KMEANS'; % Can be: 'KMEANS' or 'SPC'
pars.NMaxClus = 9;          % Maximum # of clusters

%% UNLIKELY TO CHANGE
% Parameters for each type stored as individual files in ~/+Autoclusters
AutoClustPath = fullfile(nigeLab.utils.getNigelPath,...
   '+nigeLab','+defaults','+AutoClustering');
% Load all the method-specific parameters:
AutoClusteringConfigFiles = dir(fullfile(AutoClustPath,'*.m'));
for ff = AutoClusteringConfigFiles(:)'
   parName = ff.name(1:end-2); % dropping .m
   pars.(parName) = eval(sprintf('nigeLab.defaults.AutoClustering.%s',...
      parName));
end

%% Parse output
if nargin < 1
   varargout = {pars};
else
   varargout = cell(1,nargin);
   f = fieldnames(pars);
   for i = 1:nargin
      idx = ismember(lower(f),lower(varargin{i}));
      if sum(idx) == 1
         varargout{i} = pars.(f{idx});
      end
   end
end

end