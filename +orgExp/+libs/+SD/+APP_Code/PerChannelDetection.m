function [spikedata,fs] = PerChannelDetection(blockObj,p,ch,pars,paths)
%% PERCHANNELDETECTION  Perform spike detection for each channel individually.
%
%   spikedata = PERCHANNELDETECTION(p,ch,pars,paths)
%
%   --------
%    INPUTS
%   --------
%       p           :       Number of probe.   
%
%      ch           :       Number of filtered and re-referenced
%                           single-channel stream to load.
%
%     pars          :       Parameters structure.
%
%    paths          :       Structure containing file path name info.
%
%   --------
%    OUTPUT
%   --------
%   spikedata       :       Struct containing 'spikes,' 'artifact,' and
%                           'peak_train' fields as described by
%                           SPIKEDETECTIONARRAY.
%
%     fs            :       Sampling frequency.
%
% See also: SPIKEDETECTIONARRAY, SPIKEDETECTCLUSTER
%   By: Max Murphy  v2.1    08/11/2017  Made naming more efficient. Removed
%                                       "extracted" input flag.
%                   v2.0    08/03/2017  Added peak prominence (pp) and peak
%                                       width (pw) as output to the save
%                                       files.
%                   v1.1    02/01/2017  Added flag for new format and
%                                       update pars.FS if the data is in
%                                       the new format.
%                   v1.0    01/30/2017  Original Version

%% LOAD FILTERED AND RE-REFERENCED MAT FILE
data=blockObj.Channels(ch).Filtered;

%% PERFORM SPIKE DETECTION
spikedata = SpikeDetectionArray(data,pars); 

%% SAVE SPIKE DETECTION DATA FOR THIS CHANNEL
newname = sprintf('%s%sP%d_Ch_%03d.mat',paths.N,pars.SPIKE_DATA,p,ch);

blockObj.blockObj.Channels(ch).Spikes=spikedata.spikes;

parsavedata(fullfile(paths.SL,paths.PF,newname), ...
    'spikes', spikedata.spikes, ...
    'artifact', spikedata.artifact, ...
    'peak_train',  spikedata.peak_train, ...
    'features', spikedata.features, ...
    'pw', spikedata.pw, ...
    'pp', spikedata.pp, ...
    'pars', pars)

end