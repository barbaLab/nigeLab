function class_out = ReduceClusters(spikes,class_in,pars,varargin)
%% REDUCECLUSTERS   Reduce over-clustering from GMM/SPC
%
%  class_out = REDUCECLUSTERS(spikes,class_in,'NAME',value,...)
%
% By: Max Murphy  v1.0  01/09/2018  Original version (R2017a)


%% DEFAULTS
% T-sne
TSNE_DIM = 2;       % Dimensionality from t-distributed stochastic neighborhood embedding (tsne)
EXAGGERATION = 5;   % Exaggeration for t-sne local comparisons
PERPLEXITY = 100;   % Perplexity of t-sne data (related to knn)
MIN_CLASS_IN = 250; % Min. # classes to perform t-sne

% Clustering
CLUSTER_METHOD = 'gmm'; % Can be 'gmm' or 'spc'
GMM_K = 2;              % Possible number of gaussian mixture components
GMM_SHARED_COV = false;    % If false, each GMM component has own cov mat
GMM_COV_TYPE = 'full';     % 'full' or 'diagonal'
GMM_MAX_ITERATIONS = 5000; % Max. iterations to fit GMM components

%% SPC PARAMETERS
if exist('pars','var')==0
   pars = init_params;
else
   if isempty(pars)
      pars = init_params;
   end   
end

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% MAKE TEMPLATES FROM SPIKES OR FEATURES BELONGING TO A CLASS
templates = zeros(max(class_in)+1,size(spikes,2));

for ii = 0:max(class_in)
   if (sum(class_in==ii)>0)
      templates(ii+1,:) = nanmean(spikes(class_in==ii,:),1);
   end
end

if ((size(templates,1)<MIN_CLASS_IN) && strcmpi(CLUSTER_METHOD,'gmm'))
   CLUSTER_METHOD = 'spc';
   fprintf(1,'\n\t!\tOnly %d classes, switching to SPC for cluster reduction !\n',size(templates,1));
end
         
%% DO CLUSTERING
switch lower(CLUSTER_METHOD)
   case 'spc'
      fprintf(1,'\n\t->\tReducing clusters using SPC <-\n');
      class = DoSPC(templates,pars,'MAIN',true);
      
   case 'gmm'
      % Use t-sne to reduce dimensionality
      tic;
      fprintf(1,'\n\t->\tReducing %d features to %d dimensions using t-sne <-\n',size(templates,2),TSNE_DIM);
      ppx = min(PERPLEXITY,size(templates,1));
      feat = tsne(templates,...
                  'Exaggeration',EXAGGERATION,...
                  'NumDImensions',TSNE_DIM,...
                  'Perplexity',ppx);
      fprintf(1,'\t\t'); 
      toc; fprintf(1,'\n');
      
      tic;
      fprintf(1,'\n\t->\tReducing clusters using GMM <-\n');
      
      % Set number of iterations
      opts = statset('MaxIter',GMM_MAX_ITERATIONS); 
      
      % Pre-allocate
      gmfit = cell(numel(GMM_K),1);
      a = nan(numel(GMM_K),1);
      
      % Loop through different numbers of GMM components
      for iK = 1:numel(GMM_K)
         try
            gmfit{iK} = fitgmdist(feat,GMM_K(iK), ...
               'CovarianceType',GMM_COV_TYPE,...
               'SharedCovariance',GMM_SHARED_COV, ...
               'Options',opts);
            a(iK) = gmfit{iK}.AIC;
         catch % Catch case of ill-conditioned covariance matrix
            gmfit{iK} = nan;
            a(iK) = inf;
         end
      end
      if any(~isinf(a))
         [~,ind] = nanmin(a); % Use the one with lowest AIC
         class = cluster(gmfit{ind},feat);
      else
         class = ones(size(feat,1),1);
      end
      fprintf(1,'\t\t'); 
      toc; fprintf(1,'\n\n');
   otherwise
      error('CLUSTER_METHOD (currently: %s) is not supported.',...
         CLUSTER_METHOD);
end

%% ASSIGN CLASS TO EACH SPIKE OR FEATURE THAT COMPOSE A TEMPLATE
class_out = zeros(size(class_in));
for ii = 0:max(class_in)
   class_out(class_in==ii) = class(ii+1);
end

   function spc_pars = init_params
      spc_pars = struct;
      spc_pars.SPC_VERBOSE = true;
      spc_pars.SPC_TEMPLATE = 'center';
      spc_pars.SPC_DISCARD_EXTRA_CLUS = false;         % If true, don't do template match
      spc_pars.SPC_FNAME_IN = 'tmp_data';              % Input name for cluster.exe
      spc_pars.SPC_FNAME_OUT = 'data_tmp_curr.mat';    % Read-out from cluster.exe
      spc_pars.SPC_RANDOMSEED = 147;                   % Random seed
      spc_pars.SPC_RANDOMIZE = true;                  % Use random subset for SPC?
      spc_pars.SPC_ABS_KNN = 3;                       % Absolute (min) K-Nearest Neighbors
      spc_pars.SPC_REL_KNN = 0.0001;                   % Relative K-Nearest Neighbors
      spc_pars.SPC_SWCYC = 200;                   % Swendsen-Wang cycles
      spc_pars.SPC_TSTEP = 0.001;                 % Increments for vector of temperatures
      spc_pars.SPC_MAXTEMP = 0.300;               % Max. temperature for SPC
      spc_pars.SPC_TEMPLATE_PROP = 0.25;          % Proportion for SPC before starting template match
      spc_pars.SPC_MINTEMP = 0.000;               % Min. temperature for SPC
      spc_pars.SPC_NMINCLUS = 7;                  % Absolute minimum cluster size diff
      spc_pars.SPC_RMINCLUS = 0.006;              % Relative minimum cluster size diff
      spc_pars.SPC_MAX_SPK = 1000;                % Max. # of spikes per SPC batch
      spc_pars.SPC_TEMPSD = 2.00;                 % # of SD for template matching
      spc_pars.SPC_NCLUS_MIN = 3;                % For use with 'neo' option
      spc_pars.SPC_NCLUS_MAX = 300;              % Max. # of clusters
      spc_pars.SPC_TEMP_METHOD = 'neo';           % Method of finding temperature
      
   end

end