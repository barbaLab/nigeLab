function [ts,p2pamp,pmin,pW,E] = SD_TIFCO(data,pars)
%GABOR computes the timestamps of detected spikes in timedomain using a
%Gabor Transform based spike detection.
%
%   Input parameters:
%       in_struc:   Input structure which contains
%                       M:      Matrix with data, stored columnwise
%                       SaRa:   Sampling frequency
%       optional input parameters:
%                       sx: 
%   Output parameters:
%       spikepos:   Timestamps of the detected spikes stored columnwise
%       
%   Description: 
    %         This method is based on the work F.Lieb "...". This algorithm uses 
    %         a special case of Short-Time-Fourier Transform using a filter. As spikes 
    %         can be specified by a certain time-frequency behavior, frequencies below
    %         and above a certain level will be ignored by specifying them within the
    %         GABOR transform. By applying a moving average to the time-frequency
    %         coefficients the spike form is enforced. Then a STF is used on the singal
    %         generating an indicator signal indicated in spikepos. 
            % %   Dependencies:
%              
%
%   Author: f. Lieb, September 2016

fs = pars.fs;
L = length(data);
W = window(pars.winType, pars.winL*fs ,pars.winPars{:});

a = 1;
M = 100;

[c,freq] = dgtsf(data,W,a,pars.fMin,pars.fMax,M,fs);

numt = 1;
numf = size(c,2);
%numf = 100;

W = convFreqWeights(c,numf,numt);


sx1 = sum(W,2);


% Standard detection

lambda_tifco  = prctile(sx1,99);
lambda_data      =  pars.MultCoeff*median(abs(data));
data_th = zeros(size(data));
data_th(sx1>lambda_tifco) = pars.Polarity .* data(sx1>lambda_tifco);

minTime = 1e-3*pars.RefrTime; % parameter in milliseconds
[ts,pmin] = nigeLab.libs.peakseek(data_th,minTime*pars.fs,lambda_data);
pmin = pmin .* pars.Polarity;
E = sx1(ts); 

%% GET PEAK-TO-PEAK VALUES
PLP = floor(pars.PeakDur*1e-3*pars.fs); % from ms to samples must be a row vector of integers or integer scalars (trouble with TDT data)
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

function [c, freq] = dgtsf(f,g,a,fmin,fmax,M,fs,tinv)
%DGTSF Discrete Gabor transform with specified frequency range
%   Usage:  c = dgtsf(f,g,a,fmin,fmax,M,fs);
%           c = dgtsf(f,g,a,fmin,fmax,M,fs,'timeinv');
%           [c,freq] = dgtsf(f,g,a,fmin,fmax,M,fs);
%
%   Input parameters:
%       f    : Signal
%       a    : Length of time shifts
%       M    : Number of frequency channels
%       g    : Window function (currently supported: hanning window only)
%       fmin : Minimum frequency
%       fmax : Maximum frequency
%       tinv : Option to compute the time invariant version 
%
%   Output parameters:
%       c    : Time-Frequency respresentation
%       freq : Frequency axis ranging from [fmin fmax] 
%
%   Description:
%       dgtsf(f,g,a,fmin,fmax,M,fs) computes the time-frequency
%       represenation of f very efficiently if M is relatively small. The
%       option tinv computes the time-invariant phase (shift and modulation
%       operator are reversed). This phase option is requiered in the
%       spikeDetection Algorithm.
%
%       The window g can be a vector containing the window, or a cell array
%       where the first entry is the window type as a string. If the ltfat
%       toolbox is installed a variety of different windows are available,
%       if not only the hanning window is supported so far. The second
%       parameter in the cell array is the size of the window. For example
%       {'hann', 100} gives a hanning window with 100 datapoints. Please be
%       reminded that the windowing is done in the frequency domain, so a
%       narrow window will give a good frequency resolution.
%
%   
%   Dependencies:
%       findFreqIndx
%        ~gabwin if ltfat exists on path
%
%   Author: F. Lieb, Janurary 2016
%
if nargin<8
    tinv = '';
end

%get signal length
L=size(f,1);
if L == 1
    L = size(f,2);
    f = f';
end
    
numelectrodes = size(f,2);

%get window function
if (iscell(g))
    if exist('gabwin','file') == 2
        if strcmp(g{1},'gauss')
            winsize = L;
            glh = L/2;
            g2 = fftshift(gabwin(g,a,L,L));
        else
            winsize = ceil(g{2});
            glh=floor(winsize/2);
            g2 = fftshift(gabwin(g,a,winsize));
        end
        
    else
        winsize = ceil(g{2});
        glh = floor(winsize/2);
        g2 = hann(g{2},'periodic');
        g2 = g2./norm(g2);
    end
    offset = 0;
else
    g2 = g;
    winsize = length(g2);
    glh=floor(winsize/2);
    [~,ymaxidx] = max(g2);
    offset =  ymaxidx;
