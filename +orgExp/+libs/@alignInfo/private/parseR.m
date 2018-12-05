function VideoStartGuess = parseR(R,lag,varargin)
%% PARSER   Parse correlation matrix to guess Video Start offset
%
%  VideoStartGuess = PARSER(R,lag,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     R     :     Correlation matrix between neural data beam break and
%                 probability estimates for the presence of grasping paw.
%
%    lag    :     Vector of lag values corresponding to rows of R.
%
%  varargin :     (Optional) 'NAME',value input argument pairs.
%                 -> 'FS' (def: 125 Hz)
%  --------
%   OUTPUT
%  --------
%  VideoStartGuess   :  Guessed start time for video with respect to neural
%                       data recording onset.
%
% By: Max Murphy  v1.0   08/20/2018  Original version (R2017b)

%% DEFAULTS
FS = 125; % Interpolated video frame rate that is used in R calculation
HVEC_INTERP = 12; % Interpolate between histogram edges

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%%
[~,maxR_i] = max(R);
lagval = lag(maxR_i)/FS;

[nCount,edge] = histcounts(lagval);

[~,idx] = max(nCount);
hvec = linspace(edge(idx),edge(idx+1),HVEC_INTERP);

[nCount,~,lagbins] = histcounts(lagval,hvec);

[~,idx] = max(nCount);


VideoStartGuess = mode(lagval(lagbins==idx));


end