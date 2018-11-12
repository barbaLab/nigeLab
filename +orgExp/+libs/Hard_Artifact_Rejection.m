function [data_ART,art_idx] = Hard_Artifact_Rejection(data,pars)
%% HARD_ARTIFACT_REJECTION  Automatically changes data to zero on samples and samples within a pre-specified window around it upon crossing a pre-specified threshold.
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
%       ->  th_artifact \\ Artifact threshold (micro-volts).
%
%       ->  nc_artifact \\ Number of samples around threshold to replace 
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
segm = find(abs(data) >= pars.th_artifact);
art_idx = [];

%% REMOVE (ZERO) SECTIONS AROUND ARTIFACT
if any(segm)    
    if (pars.nc_artifact)
         rm_pre = max(segm - pars.nc_artifact,1);             % Start index >= 1
         rm_post = min(length(data),segm + pars.nc_artifact); % End index <= total samples in data
         
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

    art_idx = 0;
end 

end