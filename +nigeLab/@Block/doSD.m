function flag = doSD(blockObj)
%DOSD   Detects spikes after raw extraction and unit filter
%
%  EXAMPLE USAGE
%  -------------------------------------------------------
%  b = nigeLab.Block();    % point to experiment
%  doRawExtraction(b);     % convert binary data
%  doUnitFilter(b);        % filter the data
%  doSD(b);                % detect extracellular spiking
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

% LOAD DEFAULT PARAMETERS FROM HARD-CODED SOURCE FILE
if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      if ~isempty(blockObj(i))
         if isvalid(blockObj(i))
            flag = flag && doSD(blockObj(i));
         end
      end
   end
   return;
else
   flag = false;
end
checkActionIsValid(blockObj);
nigeLab.utils.checkForWorker('config');

if ~genPaths(blockObj)
   warning('Something went wrong when generating paths for extraction.');
   return;
end

[~,pars] = blockObj.updateParams('SD','KeepPars');
pars.fs = blockObj.SampleRate;

% UPDATE STATUS FOR THESE STAGES
blockObj.updateStatus('Spikes',false,blockObj.Mask);
blockObj.updateStatus('SpikeFeatures',false,blockObj.Mask);
blockObj.updateStatus('Artifact',false,blockObj.Mask);

% GO THROUGH EACH CHANNEL AND EXTRACT SPIKE WAVEFORMS AND TIMES
if ~blockObj.OnRemote
   str = nigeLab.utils.getNigeLink('nigeLab.Block','doSD','Spike');
   str = sprintf('%s-Detection',str);
else
   str = 'Spike-Detection';
end
blockObj.reportProgress(str,0,'toWindow');
curCh = 0;
for iCh = blockObj.Mask
   curCh = curCh + 1;
   
   % No longer need check for CAR since checkActionIsValid does this
   data = blockObj.Channels(iCh).CAR(:);
   
   % Do the detection:
   if (curCh == 1)
      [spk,feat,art,blockObj.Pars.SD] = PerChannelDetection(data,pars);
   else
      [spk,feat,art,blockObj.Pars.SD] = PerChannelDetection(data,blockObj.Pars.SD);
   end

   if isempty(spk)
      spk = nan(1,size(spk,2));
   end
   
   if isempty(feat)
      feat = nan(size(spk,1),size(feat,2));
   end
   
   if isempty(art)
      art = nan(size(spk,1),size(art,2));
   end
   
   if ~saveChannelSpikingEvents(blockObj,iCh,spk,feat,art)
      error(['nigeLab:' mfilename ':BadSave'],...
         '[BLOCK/DOSD]::%s: Could not save spiking events for channel %d.',...
         blockObj.Name,iCh);
   end
   
   % Status updates done in saveChannelSpikingEvents
   pct = round(curCh/numel(blockObj.Mask) * 100);
   blockObj.reportProgress(str,pct,'toWindow');
   blockObj.reportProgress('Spike-Detection.',pct,'toEvent','Spike-Detection');
   
end
% Indicate that it is finished at the end
if blockObj.OnRemote
   str = 'Saving-Block';
   blockObj.reportProgress(str,100,'toWindow',str);
else
   blockObj.save;
   linkStr = blockObj.getLink('Spikes');
   str = sprintf('<strong>Spike Detection</strong> complete: %s\n',linkStr);
   blockObj.reportProgress(str,100,'toWindow','Done');
   blockObj.reportProgress('Done',100,'toEvent');
end
flag = true;

   function [spk,feat,art,pars] = PerChannelDetection(data, pars)
      %PERCHANNELDETECTION  Main sub-function for thresholding and detection
      %
      %   spk = PERCHANNELDETECTION(data,pars);
      %   [spk,feat] = PERCHANNELDETECTION(data,pars);
      %   [spk,feat,art] = PERCHANNELDETECTION(data,pars);
      %   [spk,feat,art,pars] = PERCHANNELDETECTION(data,pars);
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
      %     spk      :        Structure containing detected spikes as a sparse
      %                       array (peak_train); artifact occurrences as a
      %                       sparse array (artifact); and spike waveforms
      %                       corresponding to each positive entry of peak_train
      %                       (spikes).
      %
      %     feat     :        Contains the features corresponding to
      %                       detected spikes.
      %
      %      art     :        Contains artifact times.
      %
      %     pars     :        Updated parameters with new spike-related
      %                       variables.
      %
      % Adapted by: MAECI 2018 Collaboration (Federico Barban & Max Murphy)
      
      % CONVERT PARAMETERS
