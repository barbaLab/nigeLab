function [ts,p2pamp,pmin,pW]  = SD_HardThresh(data,pars)
%% THRESHOLDDETECTION  Use monopolar threshold-crossing to get spike times
%
%   [v,ts,w,p] = THRESHOLDDETECTION(data,thresh,PLP,RP,polarity)
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
%       -> thresh \\ Amplitude for threshold crossing detection.
%
%       -> PLP    \\ Pulse lifetime period (samples; NOTE: this is divided
%                    by 3 in order to keep the default PLP similar between
%                    this method and PT method, for the time-being).
%
%       -> RP     \\ Refractory period (samples)
%
%       -> 
%
%     polarity  :       1 for positive-going only; -1 for negative-going
%                       only.
%
%   --------
%    OUTPUT
%   --------
%      v        :       Values of spike peaks.
%
%     ts        :       Timestamps (sample indices) of spike peaks.
%
%      w        :       Width at half-spike-amplitude.
%
%      p        :       Prominence of spikes.
%
% By: Max Murphy    v1.3    08/10/2017  Adaptive amplitude thresholding
%                   v1.2    08/08/2017  No longer needs peak prominence.
%                   v1.1    08/03/2017  Changed it to take pars structure
%                                       instead of several different
%                                       inputs.
%                   v1.0    08/02/2017  Original version (R2017a)

%% SET THRESHOLD

pk = pars.Polarity * data > pars.Thresh;

%% REDUCE CONSECUTIVE CROSSINGS TO SINGLE POINTS
z = zeros(size(data));
pkloc = conv(pk,ones(1,pars.NSaround*2+1),'same')>0;
z(pkloc) = pars.Polarity .* data(pkloc);


minTime = 1e-3*pars.RefrTime; % parameter in milliseconds
[ts,pmin] = nigeLab.libs.peakseek(z,minTime*pars.fs,pars.Thresh);
pmin = pmin .* pars.Polarity;


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