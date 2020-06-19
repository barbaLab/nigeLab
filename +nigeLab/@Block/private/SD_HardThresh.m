function [v,ts,w,p] = SD_HardThresh(data,pars)
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
% Min of flat threshold or adaptive from Quiroga 2004
% pars.thresh = min(pars.FIXED_THRESH,...
%                   pars.MULTCOEFF*median(abs(data))/0.6745);

polarity = pars.Polarity;
%% JUST USE FINDPEAKS...
[v,ts,w,p] = findpeaks(polarity*data, ...
                      'MinPeakHeight',pars.Thresh, ...
                      'MinPeakProminence',pars.Thresh,...
                      'MaxPeakWidth',pars.PeakDur/3, ... 
                      'WidthReference','halfheight', ...
                      'MinPeakDistance',pars.RefrTime);
                  
%% MAKE SURE SIGN IS CORRECT
v = v * polarity;

end