%       pars.w_pre       =   double(round(pars.W_PRE / 1000 * pars.FS));        % Samples before spike
%       pars.w_post      =   double(round(pars.W_POST / 1000 * pars.FS));       % Samples after spike
%       pars.ls          =   double(pars.w_pre+pars.w_post);                    % Length of spike
%       pars.art_dist    =   double(pars.ART_DIST*pars.FS);                     % Maximum Stimulation frequency
%       pars.PLP         =   double(floor(pars.PKDURATION*1e-3*pars.FS));       % Pulse lifetime period [samples]
%       pars.RP          =   double(floor(pars.REFRTIME*1e-3*pars.FS));         % Refractory period  [samples]
%       pars.npoints     =   double(length(data));                               % Sample length of record
%       if pars.PRESCALED
%          pars.th_artifact = pars.ARTIFACT_THRESH;
%       else
%          pars.th_artifact = pars.ARTIFACT_THRESH * 1e-6;
%       end
      


%             REMOVE ARTIFACT
      if ~isempty(pars.STIM_TS)
         data_ART = RemoveStimPeriods(data,pars);
      else
         data_ART = data;
      end
      
      if ~isempty(pars.ARTIFACT)
         [data_ART,art_idx] = RemoveArtifactPeriods(data_ART,pars.ARTIFACT);
      else
         art_idx = [];
      end
      
      ArtFun = ['ART_' pars.ArtefactRejMethodName];
      ArtPars = pars.(ArtFun);
      ArtPars.fs = pars.fs;
      Artargsout = cell(1,nargout(ArtFun));
      [Artargsout{:}] = feval(ArtFun,data_ART,ArtPars);
      data_ART = Artargsout{1};
      artifact = Artargsout{2};
      

      
      
      SDFun = ['SD_' pars.SDMethodName];
      SDPars = pars.(SDFun);
      SDPars.fs = pars.fs;
      SDargsout = cell(1,nargout(SDFun));
      [SDargsout{:}] = feval(SDFun,data_ART,SDPars);
      
      tIdx        = SDargsout{1};
      peak2peak = SDargsout{2};
      peakAmpl  = SDargsout{3};
      peakWidth = SDargsout{4};
      
      if numel(SDargsout)>4
          pTransformed = SDargsout{5};
      end
      dt = [diff(tIdx), round(median(diff(tIdx)))];

      % COMPUTE SPIKE THRESHOLD AND DO DETECTION
      % SpikeDetection_PTSD_core.cpp;
%       if mod(pars.PLP,2)>0
%          pars.PLP = pars.PLP + 1; % PLP must be even or doesn't work...
%       end
%       data_ART = double(data_ART);
%       
%       switch pars.PKDETECT
%          case 'both' % (old, probably not using any more -MM 8/3/2017)
%             tmpdata = data_ART;
%             tmpdata(art_idx) = [];
%             pars.thresh = PreciseTimingThreshold(tmpdata,pars);
%             [spkValues, spkTimeStamps] = SpikeDetection_PTSD_core(data_ART, ...
%                pars.thresh, ...
%                pars.PLP, ...
%                pars.RP, ...
%                pars.ALIGNFLAG);
%             
%             % +1 added to accomodate for zero- (c) or one-based (matlab) array indexing
%             ts  = 1 + spkTimeStamps( spkTimeStamps > 0);
%             p2pamp = spkValues( spkTimeStamps > 0);
%             pw = nan(size(p2pamp));
%             pp = nan(size(p2pamp));
%             
%             clear spkValues spkTimeStamps;
%             
%          case 'neg' % (probably use this in future -MM 8/3/2017)
%             
%             pars.thresh = pars.FIXED_THRESH;
%             
%             [p2pamp,ts,pw,pp] = ThresholdDetection(data_ART,pars,-1);
%             
%          case 'pos'
%             
%             pars.thresh = pars.FIXED_THRESH;
%             
%             [p2pamp,ts,pw,pp] = ThresholdDetection(data_ART,pars,1);
%             
%          case 'adapt' % Use findpeaks in conjunction w/ adaptive thresh -12/13/17
%             pars.thresh = pars.MULTCOEFF;
%             [p2pamp,ts,pw,pp] = AdaptiveThreshold(data_ART,pars);
%             
%          case 'SNEO' % Use findpeaks in conjunction w/ SNEO - 1/4/17
%             
% %             [p2pamp,ts,pw,pp,E] = SNEOThreshold(data_ART,pars,art_idx);
%          otherwise
%             error('Invalid PKDETECT specification.');
%       end
      % ENSURE NO SPIKES REMAIN FROM ARTIFACT PERIODS
      if any(artifact)
         [tIdx,ia]=setdiff(tIdx,(artifact./pars.fs));
         peak2peak=peak2peak(ia);
         peakAmpl = peakAmpl(ia);
         peakWidth = peakWidth(ia);
         if exist('pTransformed','var')~=0
            pTransformed = pTransformed(ia);
         end
      end
      
      % EXCLUDE SPIKES THAT WOULD GO OUTSIDE THE RECORD
      WindowPreSamples = floor(pars.WPre * 1e-3 * pars.fs); 
      WindowPostSamples = floor(pars.WPost * 1e-3 * pars.fs); 
      out_of_record = tIdx <= WindowPreSamples+1 | tIdx >= length(data) - WindowPostSamples - 2;
      peak2peak(out_of_record) = [];
      peakAmpl(out_of_record) = [];
      peakWidth(out_of_record) = [];
      tIdx(out_of_record) = [];
      if exist('pTransformed','var')~=0
         pTransformed(out_of_record) = [];
      end
      
      % BUILD SPIKE SNIPPET ARRAY AND PEAK_TRAIN
      tIdx = tIdx(:); % make sure it's vertical 
      if (numel(tIdx)>pars.MinSpikes) % If there are spikes in the current signal
         snippetIdx = (-WindowPreSamples : WindowPostSamples) + tIdx;
         spikes = data(snippetIdx);
