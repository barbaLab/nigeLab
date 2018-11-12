function [spikedata,pars] = SpikeDetectionArray(data, pars)
%% SPIKEDETECTIONARRAY  Main sub-function for thresholding and detection
%
%   spikedata = SPIKEDETECTIONARRAY(data,pars)
%
%   --------
%    INPUTS
%   --------
%     data      :       Filtered and re-referenced data (in micro-volts) of
%                       a single channel of input data.
%
%     pars      :       Parameter structure that contains things like the
%                       sampling frequency, which will be passed through to
%                       other sub-functions called from SPIKEDETECTIONARRAY
%
%   --------
%    OUTPUT
%   --------
%   spikedata   :       Structure containing detected spikes as a sparse
%                       array (peak_train); artifact occurrences as a
%                       sparse array (artifact); and spike waveforms
%                       corresponding to each positive entry of peak_train
%                       (spikes).
%
%     pars      :       Updated parameters with new spike-related
%                       variables.
%
% See also: SPIKEDETECTIONARRAY
%
% Max Murphy        v 3.1.0 08/11/2017 - Moved feature-extraction to
%                                        SPIKEDETECTIONARRAY, which has
%                                        previously been done in the
%                                        SPIKECLUSTER_SPC step, but really
%                                        it makes more sense for the
%                                        extracted spike features to be
%                                        saved with the spike waveforms,
%                                        and instead of saving all the
%                                        spike waveforms for each cluster
%                                        separately, twice, just make use
%                                        of the spikes files and the
%                                        clusters files for unique types of
%                                        information.
%                   v 3.0.1 08/03/2017 - Just cleaned some things up, added
%                                        more of the derived parameters to
%                                        the pars struct so that it's
%                                        easier to use these functions just
%                                        by loading saved spike output and
%                                        then interacting with individual
%                                        functions from APP_CODE.
%                   v 3.0   08/01/2017 - Added STIM_TS blanking capability.
%                                        Added ARTIFACT blanking
%                                        capability.
%                   v 2.3   07/29/2017 - Made it actually use the
%                                        "PRESCALED" input.
%                   v 2.2   02/03/2017 - Fixed problem where PLP and RP
%                                        were getting passed to the PTSD c
%                                        file as singles, causing them to
%                                        not detect any spikes.
%                   v 2.1   01/30/2017 - Slightly modified the artifact
%                                        exclusion for both high- and
%                                        low-value spikes.
%                   v 2.0   01/29/2017 - Changed inputs (removed 'trials'/
%                                        'chan', added 'pars'). Added
%                                        documentation. Modified
%                                        sub-functions as well as
%                                        SPIKEDETECTCLUSTER, the main file
%                                        which calls SPIKEDETECTIONARRAY.
%                                        Removed unnecessary loops since
%                                        this will now only run as a single
%                                        channel at a time. Removed
%                                        unnecessary (redundant) output,
%                                        since detection will no longer
%                                        occur as a concatenation of many
%                                        smaller "trials" occurring over
%                                        the course of a recording, but
%                                        rather as a single trial per
%                                        recording that spans the
%                                        recording's duration.
% Alberto Averna    v 1.3   11/09/2016 - ???
% Max Murphy        v 1.2   04/21/2016 - Update artifact from 100 to 250 uV
% Max Murphy        v 1.1   03/01/2016 - Troubleshoot for RC code

%% CONVERT PARAMETERS
pars.w_pre       =   double(round(pars.W_PRE / 1000 * pars.FS));        % Samples before spike
pars.w_post      =   double(round(pars.W_POST / 1000 * pars.FS));       % Samples after spike
pars.ls          =   double(pars.w_pre+pars.w_post);                    % Length of spike
pars.art_dist    =   double(pars.ART_DIST*pars.FS);                     % Maximum Stimulation frequency
pars.PLP         =   double(floor(pars.PKDURATION*1e-3*pars.FS));       % Pulse lifetime period [samples]
pars.RP          =   double(floor(pars.REFRTIME*1e-3*pars.FS));         % Refractory period  [samples]
pars.nc_artifact =   double(floor(pars.ARTIFACT_SPACE*1e-3*pars.FS));   % PLP [samples]
pars.npoints     =   double(numel(data));                               % Sample length of record
if pars.PRESCALED
   pars.th_artifact = pars.ARTIFACT_THRESH;
else
   pars.th_artifact = pars.ARTIFACT_THRESH * 1e-6;
end

%% REMOVE ARTIFACT
if ~isempty(pars.STIM_TS)
   data_ART = Remove_Stim_Periods(data,pars);
else
   data_ART = data;
end

if ~isempty(pars.ARTIFACT)
   [data_ART,art_idx] = Remove_Artifact_Periods(data_ART,pars.ARTIFACT);
else
   art_idx = [];
end
[data_ART,artifact] = Hard_Artifact_Rejection(data_ART,pars);

