function feat = FEAT_pca(spikes,pars)
%% WAVEFEATURES Calculates the spike features
%
%   [inspk,K] = WAVEFEATURES(spikes,pars)
%
%   --------
%    INPUTS
%   --------
%    spikes     :       N x M matrix of putative spike waveforms. N is the
%                       number of spikes, M is the number of samples in
%                       each spike "snippet."
%
%     pars      :       Parameters structure from  feature decomposition.
%
%   --------
%    OUTPUT
%   --------
%     feat     :       N x K matrix of spike features to be input to the
%                       SPC algorithm. N is the number of spikes, K is the
%                       user-defined number of features (which depends on
%                       the feature-extraction algorithm selected).
%
%
% Reformatted for use in nigeLab by FB 2020/06/19 (what a great year btw)
% Based on previous design by Max Murphy


%% GET VARIABLES
N =size(spikes,1);   % # spikes

if N <= 10
   K = pars.NOut;
   feat = rand(N,K); % Just put everything into same cluster
   return;
end

[~, SCORE, LATENT] = pca(spikes);
if isinf(coeff.ExplVar)
    K = pars.NOut;
else
    K = find( cumsum(LATENT)./sum(LATENT) > pars.ExplVar,1);
end
%% CREATES INPUT MATRIX FOR SPC
feat = SCORE(:,1:K);


end

