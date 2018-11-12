function [inspk,K] = wave_features(spikes,pars)
%% WAVE_FEATURES Calculates the spike features
%
%   [inspk,K] = WAVE_FEATURES(spikes,pars)
%
%   --------
%    INPUTS
%   --------
%    spikes     :       N x M matrix of putative spike waveforms. N is the
%                       number of spikes, M is the number of samples in
%                       each spike "snippet."
%
%     pars      :       Parameters structure from SPIKEDETECTCLUSTER.
%
%   --------
%    OUTPUT
%   --------
%     inspk     :       N x K matrix of spike features to be input to the
%                       SPC algorithm. N is the number of spikes, K is the
%                       user-defined number of features (which depends on
%                       the feature-extraction algorithm selected).
%
%      K        :       Number of features extrated.
%
% Modified by: Max Murphy v3.0  01/10/2017 Fixed wavelet decomposition.
%                                          Added interpolation to spikes
%                                          prior to decomposition, using
%                                          cubic spline.
%                                          Fixed method for selecting
%                                          "best" wavelet coefficients.
%                         v2.0  08/03/2017 Added 'ica' and 'mix' options,
%                                          added K as an output for
%                                          convenience.
%                         v1.1  04/07/2017 Changed PRINCOMP to PCA (LINE
%                                          61). Cleaned up syntax and
%                                          removed unused variables. Added
%                                          documentation.

%% GET VARIABLES
N =size(spikes,1);   % # spikes

if N <= 10
   switch pars.FEAT
      case 'wav'
         K = pars.NINPUT;
      case 'pca'
         K = pars.NINPUT;
      case 'ica'
         K = 3;
      case 'mix'
         K = 4;
      otherwise
         K = pars.NINPUT;
   end
   inspk = zeros(N,K); % Just put everything into same cluster
   return;
end

%% INTERPOLATE SPIKES
pars.N_INTERP_SAMPLES = max(size(spikes,2),pars.N_INTERP_SAMPLES);
spikes = interp1(1:size(spikes,2),...
   spikes.',...
   linspace(1,size(spikes,2),pars.N_INTERP_SAMPLES),...
   'spline').';
M =size(spikes,2);   % # samples per spike

%% CALCULATES FEATURES
switch pars.FEAT
   case 'wav' % Currently the best option [8/11/2017 - MM]
      K = pars.NINPUT;
      cc = zeros(N,floor(pars.N_INTERP_SAMPLES/2));
      for iN=1:N  % Wavelet decomposition (been using 3 scales, 'bior1.3')
         [C,L] = wavedec(spikes(iN,:), ...
            pars.NSCALES, ...
            pars.WAVELET);
         cc(iN,:) = C((sum(L(1:pars.NSCALES))+2):(end-1));
      end
      
      % Remove columns (features) that are mostly 0
      aux = [];
      for iC = 1:size(cc,2)
         if sum(abs(cc(:,iC))<eps)<0.1*size(cc,1)
            aux = [aux, cc(:,iC)]; %#ok<AGROW>
         end
      end

      % Normalize features
      cc = cc - mean(cc,1);
      cc = cc./std(cc,[],1);
      
      % Find kurtosis peaks in the time-series distribution
      y = kurtosis(cc);
      [k_pk,k_loc] = findpeaks(y);
      try
         [~,ind] = sort(k_pk,'descend');
         loc = k_loc(ind);
      catch
         loc = [];
      end
      
      if (numel(loc) >= K)
         coeff = loc(1:K);
      else  % Not enough coefficients, look for skewness
         y = skewness(cc);
         try
            [p_pk, p_loc] = findpeaks(y);
            [p_pk,ind] = sort(p_pk,'descend');
            p_loc = p_loc(ind);
         catch
            p_loc = [];
         end
                 
         try
            [n_pk, n_loc] = findpeaks(-y);
            [n_pk,ind] = sort(n_pk,'descend');
            n_loc = n_loc(ind);
         catch
            n_loc = [];
         end
         
         % Decide which one to include first
         if ~isempty(p_loc) && ~isempty(n_loc)
            flag = p_loc(1) > n_loc(1);
         elseif isempty(p_loc) && isempty(n_loc)
            flag = true;
         else
            if isempty(p_loc)
               flag = false;
            elseif isempty(n_loc)
               flag = true;
            end   
         end
         
         % Add coeffs based on skew until enough coefficients
         pk_count = 0;
         while ((pk_count <= max(numel(p_pk),numel(n_pk))) && ...
               (numel(loc) < K))
            pk_count = pk_count + 0.5;
            
            if (flag && (pk_count <= numel(p_pk)))
               loc = [loc, p_loc(ceil(pk_count))];          %#ok<AGROW>
            elseif (~flag && (pk_count <= numel(n_pk)))
               loc = [loc, n_loc(ceil(pk_count))];          %#ok<AGROW>
            end
            loc = unique(loc);
         end
         
         % If still need coefficients, add random ones
         if numel(loc) < K
            vec = 1:size(cc,2);
            vec = setdiff(vec,loc);
            n_remain = K - numel(loc);
            
            loc = [loc, vec(randperm(numel(vec),n_remain))];
         end
         
         coeff = loc(1:K);
      end
      
   case 'pca' % Top K PCA features
      K = pars.NINPUT;
      [~,cc] = pca(spikes);
      coeff=1:pars.NINPUT;
      
   case 'ica' % Kurtosis-based ICA method
      K = 3;
      Z = fastICA(spikes.',K);
      cc = Z.';
      coeff = 1:K;
      
   case 'mix' % Combine peak-width, p2pamp, ICAs
      K = 4;
      spikes_interp = interp1((0:(size(spikes,2)-1))/pars.FS, ...
         spikes.', ...
         linspace(0,(size(spikes,2)-1)/pars.FS, ...
         pars.N_INTERP_SAMPLES));
      
      spikes_interp = spikes_interp.';
      
      [amax,imax] = max(spikes_interp,[],2);
      [amin,imin] = min(spikes_interp,[],2);
      Z = fastICA(spikes_interp.',2);
      cc = [amax - amin,imax-imin,Z.'];
      coeff = 1:K;
end

%% CREATES INPUT MATRIX FOR SPC
inspk=zeros(N,K);
for iN=1:N
   for iK=1:K
      inspk(iN,iK)=cc(iN,coeff(iK));
   end
end

end

