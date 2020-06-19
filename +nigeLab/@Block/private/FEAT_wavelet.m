function [feat,featName] = FEAT_wavelet(spikes,pars)
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
   featName =  arrayfun(@(ii) sprintf('rand-%.2d',ii),1:K,'UniformOutput',false);
   return;
end

M =size(spikes,2);   % # samples per spike

%% CALCULATES Wavelt decomposition features
      K = pars.NOut;
      cc = zeros(N,floor(M/2));
      for iN=1:N  % Wavelet decomposition (been using 3 scales, 'bior1.3')
         [C,L] = wavedec(spikes(iN,:), ...
            pars.NScales, ...
            pars.LoD,...
            pars.HiD);
         cc(iN,:) = C((sum(L(1:pars.NScales))+2):(end-1));
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
      
   

%% Format Output
feat=zeros(N,K);
for iN=1:N
   for iK=1:K
      feat(iN,iK)=cc(iN,coeff(iK));
   end
end

featName =  arrayfun(@(ii) sprintf('wave-%.2d',ii),1:K,'UniformOutput',false);



end

