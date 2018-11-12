function clu = DoTemplateClustering(features,pw,pp,pars)
%% DOTEMPLATECLUSTERING  Does a template-based clustering algorithm (GMM)
%
%  clu = DOTEMPLATECLUSTERING(features,pk,dt);
%  clu = DOTEMPLATECLUSTERING(features,pk,dt,pars);
%
%  --------
%   INPUTS
%  --------
%  features    :     N x K array of features, where N is the number of
%                          observations (spikes), and K is the number of
%                          features per observation (for example, number of
%                          wavelet coefficients)

%
%     pw       :     Absolute value of negative-going peak. (pk)
%
%     pp       :     Difference (in samples) of time between this and next
%                    spike. (dt)
%
%    pars      :     (Optional) struct containing clustering parameters. If
%                               not specified, uses default parameters.
%
%  --------
%   OUTPUT
%  --------
%    clu       :     Cluster class assigned to each spike. Used as a
%                    default cluster assignment to assist in manual
%                    curation using CRC.
%
% By: Max Murphy  v1.0  01/08/2018  Original version (R2017a)

%% DEFAULTS
if exist('pars','var')==0
   pars = struct;
   % Relevant parameter properties:
   pars.GMM_K = 4;
   pars.GMM_SIGMA = 'diagonal';
   pars.GMM_SHARED_COV = false;
   pars.GMM_MAX_ITERATIONS = 150;
end

%% NORMALIZE AND CONCATENATE FEATURES
dt = (log(pp)-mean(log(pp)))./std(log(pp));
pk = (pw-mean(pw))./std(pw);
Z = [features, dt.', pk.'];
nf = size(features,2);

% Get list of feature combinations for Mixture of Gaussians
comb_list = nchoosek(1:size(Z,2),2);
nCombos = size(comb_list,1);
clu = zeros(size(Z,1),nCombos);

options = statset('MaxIter',pars.GMM_MAX_ITERATIONS); 

for iZ = 1:nCombos % Loop through pairs of features and classify
   fprintf(1,'\n\t\tFitting GMM to feature pair %d of %d...\n',iZ,nCombos);
   X = Z(:,comb_list(iZ,:));
   b = nan(numel(pars.GMM_K),1);
   gmfit = cell(numel(pars.GMM_K),1);
   for iK = 1:numel(pars.GMM_K)
      try
         gmfit{iK} = fitgmdist(X,pars.GMM_K(iK), ...
            'CovarianceType',pars.GMM_SIGMA,...
            'SharedCovariance',pars.GMM_SHARED_COV, ...
            'Options',options);
         b(iK) = gmfit{iK}.BIC;
      catch % Catch case of ill-conditioned covariance matrix
         gmfit{iK} = nan;
         b(iK) = inf;
      end
   end
   if any(~isinf(b))
      [~,ind] = nanmin(b);
      clu(:,iZ) = cluster(gmfit{ind},X);
   else
      clu(:,iZ) = ones(size(Z,1),1);
   end
end


end