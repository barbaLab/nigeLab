function [ts,p2pamp,pmin,pW,E] = SD_SWTTEO(data,pars)
%SWTTEO Detects Spikes Location using a modified WTEO approach
%   Usage:  spikepos = swtteo(in);
%           spikepos = swtteo(in,params);
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
%       swtteo(in,params) computes the location of action potential in
%       noisy MEA measurements. This method is based on the work of N.
%       Nabar and K. Rajgopal "A Wavelet based Teager Engergy Operator for
%       Spike Detection in Microelectrode Array Recordings". The algorithm
%       therein was further improved by using a stationary wavelet
%       transform and a different thresholding concept.
%       For an unsupervised usage the sensitivity of the algorithm can be
%       adapted by changing the value of the variable global_fac in line
%       108. A larger value results in fewer detected spikes but also the
%       number of false positives decrease. Decreasing this factor makes it
%       more sensitive to detect spikes. 
%
%   References:
%       tbd.
%
%
%   Author: F. Lieb, February 2016
%


%parse inputs
fs = pars.fs;
TEO = @(x,k) (x.^2 - myTEOcircshift(x,[-k, 0]).*myTEOcircshift(x,[k, 0]));
L = length(data);
data = data(:);     % ensure in is column


%do zero padding if the L is not divisible by a power of two
% TODO use nextpow2 here
pow = 2^pars.wavLevel;
if rem(L,pow) > 0
    Lok = ceil(L/pow)*pow;
    Ldiff = Lok - L;
    data = [data; zeros(Ldiff,1)];
end



%vectorized version:
[lo_D,HiD] = wfilters(pars.waveName);
out_ = zeros(size(data));
ss = data;
for k=1:pars.wavLevel
    %Extension
    lf = length(lo_D);
    ss = extendswt(ss,lf);
    %convolution
    swa = conv2(ss,lo_D','valid');
    swa = swa(2:end,:); %even number of filter coeffcients
    %apply teo to swt output
    
    
    temp = abs(TEO(swa,1));


    
    if pars.smoothN
        wind = window(pars.winType,pars.smoothN,pars.winPars{:});
        temp2 = conv2(temp,wind','same');
    else
        temp2 = temp;
    end
        
    out_ = out_ + temp2;
    

    %dyadic upscaling of filter coefficients
    lo_D = dyadup(lo_D,0,1);
    %updates
    ss = swa;
end
clear('ss');

% Standard detection

lambda_swtteo   = prctile(out_,99);
lambda_data      =  pars.MultCoeff*median(abs(data));
data_th = zeros(size(data));
data_th(out_>lambda_swtteo) = pars.Polarity .* data(out_>lambda_swtteo);

minTime = 1e-3*pars.RefrTime; % parameter in milliseconds
[ts,pmin] = nigeLab.utils.peakseek(data_th,minTime*pars.fs,lambda_data);
pmin = pmin .* pars.Polarity;
E = out_(ts); 

%% GET PEAK-TO-PEAK VALUES
PLP = round(pars.PeakDur*1e-3*pars.fs); % from ms to samples
tloc = repmat(ts,2*PLP+1,1) + (-PLP:PLP).';
tloc(tloc < 1) = 1;
tloc(tloc > numel(data)) = numel(data);
[pmax,Imax] = max(data(tloc));
p2pamp = pmax + pmin;

%% Get peak width and exlude pw > pars.PeakDur
tlocmin = flipud( repmat(ts,PLP+1,1) + (-PLP:0).');
tlocmin(tlocmin < 1) = 1;
tlocmin(tlocmin > numel(data)) = numel(data);
tlocmax = repmat(ts,PLP,1) + (1:PLP).';
tlocmax(tlocmax < 1) = 1;
tlocmax(tlocmax > numel(data)) = numel(data);
for ii=1:size(tlocmin,2)
    [~,thispeak] = findpeaks(data(tlocmin(:,ii)),'NPeaks',1);
    if isempty(thispeak)
        thispeak = PLP+1;
    end
    Imax1(ii) = 1-thispeak;
    
    [~,thispeak] = findpeaks(data(tlocmax(:,ii)),'NPeaks',1);
    if isempty(thispeak)
        thispeak = PLP;
    end
    Imax2(ii) = thispeak;
end

pW = Imax2 - Imax1;

%% EXCLUDE VALUES 
pw_ex = pW>PLP;
pm_ex = pmax<=0;

ex = pw_ex | pm_ex;
ts(ex) = [];
p2pamp(ex) = [];
pmax(ex) = [];
pmin(ex) = [];
E(ex) = [];
pW(ex) = [];




function y = extendswt(x,lf)
%EXTENDSWT extends the signal periodically at the boundaries
[r,c] = size(x);
y = zeros(r+lf,c);
y(1:lf/2,:) = x(end-lf/2+1:end,:);
y(lf/2+1:lf/2+r,:) = x;
y(end-lf/2+1:end,:) = x(1:lf/2,:);


function X = myTEOcircshift(Y,k)
%circshift without the boundary behaviour...

colshift = k(1);
rowshift = k(2);

temp  = circshift(Y,k);

if colshift < 0
    temp(end+colshift+1:end,:) = flipud(Y(end+colshift+1:end,:));
elseif colshift > 0
    temp(1:1+colshift-1,:) = flipud(Y(1:1+colshift-1,:));
else
    
end

if rowshift<0
    temp(:,end+rowshift+1:end) = fliplr(Y(:,end+rowshift+1:end));
elseif rowshift>0
    temp(:,1:1+rowshift-1) = fliplr(Y(:,1:1+rowshift-1));
else
end

X = temp;

