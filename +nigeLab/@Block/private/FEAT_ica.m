function feat = FEAT_ica(spikes,pars)
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
%     pars      :       Parameters structure for feature decomposition.
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
error('nigeLab:WIP','ICA based decomposition is not yet implemented.\nSorry, the cat ate my homework...');

% N =size(spikes,1);   % # spikes
% 
% if N <= 10
%     K = 3;
%     feat = zeros(N,K); % Just put everything into same cluster
%    return;
% end
% 
% 
% M =size(spikes,2);   % # samples per spike
% 
% %% CALCULATES FEATURES
%       K = 3;
%       Z = fastICA(spikes.',K);
%       cc = Z.';
%       coeff = 1:K;
%       
%    
% 
% %% CREATES INPUT MATRIX FOR SPC
% feat=zeros(N,K);
% for iN=1:N
%    for iK=1:K
%       feat(iN,iK)=cc(iN,coeff(iK));
%    end
% end

end

