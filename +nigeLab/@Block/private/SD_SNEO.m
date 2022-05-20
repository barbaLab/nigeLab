function [ts,p2pamp,pmin,pW,E] = SD_SNEO(data,pars)
%% SNEOTHRESHOLD   Smoothed nonlinear energy operator thresholding detect
%
%  [ts,p2pamp,pmin,pW,E] = SNEOTHRESHOLD(data,pars,art_idx)
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
%      pW       :       peakWidth, distance between pmax and pmin
%
% By: Max Murphy    1.0   01/04/2018   Original version (R2017a)

%% GET NONLINEAR ENERGY OPERATOR SIGNAL AND SMOOTH IT
Y = data - mean(data);
Yb = Y(1:(end-2));
Yf = Y(3:end);
Z = [0, Y(2:(end-1)).^2 - Yb .* Yf, 0]; % Discrete nonlinear energy operator
% Zs = fastsmooth(Z,pars.SNEO_N);
kern = ones(1,pars.SmoothN)./pars.SmoothN;
Zs = fliplr( conv( fliplr(conv(Z,kern,'same')) ,kern,'same')); % the same as the above tri option,(default one here used) but 10x faster
clear('Z','Y','Yb','Yf');
%% CREATE THRESHOLD FILTER
tmpdata = data;
% tmpdata(art_idx) = [];
tmpZ = Zs;
% tmpZ(art_idx) = [];

th = pars.MultCoeff * median(abs(tmpZ));
data_th = pars.MultCoeff * median(abs(tmpdata));
clear('tmpZ','tmpdata');
%% PERFORM THRESHOLDING
pk = Zs > th;

if sum(pk) <= 1
   p2pamp = [];
   ts = [];
   pmin = [];
   dt = [];
   E = [];
   return
end

%% REDUCE CONSECUTIVE CROSSINGS TO SINGLE POINTS
z = zeros(size(data));
% pkloc = repmat(find(pk),pars.NS_AROUND*2+1,1) + (-pars.NS_AROUND:pars.NS_AROUND).';
% pkloc(pkloc < 1) = 1;
% pkloc(pkloc > numel(data)) = numel(data);
% pkloc = unique(pkloc(:));
% z(pkloc) = data(pkloc);

%%%%%%%%%%%%%%%% FB, 5/28/2019 optimized for speed.  The above process took 2.9s 
%%%%%%%%%%%%%%%%  now it takes more or less 0.85s. Same result
pkloc = conv(pk,ones(1,pars.NSaround*2+1),'same')>0;
z(pkloc) = pars.Polarity .* data(pkloc);


minTime = 1e-3*pars.RefrTime; % parameter in milliseconds
[ts,pmin] = nigeLab.utils.peakseek(z,minTime*pars.fs,data_th);
pmin = pmin .* pars.Polarity;
E = Zs(ts);            


%% GET PEAK-TO-PEAK VALUES
PLP = floor(pars.PeakDur*1e-3*pars.fs); % from ms to samples
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
E(pm_ex) = [];
pW(pm_ex) = [];

end
