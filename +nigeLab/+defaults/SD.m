function pars = SD(varargin)
%% defaults.SD    Initialize parameters for spike detection
%
%   pars = nigeLab.defaults.SD('NAME',value,...);
%
%  Note: before further documentation here, maybe we consider cleaning this
%        up... basically it got pretty cluttered as I was trying lots of
%        different spike detection methods to find what worked best on our
%        data-sets generally. - MM
%
% By: MAECI 2018 collaboration (Max Murphy & Federico Barban)
%                 01/09/2019 :: 4.0.0 -> 4.0.1 = Fix FEAT_NAMES generation

%% DEFAULTS
pars = struct;

% General settings
pars.VERSION  = 'v4.0.1';     % Version, to be passed with parameters
pars.LIBDIR   = 'C:\MyRepos\_SD\APP_Code'; % Location of sub-functions

% Folder tags
pars.USE_CAR     = true;       % By def. use common spatial reference

% File tags
pars.DELETE_OLD_PATH = false;        % Remove old files
pars.USE_EXISTING_SPIKES = false;    % Use existing spikes on directory
pars.DO_AUTO_CLUSTERING = true;  % If false, skips "clustering" portion
                                 % (v2017a in order to use Isilon cluster)

% % Isilon cluster settings
pars.USE_CLUSTER = false;      % Must already have clustering done


%% SPIKE DETECTION PARAMETERS
% Parameters
pars.ARTIFACT_THRESH = 450;    % Threshold for artifact
pars.STIM_TS  = [];            % Pre-specified stim times
pars.ARTIFACT = [];            % Pre-specified artifact times
pars.PRE_STIM_BLANKING  = 0.5; % Window to blank before specifieid stim times (ms)
pars.POST_STIM_BLANKING = 1.5; % Window to blank after specified stim times (ms)
pars.ARTIFACT_SPACE  = 4;    % Window to ignore around artifact (suggest: 4 ms MIN for stim rebound)
pars.MULTCOEFF       = 4.5;  % Multiplication coefficient for noise
pars.PKDURATION      = 1.0;  % Pulse lifetime period (suggest: 2 ms MAX)
pars.REFRTIME        = 0.5;  % Refractory period (suggest: 2 ms MAX).
pars.PKDETECT        = 'sneo';% 'both' or 'pos' or 'neg' or 'adapt' or 'sneo' for peak type
pars.ADPT_N          = 60;   % Number of ms to use for adaptive filter
pars.SNEO_N          = 5;    % Number of samples to use for smoothed nonlinear energy operator window
pars.NS_AROUND       = 7;    % Number of samples around the peak to "look" for negative peak
pars.ADPT_MIN        = 15;   % Minimum for adaptive threshold (fixed)
pars.ALIGNFLAG       = 1;    % Alignment flag for detection
% [0 -> highest / 1 -> most negative]
pars.P2PAMP          = 60;   % Minimum peak-to-peak amplitude
pars.W_PRE           = 0.4;  % Pre-spike window  (ms)
pars.W_POST          = 0.8;  % Post-spike window (ms)
pars.ART_DIST        = 1/35; % Max. time between stimuli (sec)
pars.NWIN            = 120;  % Number of windows for automatic thresholding
pars.WINDUR          = 200*1e-3; % Minimum window length (msec)
pars.INIT_THRESH     = 50;       % Pre-adaptive spike threshold (micro-volts)
pars.PRESCALED       = true;     % Whether data has been pre-scaled to micro-volts.
pars.FIXED_THRESH    = 50;       % If alignment is 'neg' or 'pos' this can be set to fix the detection threshold level
pars.ART_RATE        = 0.0035;   % Empirically determined rate for artifacts based on artifact rejection
pars.M               = (-7/3);   % See ART_RATE
pars.B               = 1.05;     % See ART_RATE

% Spike features and sorting settings (SPC pars in SPIKECLUSTER_SPC)
pars.SC_VER = 'SPC';   % Version of spike clustering

% Parameters
pars.N_INTERP_SAMPLES = 250; % Number of interpolated samples for spikes
pars.MIN_SPK  = 100;       % Minimum spikes before sorting
pars.TEMPSD   = 3.5;      % Cluster template max radius for template matching
pars.TSCALE   = 3.5;      % Scaling for timestamps of spikes as a feature
pars.USE_TS_FEATURE = false; % Add timestamp as an additional feature for SPC?
pars.FEAT     = 'wav';    % 'wav' or 'pca' or 'ica' for spike features
pars.WAVELET  = 'bior1.3';% 'haar' 'bior1.3' 'db4' 'sym8' all examples
[pars.LoD,pars.HiD] = wfilters(pars.WAVELET); % get wavelet decomposition parameters
pars.NINPUT   = 12;       % Number of feature inputs for clustering
pars.NSCALES  = 3;        % Number of scales for wavelet decomposition

%% PARSE VARARGIN
if numel(varargin)==1
   varargin = varargin{1};
   if numel(varargin) ==1
      varargin = varargin{1};
   end
end

for iV = 1:2:length(varargin)
   pars.(upper(varargin{iV}))=varargin{iV+1};
end

%% PARSE OTHER PARAMETERS BASED ON SELECTED PARAMETERS
switch pars.PKDETECT
   case 'neg'
      pars.SD_VER = [pars.FEAT '-neg' num2str(pars.FIXED_THRESH)];
   case 'pos'
      pars.SD_VER = [pars.FEAT '-pos' num2str(pars.FIXED_THRESH)];
   case 'adapt'
      pars.SD_VER = [pars.FEAT '-adapt'];
   case 'both'
      pars.SD_VER = [pars.FEAT '-PT'];
   case 'sneo'
      pars.SD_VER = [pars.FEAT '-sneo'];
   otherwise
      pars.SD_VER = [pars.FEAT '-new'];
end

if pars.USE_CAR
   pars.ID.Artifact = [pars.SD_VER '_CAR'];
   pars.ID.Spikes = [pars.SD_VER '_CAR'];
   pars.ID.SpikeFeatures = [pars.SD_VER '_CAR'];
   pars.ID.Clusters = [pars.SD_VER '_' pars.SC_VER '_CAR'];
   pars.ID.Sorted = [pars.SD_VER '_' pars.SC_VER '_CAR'];
else
   pars.ID.Artifact = pars.SD_VER;
   pars.ID.Spikes = pars.SD_VER;
   pars.ID.SpikeFeatures = pars.SD_VER;
   pars.ID.Clusters = [pars.SD_VER '_' pars.SC_VER];
   pars.ID.Sorted = [pars.SD_VER '_' pars.SC_VER];
end

switch pars.FEAT
   case 'raw'
      pars.FEAT_NAMES = cell(1,2*pars.NINPUT + 1);
      for ii = 1:pars.NINPUT
         pars.FEAT_NAMES{ii} = sprintf('wav-%02d',ii);
      end
      for ik = 1:pars.NINPUT
         pars.FEAT_NAMES{ii+ik} = sprintf('raw-%02d',ik);
      end
      pars.FEAT_NAMES{ii+ik+1} = 'raw-mean';
   otherwise
      pars.FEAT_NAMES = cell(1,pars.NINPUT);
      for ii = 1:pars.NINPUT
         pars.FEAT_NAMES{ii} = sprintf('%s-%02d',pars.FEAT,ii);
      end
end

end