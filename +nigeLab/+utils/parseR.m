function VideoStartGuess = parseR(R,lag,fs,K)
% PARSER   Parse correlation matrix to guess Video Start offset
%
%  VideoStartGuess = nigeLab.utils.ParseR(R,lag,fs);
%  VideoStartGuess = nigeLab.utils.ParseR(R,lag,fs,K);
%
%  --------
%   INPUTS
%  --------
%     R     :     Correlation matrix between neural data beam break and
%                 probability estimates for the presence of grasping paw.
%
%    lag    :     Vector of lag values corresponding to rows of R.
%
%     fs    :     Sample rate of resampled streams that were used in the
%                    cross-correlation.
%
%     K     :     (Optional) Interpolation factor between histogram edges
%  --------
%   OUTPUT
%  --------
%  VideoStartGuess   :  Guessed start time for video with respect to neural
%                       data recording onset.

%% DEFAULTS
if nargin < 4
   K = 12; % Interpolate between histogram edges
end

%%
[~,maxR_i] = max(R);
lagval = lag(maxR_i)/fs;

[nCount,edge] = histcounts(lagval);

[~,idx] = max(nCount);
hvec = linspace(edge(idx),edge(idx+1),K);

[nCount,~,lagbins] = histcounts(lagval,hvec);

[~,idx] = max(nCount);


VideoStartGuess = mode(lagval(lagbins==idx));


end