%          [peak_train,spikes] = BuildSpikeArray(data,ts,peak2peak,pars);
         
%          %No interpolation in this case
%          if length(spikes) > 1
%             %eliminates borders that were introduced for interpolation
%             spikes(:,end-1:end)=[];
%             spikes(:,1:2)=[];
%          end
         
         %% Extract spike features
         features = [];
         pars.FEAT_NAMES = {};
         if ~strcmp(pars.FeatureExtractionMethodName,{'none',''})
             
             %Interpolate spikes
             pars.InterpSamples = max(size(spikes,2),pars.InterpSamples);
             Ispikes = interp1(1:size(spikes,2),...
                 spikes.',...
                 linspace(1,size(spikes,2),pars.InterpSamples),...
                 'spline').';
             
             FeatFun = ['FEAT_' pars.FeatureExtractionMethodName];
             FeatPars = pars.(FeatFun);
             FeatPars.fs = pars.fs;
             Featargsout = cell(1,nargout(FeatFun));
             [Featargsout{:}] = feval(FeatFun,Ispikes,FeatPars);
             features = Featargsout{1};
             if nargout(FeatFun) == 1
                 % if feature labels are not provided just use the method
                 % name and numbers
                 pars.FEAT_NAMES = arrayfun(@(ii)...
                     sprintf('%s-%.2d',...
                     pars.FeatureExtractionMethodName, ii),...
                     1:size(features,2),...
                     'UniformOutput',false);
             else
                 pars.FEAT_NAMES = Featargsout{2};
             end
         end
         
         
         normalize = @(x)(x - mean(x))./std(x,[],1);
         features = [features, normalize(peakAmpl(:))];
         if ~ismember({'pk-amp'},pars.FEAT_NAMES)
             pars.FEAT_NAMES = [pars.FEAT_NAMES, {'pk-amp'}];
         end
         
         features = [features, normalize(peak2peak(:))];
         if ~ismember({'pk-prom'},pars.FEAT_NAMES)
             pars.FEAT_NAMES = [pars.FEAT_NAMES, {'pk-prom'}];
         end
         
         features = [features, normalize(peakWidth(:))];
         if ~ismember({'pk-width'},pars.FEAT_NAMES)
             pars.FEAT_NAMES = [pars.FEAT_NAMES, {'pk-width'}];
         end
         
         if exist('pTransformed','var')~=0
             features = [features, normalize(pTransformed(:))];
             
             if ~ismember({'pk-energy'},pars.FEAT_NAMES)
                 pars.FEAT_NAMES = [pars.FEAT_NAMES, {'pk-energy'}];
             end
         end
         
      else % If there are no spikes in the current signal
          FeatFun = ['FEAT_' pars.FeatureExtractionMethodName];
         spk = ones(0,-WindowPreSamples + WindowPostSamples + 4);
         feat = ones(0,pars.(FeatFun).NOut+4);
         art = ones(0,5);
         return;
      end
      
      % GENERATE OUTPUT VECTORS
%       tIdx = find(peak_train);
%       tIdx = reshape(tIdx,numel(tIdx),1);
      
      type = zeros(size(tIdx));
      value = tIdx; % Store in value for now
      tag = zeros(size(tIdx));
      ts = tIdx./pars.fs; % Get values in seconds
      
      % CONCATENATE OUTPUT MATRICES
      if isempty(spikes)
         spk = ones(0,pars.ls + 4);
      else
         spk = [type,value,tag,ts,spikes];
      end
      
      if isempty(features)
         feat = ones(0,numel(pars.FEAT_NAMES)+4);
      else
         feat = [type,value,tag,ts,features];
      end
      
      % ASSIGN "ARTIFACT" OUTPUT
      if isempty(artifact)
         art = ones(0,5);
      else
         artifact = artifact(:); % make sure is column oriented
         iStart = artifact([true, diff(artifact)' ~= 1]);
         iStop = artifact(fliplr([true, diff(fliplr(artifact))' ~= 1]));
         
         value = reshape(iStart,numel(iStart),1);
         tag = reshape(iStop,numel(iStop),1);
         type = zeros(size(value));
         ts = value./pars.fs;
         snippet = tag./pars.fs;

         art = [type,value,tag,ts,snippet];
      end
      
   end

end
