function [spikepos,y] = SD_SWT2012(in,params)
%SWTEO computes the timestamps of detected spikes in timedomain using a
%stationary wavelet transform algorithm.
%
%   Input parameters:
%       in_struc:   Input structure which contains
%                       M:      Matrix with data, stored columnwise
%                       SaRa:   Sampling frequency
%       optional input parameters:
%                       none
%   Output parameters:
%       spikepos:   Timestamps of the detected spikes stored columnwise
%       
%   Description: 
        % This method is based on the work of V.Shalchyan, W.Jensen, and D.Farina "Spike detection and clustering
        % with unsupervised wavelet optimization in extracellular neural recordings".
        % The algorithem splits signal into 5 levels of wavelet transforms. The coefficients are each thresholded by 
        % a level depended threshold. The values of the three highest Coefficients are sumed up and smoothed by a Bartlett
        % window. The indicator signal is indicated to spikepos where the spikes can be detected.
      
        % 
        % %   Dependencies:
%              
%
%   Author: F. Lieb, September 2016

s = in.M(:);
L = length(s);
fs = in.SaRa;


%prefilter signal
if params.filter
    if ~isfield(params,'F1')
        params.Fstop = 100;
        params.Fpass = 200;
        Apass = 0.2;
        Astop = 80;
        params.F1 = designfilt(   'highpassiir',...
                                  'StopbandFrequency',params.Fstop ,...
                                  'PassbandFrequency',params.Fpass,...
                                  'StopbandAttenuation',Astop, ...
                                  'PassbandRipple',Apass,...
                                  'SampleRate',fs,...
                                  'DesignMethod','butter');
    end
    f = filtfilt(params.F1,s);
else
    f = s;
end


spikelength = 2e-3*fs;

%thfactor 
thfactor = 0.8;

%do zero padding if the L is not divisible by a power of two
level = 5;

pow = 2^level;
if rem(L,pow) > 0
    Lok = ceil(L/pow)*pow;
    Ldiff = Lok - L;
    f = [s; zeros(Ldiff,1)];
else
    Lok = L;
end

%stationary wavelet transform with 5 levels and symlet
%swdec = swt(s,level,'sym4');
[swta,swtd] = swt(f,level,'sym5');

spd = swtd;

%estimate noise for each level
%tmp = swdec(1:level,:)';
tmp = spd';
thr = thfactor*sqrt(2*log(Lok)).*mad(tmp,1)/0.6745;

% Denoise.
%swdec2 = zeros(size(swdec));
swdec2 = zeros(size(spd));
for k = 1:size(spd,1)
    %swdec2(k,:) = wthresh(swdec(k,:),'h',thr(k));
    swdec2(k,:) = wthresh(spd(k,:),'h',thr(k));
end

%reconstruction not needed
%sigDEN = iswt(swdec2,'sym4');




%compute sum of level
%temp = swdec2(1:level,:)';
temp = swdec2';
EW = sum((temp-repmat(mean(temp),Lok,1)).^2);
[~,idx] = sort(EW,'descend');

%manifestation variable
Sn = abs(temp(:,idx(1))) + abs(temp(:,idx(2))) + abs(temp(:,idx(3)));

%smoothing window
w = bartlett(ceil(spikelength/2));
Tn = conv(Sn,w,'same');

y = Tn;




switch params.method
    case 'numspikes'
        out = y;
        np = 0;
        spikepos = zeros(1,params.numspikes);
        while (np < params.numspikes)
            [~, idxmax] = max(out);
            indx = idxmax-ceil(spikelength/2) : idxmax + floor(spikelength/2);
            indx = max(1,indx);
            indx = min(L,indx);
            out(indx) = 0;
            
            idxx = find(abs(s(indx)) == max(abs(s(indx))),1,'first');
            
            %spikepos(np+1) = idxmax;
            spikepos(np+1) = indx(1)+idxx-1;
            np = np + 1;
        end
    otherwise
        error('unknown method specified');
end