end

%number of time channels
N=L/a;

%find the most approriate M 
[M, freq,dfindx] = findFreqIndx(L,fs,fmin,fmax,M);

%container for result
if isa(f,'single')
    c=zeros(N,M,numelectrodes,'single');
else
    c=zeros(N,M,numelectrodes,'double');
end

%map to frq axis:
frqdst = fs/L;
fminidx = floor(fmin/frqdst);
if (iscell(g))
    win_range = fminidx-glh+1:fminidx+glh;
else
    win_range = fminidx-offset+1:fminidx+winsize-offset ;
end
win_range(win_range<1) = win_range(win_range<1)+L;

df = diff(dfindx);
df = df(1);

%fft of input signal
fhat = fft(f);

%loop over all frequency bins
for k = 1:M
    %pointwise multiplication
    c([end-floor(winsize/2)+1:end,1:ceil(winsize/2)],k,:) = bsxfun(@times,fhat(win_range,:),g2);
    %update window range
    win_range = win_range + df;
    win_range(win_range>L) = win_range(win_range>L)-L;
end
%ifft of output matrix
c = ifft(c);

%todo: do this computation inside the loop to save some comp time... 
% (couldnt get this to work...)
if (strcmp(tinv,'timeinv'))
    %apply time invariant factor:
    TimeInd = (0:(L/a-1))*a;
    phase = exp(2*pi*1i*(TimeInd'*dfindx)/L);
    c = bsxfun(@times,c,phase);
end

function [M_out, freq, freqindx] = findFreqIndx(L,fs,fmin,fmax,M)
%FINDFREQINDX finds the corresponding frequency indices for specific set of
%             parameters
%
%   If fmin and fmax as well as L (signal length) and fs are specified, not
%   all M are possible due to the discretization and the limits due to fs
%   and L. 
%   This function looks for a possible number of frequency bins M_out which
%   is close the specified number M
%
% Author: F. Lieb, February 2016
%

%get minimum freq resolution:
dfreq = fs/L;

%get indx of minimum frequency:
fminidx = floor(fmin/dfreq);
%get indx of maximum frequency:
fmaxidx = ceil(fmax/dfreq);

M_out = findFreqIndx_helper(fmaxidx,fminidx,M);
freq = linspace(fminidx*dfreq,fmaxidx*dfreq,M_out);
freqindx = linspace(fminidx,fmaxidx, M_out);

function W2 = convFreqWeights(coeff, numfn, numtn)
%CONVFREQWEIGHTS sliding window neighborhood
%   Usage: W = convFreqWeights(coeff,numfn, numtn);
%
%   Input parameters:
%       coeff : Time-Frequency matrix with columnwise frequency content
%       numfn : Number of neighbors in frequency direction
%       numtn : Number of neighbors in time direction
%
%   Output parameters:
%       W2    : Convolved Time Frequency respresentation
%
%   Description:
%       convFreqWeights(coeff,numfn,numtn) computes the convolution of a 
%       mean-window with neighboring tf-coefficients
%
%   Author: F. Lieb, February 2016
%

%get inputsize
[cm, cn] = size(coeff);

if cn > cm
    coeff = coeff.';
end

factor = 2;
%get kernel
neigh = ones(numtn,numfn);
neigh = neigh./(norm(neigh(:),1));
windowcenter = ceil(numtn/2);
windowcenter2= ceil(numfn/2);

%container
if isa(coeff,'single')
    W = zeros(cm+numtn-1,cn + numfn-1,'single');
else
    W = zeros(cm+numtn-1,cn + numfn-1,'double');
end

%extend the borders
W(windowcenter:cm+windowcenter-1,windowcenter2:cn+windowcenter2-1)=abs(coeff).^factor;%abs(coeff).^2;
W(1:windowcenter-1,:) = flipud( W(windowcenter:2*(windowcenter-1),:) );
W(cm+windowcenter:end,:) = flipud( W(cm-numtn+2*windowcenter :cm+windowcenter-1,:) );
W(:,1:windowcenter2-1)= fliplr( W(:,windowcenter2:2*(windowcenter2-1)));
W(:,cn+windowcenter2:end)= fliplr( W(:,cn-numfn+2*windowcenter2:cn+windowcenter2-1));

%do convolution
W2 = (conv2(W,neigh,'valid')).^(1/factor);

function out = findFreqIndx_helper(io,iu,M)
%FINDFREQINDX_HELPER helper function for findFreqIndx
%
% looks for an equidistant discretization of the intervall [iu io] with M
% elements or some number close to M.
%
% Author: F. Lieb, February 2016
%

isize = io-iu;

%alldiv(isize)
d=isize./(isize:-1:2);
d=d(d==round(d));

tmp = isize./d + 1;

%find element closest to M
[~,idx] = min(abs(tmp-M));
out = tmp(idx(1));


