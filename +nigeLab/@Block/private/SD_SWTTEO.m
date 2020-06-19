function [spikepos, out_] = SD_SWTTEO(in,params)
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

if nargin<2
    params = struct;
end

%parse inputs
[params,s,fs] = parseInput(in,params);
TEO = @(x,k) (x.^2 - myTEOcircshift(x,[-k, 0]).*myTEOcircshift(x,[k, 0]));
[L,c] = size(s);
if L==1
    s = s';
    L = c;
    c = 1;
end


%do zero padding if the L is not divisible by a power of two
pow = 2^params.wavLevel;
if rem(L,pow) > 0
    Lok = ceil(L/pow)*pow;
    Ldiff = Lok - L;
    s = [s; zeros(Ldiff,c)];
end



%vectorized version:
lo_D = wfilters(params.wavelet);
out_ = zeros(size(s));
ss = s;
for k=1:params.wavLevel
    %Extension
    lf = length(lo_D);
    ss = extendswt(ss,lf);
    %convolution
    swa = conv2(ss,lo_D','valid');
    swa = swa(2:end,:); %even number of filter coeffcients
    %apply teo to swt output
    
    
    temp = abs(TEO(swa,1));


    
    if params.smoothing
        wind = hamming(params.winlength);
        %wind = sqrt(3*sum(wind.^2) + sum(wind)^2);
        %temp = filtfilt(wind,1,temp);
        if params.normalize_smoothingwindow
            wind = wind./(sqrt(3*sum(wind.^2) + sum(wind)^2));
        end
        temp2 = conv2(temp,wind','same');
        %temp = circshift(filter(wind,1,temp), [-3*1 1]);
    else
        temp2 = temp;
    end
        
    out_ = out_ + temp2;
    

    %dyadic upscaling of filter coefficients
    lo_D = dyadup(lo_D,0,1);
    %updates
    ss = swa;
end

    

%non-vectorized version to extract spikes...
switch params.method
    case 'auto'
        global_fac =params.global_fac;      %1.11e+03;%1.6285e+03; %540;%1800;%430; %1198; %change this
        if c == 1
            [CC,LL] = wavedec(s,5,'sym5');
            lambda = global_fac*wnoisest(CC,LL,1);
            thout = wthresh(out_,'h',lambda);
            spikepos = getSpikePositions(thout,fs,s,params);
        else
            spikepos = cell(c,1);
            for jj=1:c
                [CC,LL] = wavedec(s(:,jj),5,'sym5');
                lambda = global_fac*wnoisest(CC,LL,1);
                thout = wthresh(out_(:,jj),'h',lambda);
                spikepos{jj}=getSpikePositions(thout,fs,s(:,jj),params);
            end
        end
    case 'auto2'
        global_fac = 9.064e+02;%1.3454e+03;%800;%1800;%430; %1198; %change this
        params.method = 'auto';
        if c == 1
            [CC,LL] = wavedec(out_,5,'sym5');
            lambda = global_fac*wnoisest(CC,LL,1);
            thout = wthresh(out_,'h',lambda);
            spikepos = getSpikePositions(thout,fs,s,params);
        else
            spikepos = cell(c,1);
            for jj=1:c
                [CC,LL] = wavedec(out_(:,jj),5,'sym5');
                lambda = global_fac*wnoisest(CC,LL,1);
                thout = wthresh(out_(:,jj),'h',lambda);
                spikepos{jj}=getSpikePositions(thout,fs,s(:,jj),params);
            end
        end
    case 'numspikes'
        if c == 1
            spikepos=getSpikePositions(out_,fs,s,params);
        else
            spikepos = cell(1,c);
            params_tmp = params;
            for jj=1:c
                % extract spike positions from wteo output
                params_tmp.numspikes = params.numspikes(jj); 
                spikepos{jj}=getSpikePositions(out_(:,jj),fs,s(:,jj),params_tmp);
            end
        end
    case 'lambda'
        thout = wthresh(out_,'h',params.lambda);
        spikepos = getSpikePositions(thout,fs,s,params);
    case 'energy'
        params.p = 0.80;
        params.rel_norm =  5.718e-3;%5.718e-3;%4.842e-3;%22e-5;%1.445e-4;
        %wavelet denoising
        wdenoising = 0;
        n = 9;
        w = 'sym5';
        tptr = 'sqtwolog'; %'rigrsure','heursure','sqtwolog','minimaxi'
        
     
        if c == 1
            if wdenoising == 1
                out_ = wden(out_,tptr,'h','mln',n,w);
                %high frequencies, decision variable
                 c = dgtreal(out_,{'hann',10},1,200);
                 out_ = sum(abs(c).^2,1);
            end
            spikepos = getSpikePositions(out_,fs,s,params);
        else
            spikepos = cell(c,1);
            for jj=1:c
                if wdenoising == 1
                    out_(:,jj) = wden(out_(:,jj),tptr,'h','mln',n,w);
                end
                spikepos{jj} = getSpikePositions(out_(:,jj),fs,s(:,jj),params);
            end
        end
    otherwise
        error('unknown detection method specified');
end




%internal functions:
%--------------------------------------------------------------------------
function [params,s,fs] = parseInput(in,params)
%PARSEINPUT parses input variables
s = in.M;
fs = in.SaRa;
%Default settings for detection method
if ~isfield(params,'method')
    params.method = 'auto';
end
if strcmp(params.method,'numspikes')
    if ~isfield(params,'numspikes')
        error('please specify number of spikes in params.numspikes');
    end
end
%Default settings for stationary wavelet transform
if ~isfield(params,'wavLevel')
    params.wavLevel = 2;
end
if ~isfield(params, 'wavelet')
    params.wavelet = 'sym5';
end
if ~isfield(params, 'winlength')
    params.winlength = ceil(1.3e-3*fs); %1.3
end
if ~isfield(params, 'normalize_smoothingwindow')
    params.normalize_smoothingwindow = 0;
end
if ~isfield(params, 'smoothing')
    params.smoothing = 1;
end
if ~isfield(params, 'filter')
    params.filter = 0;
end




function y = extendswt(x,lf)
%EXTENDSWT extends the signal periodically at the boundaries
[r,c] = size(x);
y = zeros(r+lf,c);
y(1:lf/2,:) = x(end-lf/2+1:end,:);
y(lf/2+1:lf/2+r,:) = x;
y(end-lf/2+1:end,:) = x(1:lf/2,:);


% function idx2 = getSpikePositions(input_sig,fs,orig_sig,params)
% %GETSPIKEPOSITIONS computes spike positions from thresholded data
% %
% %   This function computes the exact spike locations based on a thresholded
% %   signal. The spike locations are indicated as non-zero elements in
% %   input_sig and are accordingly evaluated. 
% %
% %   The outputs are the spike positions in absolute index values (no time
% %   dependance). 
% %
% %   Author: F.Lieb, February 2016
% %
% 
% 
% %Define a fixed spike duration, prevents from zeros before this duration is
% %over
% spikeduration = 1e-3*fs;
% offset = 1;
% L = length(input_sig);
% 
% switch params.method
%     case 'numspikes'
%         out = input_sig;
%         np = 0;
%         idx2 = zeros(1,params.numspikes);
%         while (np < params.numspikes)
%             [~, idxmax] = max(out);
%             idxl = idxmax;
%             idxr = idxmax;
%             out(idxmax) = 0;
%             offsetcounter = 0;
%             while( out(max(1,idxl-2)) < out(max(1,idxl-1)) ||...
%                         offsetcounter < spikeduration )
%                 out(max(1,idxl-1)) = 0;
%                 idxl = idxl-1;
%                 offsetcounter = offsetcounter + 1;
%             end
%             offsetcounter = 0;
%             while( out(min(L,idxr+2)) < out(min(L,idxr+1)) ||...
%                         offsetcounter < spikeduration )
%                 out(min(L,idxr+1)) = 0;
%                 idxr = idxr+1;
%                 offsetcounter = offsetcounter + 1;
%             end
%             indexx = min(L,idxl-offset:idxr+offset);
%             indexx = max(1,indexx);
%             idxx = find( abs(orig_sig(indexx)) == ...
%                                   max( abs(orig_sig(indexx) )),1,'first');
%             idx2(np+1) = idxl - offset + idxx-1;
%             np = np + 1;
%         end
%         
%     case {'auto','lambda'}
%         %helper variables
%         idx2=[];
%         iii=1;
%         test2 = input_sig;
%         %loop until the input_sig is only zeros
%         while (sum(test2) ~= 0)
%             %get the first nonzero position
%             tmp = find(test2,1,'first');
%             test2(tmp) = 0;
%             %tmp2 is the counter until the spike duration
%             tmp2 = min(length(test2),tmp + 1);%protect against end of vec
%             counter = 0;
%             %search for the end of the spike
%             while(test2(tmp2) ~= 0 || counter<spikeduration )
%                 test2(tmp2) = 0;
%                 tmp2 = min(length(test2),tmp2 + 1);
%                 counter = counter + 1;
%             end
%             %spike location is in intervall [tmp tmp2], look for the max 
%             %element in the original signal with some predefined offset: 
%             indexx = min(length(orig_sig),tmp-offset:tmp2+offset);
%             indexx = max(1,indexx);
%             idxx = find( abs(orig_sig(indexx)) == ...
%                                    max( abs(orig_sig(indexx) )),1,'first');
%             idx2(iii) = tmp - offset + idxx-1;
%             iii = iii+1;
%         end
%     otherwise
%         error('unknown method');
% end
% 
% 
% 
