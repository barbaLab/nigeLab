function [p2pamp,ts,pmin,dt,E] = SNEO_Threshold(data,pars,art_idx)
%% SNEO_THRESHOLD   Smoothed nonlinear energy operator thresholding detect
%
%  [p2pamp,ts,pmin,dt,E] = SNEO_THRESHOLD(data,pars,art_idx)
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
%       -> SNEO_N    \\ number of samples for smoothing window
%       -> MULTCOEFF \\ factor to multiply NEO noise threshold by
%
%    art_idx   :        Indexing vector for artifact rejection periods,
%                       which are temporarily removed so that thresholds
%                       are not underestimated.
%
%   --------
%    OUTPUT
%   --------
%    p2pamp     :       Peak-to-peak amplitude of spikes.
%
%     ts        :       Timestamps (sample indices) of spike peaks.
%
%    pmin       :       Value at peak minimum. (pw) in SPIKEDETECTIONARRAY
%
%      dt       :       Time difference between spikes. (pp) in
%                       SPIKEDETECTIONARRAY
%
%      E        :       Smoothed nonlinear energy operator value at peaks.
%
% By: Max Murphy    1.0   01/04/2018   Original version (R2017a)

%% GET NONLINEAR ENERGY OPERATOR SIGNAL AND SMOOTH IT
Y = data - mean(data);
Yb = Y(1:(end-2));
Yf = Y(3:end);
Z = [0, Y(2:(end-1)).^2 - Yb .* Yf, 0]; % Discrete nonlinear energy operator
Zs = fastsmooth(Z,pars.SNEO_N);

%% CREATE THRESHOLD FILTER
tmpdata = data;
tmpdata(art_idx) = [];
tmpZ = Zs;
tmpZ(art_idx) = [];

th = pars.MULTCOEFF * median(abs(tmpZ));
data_th = pars.MULTCOEFF * median(abs(tmpdata));

%% PERFORM THRESHOLDING
pk = Zs > th;

if sum(pk) <= 1
   p2pamp = [];
   ts = [];
   pmin = [];
   dt = [];
   return
end

%% REDUCE CONSECUTIVE CROSSINGS TO SINGLE POINTS
z = zeros(size(data));
pkloc = repmat(find(pk),pars.NS_AROUND*2+1,1) + (-pars.NS_AROUND:pars.NS_AROUND).';
pkloc(pkloc < 1) = 1;
pkloc(pkloc > numel(data)) = numel(data);
pkloc = unique(pkloc(:));

z(pkloc) = data(pkloc);
[pmin,ts] = findpeaks(-z,... % Align to negative peak
               'MinPeakHeight',data_th);
E = Zs(ts);            


%% GET PEAK-TO-PEAK VALUES
tloc = repmat(ts,2*pars.PLP+1,1) + (-pars.PLP:pars.PLP).';
tloc(tloc < 1) = 1;
tloc(tloc > numel(data)) = numel(data);
pmax = max(data(tloc));

p2pamp = pmax + pmin;

%% EXCLUDE VALUES OF PMAX <= 0
pm_ex = pmax<=0;
ts(pm_ex) = [];
p2pamp(pm_ex) = [];
pmax(pm_ex) = [];
pmin(pm_ex) = [];
E(pm_ex) = [];

%% GET TIME DIFFERENCES
if numel(ts)>1
   dt = [diff(ts), round(median(diff(ts)))];
else
   dt = [];
end


end