function [R,lag] = getR(x,y,varargin)
%% GETR  Get covariance matrix of two one-dimensional time-series.
%
%  R = GETR(x,y,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     x        :     Time-series vector (1).
%
%     y        :     Time-series vector (2).
%
%  varargin    :     (Optional) 'NAME', value input argument pairs
%                    -> 'N' (def: 15000) // Window length
%
%  --------
%   OUTPUT
%  --------
%     R        :     Correlation matrix between x and y.
%
%    lag       :     Lags corresponding to rows of R.
%
% By: Max Murphy  v1.0  08/20/2018  Original version (R2017b)

%% DEFAULTS
N = 5000;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET CORRELATION ON SERIES OF WINDOWS
M = min(numel(x),numel(y)) - N + 1;

R = nan(2*N-1,M);

for iM = 1:M
   vec = iM:(iM+N-1);
   [R(:,iM),lag] = xcorr(x(vec) - mean(x(vec)),y(vec) - mean(y(vec)));
end

end