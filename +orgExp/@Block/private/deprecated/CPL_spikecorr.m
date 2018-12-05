function out = CPL_spikecorr(ts1,ts2,fs,varargin)
%% CPL_SPIKECORR  Get spike train correlation between two sets of spikes
%
%  out = CPL_SPIKECORR(ts1,ts2,fs,'NAME',value,...)
%
%  --------
%   INPUTS
%  --------
%     ts1      :     Spike timestamp series 1 (sample index of peaks)
%
%     ts2      :     Spike timestamp series 2 (sample index of peaks)
%
%     fs       :     Sampling rate of record
%
%  varargin    :     (Optional) 'NAME', value input argument pairs
%
%  --------
%   OUTPUT
%  --------
%    out       :     Struct containing information about the min, max, and
%                    lags at which each occurs, as well as the average
%                    correlation.
%
% By: Max Murphy  v1.0  02/07/2018  Original version (R2017b)

%% DEFAULTS
TLIM = [-100 100];     % Limits for binning vector (ms)
BIN = 1;               % Bin width (ms)

SHOW_PROGRESS = true; % Show progress bar

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET CORRELATIONS BETWEEN TRAINS
% Convert to ms
ts1 = (ts1/fs)*1e3; 
ts2 = (ts2/fs)*1e3;

% Get bin vector
tvec = TLIM(1):BIN:TLIM(2);
hvec = tvec(1:(end-1))+(BIN/2);

r = zeros(1,numel(tvec)-1);
nTotal = numel(ts1);

if SHOW_PROGRESS
   h = waitbar(0,'Please wait, computing cross-correlation...');
   
   for iT = 1:nTotal
      r = r + CPL_clipbins(histcounts(ts2-ts1(iT),tvec));   
      waitbar(iT/nTotal);
   end
   delete(h);
else
   for iT = 1:nTotal %#ok<UNRCH>
      r = r + histcounts(ts2-ts1(iT),tvec);   
   end
end

r = r./nTotal;

%% GET OUTPUT STRUCT
[maxval,maxlag] = max(r);
maxlag = hvec(maxlag);

[minval,minlag] = min(r);
minlag = hvec(minlag);

out = struct('xcorr',r,...
             'tau',hvec,...
             'max',struct('r',maxval,'lag',maxlag),...
             'min',struct('r',minval,'lag',minlag),...
             'mu',mean(r),...
             'sigma',std(r));
end