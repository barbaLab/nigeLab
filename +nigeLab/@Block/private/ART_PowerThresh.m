function [data_ART,art_idx] = ART_PowerThresh(data,pars)
%% HARDARTIFACTREJECTION  Automatically changes data to zero on samples and samples within a pre-specified window around it upon crossing a pre-specified threshold.
%
%   --------
%    INPUTS
%   --------
%     data      :       Single-channel data that has been bandpass filtered
%                       and re-referenced (micro-volts).
%
%     pars      :       Parameter structure from SPIKEDETECTCLUSTER with
%                       the following fields:
%       
%       ->  Thresh \\ Artifact threshold (micro-volts).
%
%       ->  Samples \\ Number of samples around threshold to replace 
%                          with zeros to cancel out any ripple effects of 
%                          amplifier saturation and rebound.
%
%   --------
%    OUTPUT
%   --------
%   data_ART    :       Same as data, but with segments crossing the
%                       artifact rejection threshold and surrounding window
%                       zeroed out.
%
%   art_idx     :       Indices of artifact samples.
%
% See also: SPIKEDETECTIONARRAY
%
% Max Murphy  v1.2  08/03/2017  Changed to take pars as input instead of
%                               th_artifact and nc_artifact.
%
% Max Murphy  v1.1  01/29/2017  Changed to capital 'A' because I'm
%                               retentive about that. Changed documentation
%                               and formatting.
%
% Kelly RM    v1.0  11/04/2015  Original version.

%% FIND THRESHOLD CROSSINGS
fs = pars.fs;
W = window(pars.winType, pars.winL*fs ,pars.winPars{:})./pars.winL*fs;
if pars.Polarity > 0
%     PP = conv(data,W,'same');
%     PP(PP<0)=0;
    PP = (data*1e-6).^2;
    PP(data<0) = 0;
elseif pars.Polarity < 0
    PP = (data*1e-6).^2;
    PP(data>0) = 0;
else
    PP = (data*1e-6).^2;
end
PP = conv(PP,W,'same');
segm = find(PP >= pars.MultCoeff*median(PP));
art_idx = [];
Nsamples = double(floor(pars.Samples*1e-3*pars.fs)); % from ms to samples


%% REMOVE (ZERO) SECTIONS AROUND ARTIFACT
if any(segm)    
    if (Nsamples)
         rm_pre = max(segm - Nsamples,1);             % Start index >= 1
         rm_post = min(length(data),segm + Nsamples); % End index <= total samples in data
         
         for in = 1:length(segm) 
%               art_idx = [art_idx ,rm_pre(in):segm(in)];
%               art_idx = [art_idx ,segm(in):rm_post(in)];
             art_idx = [art_idx ,rm_pre(in):rm_post(in)]; %#ok<AGROW>
         end 
%          art_idx = unique([segm,art_idx]');
    end
    data_ART = data;
%     data_ART(art_idx) = [];
    data_ART(art_idx) = 0;
else 
    data_ART = data;

    art_idx = [];
end 

end