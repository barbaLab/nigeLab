function [p2pamp,ts,pmin,dt] = Adaptive_Threshold(data,pars)
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
%       -> ADPT_N \\ Number of samples in local noise detection filter
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
n = round((pars.ADPT_N/1e3)*pars.FS);
th = fastsmooth(abs(data),pars.ADPT_N,'abs_med',1);
th(th<pars.ADPT_MIN) = pars.ADPT_MIN;

%% PERFORM THRESHOLDING
pk = (-data) > (th * pars.MULTCOEFF);

if sum(pk) <= 1
   p2pamp = [];
   ts = [];
   pmin = [];
   dt = [];
   return
end

%% REDUCE CONSECUTIVE CROSSINGS TO SINGLE POINTS
z = zeros(size(data));
z(pk) = data(pk);
[pmin,ts] = findpeaks(-z);

%% GET PEAK-TO-PEAK VALUES
tloc = repmat(ts,pars.PLP,1) + (1:pars.PLP).';
pmax = max(data(tloc));

p2pamp = pmax + pmin;

%% EXCLUDE VALUES OF PMAX <= 0
pm_ex = pmax<=0;
ts(pm_ex) = [];
p2pamp(pm_ex) = [];
pmax(pm_ex) = [];
pmin(pm_ex) = [];

%% GET TIME DIFFERENCES
dt = [diff(ts), round(median(diff(ts)))];

%% PERFORM SECONDARY EXCLUSIONS
a = p2pamp/(2*pars.ARTIFACT_THRESH);
b = pmin/pars.ARTIFACT_THRESH;
c = dt/pars.FS;

dt_ex = c <= pars.ART_RATE & b >= (pars.M.*a + pars.B);

ts(dt_ex) = [];
p2pamp(dt_ex) = [];
pmax(dt_ex) = [];
pmin(dt_ex) = [];
dt(dt_ex) = [];



end