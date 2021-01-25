function [ts,p2pamp,pmin,pW] = SD_PTSD(data,pars)

Thresh = pars.MultCoeff*median(abs(data(:))./0.6745);

% PRECISION TIMINIG SPIKE DETECTION
[spkValues, spkTimeStamps] = SpikeDetection_PTSD_core( double(data(:)), Thresh , pars.PeakDur, pars.RefrTime, pars.AlignFlag);

% %%%%%%%%%%%%%%% Valentina - end
ts  = 1 + spkTimeStamps( spkTimeStamps > 0 )'; % +1 added to accomodate for zero- (c) or one-based (matlab) array indexing
pmin = data( ts );
% % %%%%%%%%%%%% Valentina - begin
% spikesValue(spikesTime<=w_pre+1 | spikesTime>=length(data)-w_post-2)=[];
% spikesTime(spikesTime<=w_pre+1 | spikesTime>=length(data)-w_post-2)=[];
% nspk = length(spikesTime);
% 
% minTime = 1e-3*pars.RefrTime; % parameter in milliseconds
% [ts,pmin] = nigeLab.libs.peakseek(spkValues,minTime*pars.fs,pars.Thresh );
% pmin = pmin .* pars.Polarity;

%% GET PEAK-TO-PEAK VALUES
PLP = floor(pars.PeakDur*1e-3*pars.fs); % from ms to samples
tloc = repmat(ts,2*PLP+1,1) + (-PLP:PLP).';
tloc(tloc < 1) = 1;
tloc(tloc > numel(data)) = numel(data);
[pmax,Imax] = max(data(tloc));
pW = abs(Imax-PLP);
p2pamp = pmax + pmin;

%% EXCLUDE VALUES OF PMAX <= 0
pm_ex = pmax<= 0 | pmin >= 0;
ts(pm_ex) = [];
p2pamp(pm_ex) = [];
pmax(pm_ex) = [];
pmin(pm_ex) = [];
pW(pm_ex) = [];


end

