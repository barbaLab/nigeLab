function [ts,p2pamp,pmin,pW] = SD_AdaptThresh(data,pars)
%% ADAPTIVE_THRESHOLD   Set adaptive threshold based on local noise
%
%  [pwpamp,ts,pmin,dt] = ADAPTIVE_THRESHOLD(data,pars,art_idx)
%
%   --------
%    INPUTS
%   --------
%     data      :       1 x N double of bandpass filtered data, preferrably
%                       with artifact excluded already, on which to perform
%                       monopolar spike detection.
%
%     pars      :       Parameters structure from SPIKEDETECTCLUSTER with
%                       the following fields:
%
%       -> FilterLength \\ Number of samples in local noise detection filter
%
%   --------
%    OUTPUT
%   --------
%    p2pamp     :       Peak-to-peak amplitude of spikes.
%
%     ts        :       Timestamps (sample indices) of spike peaks.
%
%    pmin       :       Value at peak minimum.
%
%      dt       :       Time difference between spikes.
%
% By: Max Murphy    1.0    12/13/2017  Original version (R2017b)

%% CREATE THRESHOLD FILTER
n = round((pars.FilterLength/1e3)*pars.fs);
th = nigeLab.utils.fastsmooth(abs(data),pars.FilterLength,'abs_med',1);
th = th * pars.MultCoeff;
th(th<pars.MinThresh) = pars.MinThresh;

%% PERFORM THRESHOLDING
pk = (pars.Polarity * data) > th;

if sum(pk) <= 1
   p2pamp = [];
   ts = [];
   pmin = [];
   dt = [];
   pW = [];
   return
end

%% REDUCE CONSECUTIVE CROSSINGS TO SINGLE POINTS
z = zeros(size(data));
z(pk) = pars.Polarity * data(pk);
[pmin,ts] = findpeaks(z);
pmin = pmin * pars.Polarity;

%% GET PEAK-TO-PEAK VALUES
PLP = pars.PeakDur*1e-3*pars.fs; % from ms to samples
tloc = repmat(ts,2*PLP+1,1) + (-PLP:PLP).';
tloc(tloc < 1) = 1;
tloc(tloc > numel(data)) = numel(data);
[pmax,Imax] = max(data(tloc));
pW = abs(Imax-PLP);
p2pamp = pmax + pmin;

%% EXCLUDE VALUES OF PMAX <= 0
pm_ex = pmax<=0;
ts(pm_ex) = [];
p2pamp(pm_ex) = [];
pmax(pm_ex) = [];
pmin(pm_ex) = [];
pW(pm_ex) = [];



end