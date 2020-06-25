function [spikepos,y] = SD_WTEO(s,pars)
%MTEO computes the timestamps of detected spikes in timedomain using a
%wavelet based teager energy operator.
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
        % This method is based on the work of N.Naber and F.Franke "a wavelet
        % based Teager Energy operator for Spike Detection 
        % in Microelectrode Array Recordings". It descriebes a wavelet
        % based TEO. Hence a low-pass filter using first and second level
        % approximation coefficients of the discrete wavelet transform is
        % apllied to each sub-band, followed by TEO. Each output is
        % thresholded independently and then up sampled to the orignial
        % signal lenght indicated in spikepos.
      
        % 
        % %   Dependencies:
%              
%
%   Author: F. Lieb, September 2016


%parse inputs
fs = pars.fs;
L = length(s);
wavLevel = 2;
wavelet = 'sym7';

TEO = @(x) (x.^2 - circshift(x,[0, -1]).*circshift(x,[0, 1]));



if size(s, 1) > size(s, 2)
    s = s';
end

%do zero padding if the L is not divisible by a power of two
pow = 2^wavLevel;
if rem(L,pow) > 0
    Lok = ceil(L/pow)*pow;
    Ldiff = Lok - L;
    s = [s; zeros(Ldiff,1)];
    L = Lok;
end



f = s;




%My interpretation
%[SWTa,SWTd] = swt(s,wavLevel,wavelet);
%out = TEO(SWTa);
lo = wfilters(wavelet);
zz = wconv1(f,lo,'same');
cA1 = zz(1:2:end);
out1 = TEO(cA1);

zz = wconv1(cA1,lo,'same');
cA2 = zz(1:2:end);
out2 = TEO(cA2);

%o1 = interp1(1:length(out1),out1,linspace(1,length(out1),L),'nearest');
o1 = dyadup(out1,1);
o1 = o1(1:end-1);
%o2 = interp1(1:length(out2),out2,linspace(1,length(out2),L),'nearest');
o2 = dyadup(dyadup(out2,1),1);
o2 = o2(1:end-3);

out = [o1;  o2];

 %sum over approximation coefficients
out = sum(out,1);
y = out;
switch pars.method
    case 'numspikes'
        spikepos = getSpikePositions(out,fs,in.M,pars);
    case 'lambda'
        thout = wthresh(out,'h',pars.lambda);
        spikepos = getSpikePositions(thout,fs,s,pars);
    otherwise
        error('unknown method specified');
end