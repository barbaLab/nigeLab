function [spikepos,y] = SD_MTEO(f,pars)
%MTEO computes the timestamps of detected spikes in timedomain using a
%multiresolution teager energy operator.
%
%   Input parameters:
%       in_struc:   Input structure which contains
%                       M:      Matrix with data, stored columnwise
%                       SaRa:   Sampling frequency
%                       k:      Resolutation parameter
%       optional input parameters:
%                       none
%   Output parameters:
%       spikepos:   Timestamps of the detected spikes stored columnwise
%       
%   Description: 
        % This method is based on the work of J.H.Choi, H.K.Jung, T.Kim "A New Action Potential Detector Using the MTEO
        % and Its Effects on Spike Sorting Systems at Low Signal-to-Noise Ratios". It describes a modified TEO. Therefor
        % the parameter k is used to vary resolution and is related to frequency of actionpotentials. The input signal is split
        % into three TEO outputs followed by a smoothing and a maximum filter. For every time instance the maximum form the 
        % three smoothed TEO outputs is picked and is indicated in spikepos via variable max.
        % 
        % %   Dependencies:
%              
%
%   Author: F. Lieb, September 2016


fs = pars.fs;
k = pars.k;
L = length(s);

if size(s, 1) > size(s, 2)
    s = s';
end



%make it zero mean
s2 = f;% - mean(f);

%this implements fig.4 in the paper
out = zeros(length(s2),length(k));
for ik = 1:length(k)
    %k-teo
    out(:,ik) = s2.^2 - circshift(s2,[0, -k(ik)]).*circshift(s2,[0, k(ik)]);
    %smoothing window (hamming of length 4*k+1) normalized by noise power
    wind = hamming(4*k(ik)+1);
    wind = wind./(sqrt(3*sum(wind.^2) + sum(wind)^2));
    
    out(:,ik) = conv(out(:,ik),wind,'same');
end

%max filter
out = max(out, [], 2);
y = out;

% extract spike positions from mteo output
switch params.method
    case 'numspikes'
        spikepos = getSpikePositions(out,fs,s,params);
    otherwise
        error('unknown method specified');
end
    