%% COMPUTE SPIKE THRESHOLD AND DO DETECTION
% SpikeDetection_PTSD_core.cpp;
if mod(pars.PLP,2)>0
   pars.PLP = pars.PLP + 1; % PLP must be even or doesn't work...
end
data_ART = double(data_ART);

switch pars.PKDETECT
   case 'both' % (old, probably not using any more -MM 8/3/2017)
      tmpdata = data_ART;
      tmpdata(art_idx) = [];
      pars.thresh = PreciseTiming_Threshold(tmpdata,pars);
      [spkValues, spkTimeStamps] = SpikeDetection_PTSD_core(data_ART, ...
         pars.thresh, ...
         pars.PLP, ...
         pars.RP, ...
         pars.ALIGNFLAG);
      
      % +1 added to accomodate for zero- (c) or one-based (matlab) array indexing
      ts  = 1 + spkTimeStamps( spkTimeStamps > 0);
      p2pamp = spkValues( spkTimeStamps > 0);
      pw = nan(size(p2pamp));
      pp = nan(size(p2pamp));
      
      clear spkValues spkTimeStamps;
      
   case 'neg' % (probably use this in future -MM 8/3/2017)
      
      pars.thresh = pars.FIXED_THRESH;
      
      [p2pamp,ts,pw,pp] = Threshold_Detection(data_ART,pars,-1);
      
   case 'pos'
      
      pars.thresh = pars.FIXED_THRESH;
      
      [p2pamp,ts,pw,pp] = Threshold_Detection(data_ART,pars,1);
      
   case 'adapt' % Use findpeaks in conjunction w/ adaptive thresh -12/13/17
      pars.thresh = pars.MULTCOEFF;
      [p2pamp,ts,pw,pp] = Adaptive_Threshold(data_ART,pars);
      
   case 'sneo' % Use findpeaks in conjunction w/ SNEO - 1/4/17
      pars.thresh = pars.MULTCOEFF;
      [p2pamp,ts,pw,pp,E] = SNEO_Threshold(data_ART,pars,art_idx);
   otherwise
      error('Invalid PKDETECT specification.');
end
%% ENSURE NO SPIKES REMAIN FROM ARTIFACT PERIODS
if any(artifact)
   [ts,ia]=setdiff(ts,artifact);
   p2pamp=p2pamp(ia);
   pw = pw(ia);
   pp = pp(ia);
   if exist('E','var')~=0
      E = E(ia);
   end
end

%% EXCLUDE SPIKES THAT WOULD GO OUTSIDE THE RECORD
out_of_record = ts <= pars.w_pre+1 | ts >= pars.npoints-pars.w_post-2;
p2pamp(out_of_record) = [];
pw(out_of_record) = [];
pp(out_of_record) = [];
ts(out_of_record) = [];
if exist('E','var')~=0
   E(out_of_record) = [];
end

%% BUILD SPIKE SNIPPET ARRAY AND PEAK_TRAIN
if (any(ts)) % If there are spikes in the current signal
   
   [peak_train,spikes] = Build_Spike_Array(data,ts,p2pamp,pars);
   
   %No interpolation in this case
   if length(spikes) > 1
      %eliminates borders that were introduced for interpolation
      spikes(:,end-1:end)=[];
      spikes(:,1:2)=[];
   end
   
   % Extract spike features
   if size(spikes,1) > pars.MIN_SPK % Need minimum number of spikes
      features = wave_features(spikes,pars);
      features = features./std(features);
      if ~any(isnan(p2pamp))
         tmp = (reshape(p2pamp,size(features,1),1)./max(p2pamp)-0.5)*3.0;
         features = [features, tmp];
      end
      if ~any(isnan(pp))
         tmp = (reshape(pp,size(features,1),1)./max(pp)-0.5)*3.0;
         features = [features, tmp];
      end
      if ~any(isnan(pw))
         tmp = (reshape(pw,size(features,1),1)./max(pw)-0.5)*3.0;
         features = [features, tmp];
      end
      if exist('E','var')~=0
         tmp = (reshape(E,size(features,1),1)./max(E)-0.5)*3.0;
         features = [features, tmp];
      end
   else
      % Just make features reflect poor quality of (small) cluster
      features = randn(size(spikes,1),pars.NINPUT) * 10;
   end
   
else % If there are no spikes in the current signal
   peak_train = sparse(double(pars.npoints) + double(pars.w_post), double(1));
   spikes = [];
   features = [];
end

%% ASSIGN OUTPUT
spikedata.peak_train = peak_train;      % Spike (neg.) peak times
spikedata.artifact = artifact;          % Artifact times
spikedata.spikes = spikes;              % Spike snippets
spikedata.features = features;          % Wavelet features
spikedata.pp = pp;                      % Prominence (peak min. for 'adapt')
spikedata.pw = pw;                      % Width (peak max. for 'adapt')

end
