function spikeDetection(blockObj)
    blockObj.SDpars = orgExp.defaults.Init_SD;
    pars = blockObj.SDpars;
%     SiteLayout = pars.CHANS{iP,2};
    nCh = blockObj.numChannels;
    
    spk = cell(nCh,1);
%     if pars.USE_CLUSTER
%         set(myJob,'Tag',['Detecting spikes for ' paths.N '...']);
%     else
%         disp('Beginning spike detection...'); %#ok<*UNRCH>
%     end
    
    FS = nan(nCh,1);
%     Fspk = dir(fullfile(paths.SL, ...
%         paths.PF,['*' pars.SPIKE_DATA '*.mat']));
%     if (~isempty(Fspk) && pars.USE_EXISTING_SPIKES)
%         for ii = 1:numel(Fspk)
%             tempname = strsplit(Fspk(ii).name(1:end-4),'_');
%             ind = find(ismember(tempname,'Ch'),1,'last')+1;
%             iCh = str2double(tempname{ind});
%             ch = find(abs(SiteLayout-iCh)<eps,1,'first');
%             spk{ch} = load(fullfile(paths.SL, ...
%                 paths.PF,Fspk(ii).name));
%             FS(ch) = spk{ch}.pars.FS;
%         end
%     else
        for iCh = 1:nCh
            pnum  = num2str(blockObj.Channels(iCh).port_number);
            chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
            fname = sprintf(strrep(blockObj.paths.SDW_N,'\','/'), pnum, chnum);
            blockObj.Channels(iCh).Spikes = orgExp.libs.DiskData('MatFile',fullfile(fname));
        end
        % Many low-memory computations; parallelize this
        if pars.USE_CLUSTER
            Chans=blockObj.Channels;
            parfor iCh = 1:nCh % For each "channel index"...
                [spk] = PerChannelDetection( ...
                    blockObj,iCh,pars);
                    Chans(iCh).Spikes(:)=spk;
            end
            blockObj.Channels = Chans;
        else
            disp('000%');
            for iCh = 1:nCh % For each "channel index"...
                [spk] = PerChannelDetection( ...
                    blockObj,iCh,pars);
                blockObj.Channels(iCh).Spikes(:)=spk;
                
                fraction_done = 100 * (iCh / nCh);
                if ~floor(mod(fraction_done,5)) % only increment counter by 5%
                    fprintf(1,'\b\b\b\b%.3d%%',floor(fraction_done))
                end
                
            end
        end

        blockObj.updateStatus('Spikes',true);
        blockObj.save;    
end


function [spikedata] = PerChannelDetection(blockObj,ch,pars)
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

%% LOAD FILTERED AND RE-REFERENCED MAT FILE
data=blockObj.Channels(ch).Filtered(:,:);
pars.FS = blockObj.Sample_rate;
%% PERFORM SPIKE DETECTION
spikedata = SpikeDetectionArray(data,pars); 

%% SAVE SPIKE DETECTION DATA FOR THIS CHANNEL
% newname = sprintf('%s%sP%d_Ch_%03d.mat',paths.N,pars.SPIKE_DATA,p,ch);


% orgExp.libs.parsavedata(fullfile(paths.SL,paths.PF,newname), ...
%     'spikes', spikedata.spikes, ...
%     'artifact', spikedata.artifact, ...
%     'peak_train',  spikedata.peak_train, ...
%     'features', spikedata.features, ...
%     'pw', spikedata.pw, ...
%     'pp', spikedata.pp, ...
%     'pars', pars)

end


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

%% CONVERT PARAMETERS
pars.w_pre       =   double(round(pars.W_PRE / 1000 * pars.FS));        % Samples before spike
pars.w_post      =   double(round(pars.W_POST / 1000 * pars.FS));       % Samples after spike
pars.ls          =   double(pars.w_pre+pars.w_post);                    % Length of spike
pars.art_dist    =   double(pars.ART_DIST*pars.FS);                     % Maximum Stimulation frequency
pars.PLP         =   double(floor(pars.PKDURATION*1e-3*pars.FS));       % Pulse lifetime period [samples]
pars.RP          =   double(floor(pars.REFRTIME*1e-3*pars.FS));         % Refractory period  [samples]
pars.nc_artifact =   double(floor(pars.ARTIFACT_SPACE*1e-3*pars.FS));   % PLP [samples]
pars.npoints     =   double(length(data));                               % Sample length of record
if pars.PRESCALED
   pars.th_artifact = pars.ARTIFACT_THRESH;
else
   pars.th_artifact = pars.ARTIFACT_THRESH * 1e-6;
end

%% REMOVE ARTIFACT
if ~isempty(pars.STIM_TS)
   data_ART = orgExp.libs.Remove_Stim_Periods(data,pars);
else
   data_ART = data;
end

if ~isempty(pars.ARTIFACT)
   [data_ART,art_idx] = orgExp.libs.Remove_Artifact_Periods(data_ART,pars.ARTIFACT);
else
   art_idx = [];
end
[data_ART,artifact] = orgExp.libs.Hard_Artifact_Rejection(data_ART,pars);

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
      pars.thresh = orgExp.libs.PreciseTiming_Threshold(tmpdata,pars);
      [spkValues, spkTimeStamps] = orgExp.libs.SpikeDetection_PTSD_core(data_ART, ...
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
      
      [p2pamp,ts,pw,pp] = orgExp.libs.Threshold_Detection(data_ART,pars,-1);
      
   case 'pos'
      
      pars.thresh = pars.FIXED_THRESH;
      
      [p2pamp,ts,pw,pp] = Threshold_Detection(data_ART,pars,1);
      
   case 'adapt' % Use findpeaks in conjunction w/ adaptive thresh -12/13/17
      pars.thresh = pars.MULTCOEFF;
      [p2pamp,ts,pw,pp] = orgExp.libs.Adaptive_Threshold(data_ART,pars);
      
   case 'sneo' % Use findpeaks in conjunction w/ SNEO - 1/4/17
      pars.thresh = pars.MULTCOEFF;
      [p2pamp,ts,pw,pp,E] = orgExp.libs.SNEO_Threshold(data_ART,pars,art_idx);
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
   
   [peak_train,spikes] = orgExp.libs.Build_Spike_Array(data,ts,p2pamp,pars);
   
   %No interpolation in this case
   if length(spikes) > 1
      %eliminates borders that were introduced for interpolation
      spikes(:,end-1:end)=[];
      spikes(:,1:2)=[];
   end
   
   % Extract spike features
   if size(spikes,1) > pars.MIN_SPK % Need minimum number of spikes
      features = orgExp.libs.wave_features(spikes,pars);
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