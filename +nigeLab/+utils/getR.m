function [R,lag] = getR(x,y,wLen)
%% GETR  Get covariance matrix of two one-dimensional time-series.
%
%  R = nigeLab.utils.getR(x,y);
%  R = nigeLab.utils.getR(x,y,wLen);
%
%  --------
%   INPUTS
%  --------
%     x        :     Time-series vector (1).
%
%     y        :     Time-series vector (2).
%
%    wLen      :     (Optional) window length (samples) default: 5000
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
if nargin < 3
   wLen = 5000;
end

%% GET CORRELATION ON SERIES OF WINDOWS
M = min(numel(x),numel(y)) - wLen + 1;

R = nan(2*wLen-1,M);

for iM = 1:M
   vec = iM:(iM+wLen-1);
   [R(:,iM),lag] = xcorr(x(vec) - mean(x(vec)),y(vec) - mean(y(vec)));
end

end