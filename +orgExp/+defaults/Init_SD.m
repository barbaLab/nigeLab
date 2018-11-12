function pars = Init_SD(varargin)
%% INIT_SD Initialize SpikeDetectCluster parameters
%
%   pars = INIT_SD('NAME',value,...)
%
% By: Max Murphy (08/14/2017)

%% DEFAULTS
% General settings
VERSION  = 'v4.0.0';     % Version, to be passed with parameters
LIBDIR   = 'C:\MyRepos\_SD\APP_Code';% Location of associated sub-functions
DEF_DIR  = 'P:\';        % Default location to look for extracted data file
ED_ID = '\*P*Ch*.mat';    % Extracted data identifier (for input)

% Folder tags
RAW_ID      = '_RawData';           % Raw stream ID
FILT_ID     = '_Filtered';          % Filtered stream ID
CAR_ID      = '_FilteredCAR';       % Filtered + CAR ID
SPIKE_ID    = '_Spikes';            % Spike folder ID
SORT_ID     = '_Clusters';          % Sort folder ID
USE_CAR     = true;                 % By def. use common spatial reference

% File tags
RAW_DATA    = '_Raw_';              % Raw file ID
FILT_DATA   = '_Filt_';             % Filtered file ID
CAR_DATA    = '_FiltCAR_';          % CAR file ID
SPIKE_DATA  = '_ptrain_';           % Spikes file ID
CLUS_DATA   = '_clus_';             % Clusters file ID
DELETE_OLD_PATH = false;            % Remove old files
USE_EXISTING_SPIKES = false;        % Use existing spikes on directory
DO_AUTO_CLUSTERING = true;          % If false, skips "clustering" portion

% % Isilon cluster settings
USE_CLUSTER = true;      % Must pre-detect clusters on machine and run 
                         % v2017a in order to use Isilon cluster.

% Probe configuration
CHANS =  {'Wave',1:32,'P1'; ...  % Match the format for each probe that was used
          'Wav2',1:32,'P2'; ...  % to the number of channels on that probe. Skip
          'Wav3',1:32,'P3'; ...  % channel numbers (as seen by recording system)
          'Wav4',1:32,'P4'};     % if they are 'bad' (too noisy/too quiet).

% Spike detection settings

    % Parameters                     
    ARTIFACT_THRESH = 450;    % Threshold for artifact
    STIM_TS  = [];            % Pre-specified stim times
    ARTIFACT = [];            % Pre-specified artifact times
    PRE_STIM_BLANKING  = 0.5; % Window to blank before specifieid stim times (ms)
    POST_STIM_BLANKING = 1.5; % Window to blank after specified stim times (ms)
    ARTIFACT_SPACE  = 4;    % Window to ignore around artifact (suggest: 4 ms MIN for stim rebound)
    MULTCOEFF       = 4.5;  % Multiplication coefficient for noise
    PKDURATION      = 1.0;  % Pulse lifetime period (suggest: 2 ms MAX)
    REFRTIME        = 2.0;  % Refractory period (suggest: 2 ms MAX).
    PKDETECT        = 'sneo';% 'both' or 'pos' or 'neg' or 'adapt' or 'sneo' for peak type
    ADPT_N          = 60;   % Number of ms to use for adaptive filter
    SNEO_N          = 5;    % Number of samples to use for smoothed nonlinear energy operator window
    NS_AROUND       = 7;    % Number of samples around the peak to "look" for negative peak
    ADPT_MIN        = 15;   % Minimum for adaptive threshold (fixed)
    ALIGNFLAG       = 1;    % Alignment flag for detection
                            % [0 -> highest / 1 -> most negative]
    P2PAMP          = 60;   % Minimum peak-to-peak amplitude
    W_PRE           = 0.4;  % Pre-spike window  (ms)
    W_POST          = 0.8;  % Post-spike window (ms)
    ART_DIST        = 1/35; % Max. time between stimuli (sec)
    NWIN            = 120;  % Number of windows for automatic thresholding
    WINDUR          = 200*1e-3; % Minimum window length (msec)    
    INIT_THRESH     = 50;       % Pre-adaptive spike threshold (micro-volts)
    PRESCALED       = true;     % Whether data has been pre-scaled to micro-volts.
    FIXED_THRESH    = 50;       % If alignment is 'neg' or 'pos' this can be set to fix the detection threshold level
    ART_RATE        = 0.0035;   % Empirically determined rate for artifacts based on artifact rejection
    M               = (-7/3);   % See ART_RATE
    B               = 1.05;     % See ART_RATE
    
% Spike features and sorting settings (SPC pars in SPIKECLUSTER_SPC)
SC_VER = 'SPC';   % Version of spike clustering 
                         
    % Parameters
    N_INTERP_SAMPLES = 250; % Number of interpolated samples for spikes
    MIN_SPK  = 100;       % Minimum spikes before sorting
    TEMPSD   = 3.5;      % Cluster template max radius for template matching
    TSCALE   = 3.5;      % Scaling for timestamps of spikes as a feature
    USE_TS_FEATURE = false; % Add timestamp as an additional feature for SPC?
    FEAT     = 'wav';    % 'wav' or 'pca' or 'ica' for spike features
    WAVELET  = 'bior1.3';% 'haar' 'bior1.3' 'db4' 'sym8' all examples
    NINPUT   = 12;       % Number of feature inputs for clustering
    NSCALES  = 3;        % Number of scales for wavelet decomposition
    
%% PARSE VARARGIN
if numel(varargin)==1
    varargin = varargin{1};
    if numel(varargin) ==1
        varargin = varargin{1};
    end
end

for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if exist('SD_VER','var')==0
    % Version of spike detection
    switch PKDETECT
       case 'neg'
         SD_VER = [FEAT '-neg' num2str(FIXED_THRESH)];    
       case 'pos'
         SD_VER = [FEAT '-pos' num2str(FIXED_THRESH)];
       case 'adapt'
         SD_VER = [FEAT '-adapt'];
       case 'both'
         SD_VER = [FEAT '-PT'];  
       case 'sneo'
         SD_VER = [FEAT '-sneo'];
       otherwise
         SD_VER = [FEAT '-new'];
    end
end

%% INITIALIZE PARAMETERS STRUCTURE OUTPUT
pars = struct;
    
    % Path properties
    if exist('DIR','var')~=0
        pars.DIR = DIR;
    end
    if exist('SAVE_LOC','var')~=0
        pars.SAVE_LOC = SAVE_LOC;
    end
    pars.DEF_DIR = DEF_DIR;
    pars.DELETE_OLD_PATH = DELETE_OLD_PATH;
    pars.USE_EXISTING_SPIKES = USE_EXISTING_SPIKES;
    pars.DO_AUTO_CLUSTERING = DO_AUTO_CLUSTERING;
    
    %Detection properties
    pars.ARTIFACT_THRESH = ARTIFACT_THRESH;
    pars.ARTIFACT = ARTIFACT;
    pars.STIM_TS = STIM_TS;
    pars.PRE_STIM_BLANKING = PRE_STIM_BLANKING;
    pars.POST_STIM_BLANKING = POST_STIM_BLANKING;
    pars.ARTIFACT_SPACE = ARTIFACT_SPACE;
    pars.MULTCOEFF = MULTCOEFF;
    pars.PKDURATION = PKDURATION;
    pars.REFRTIME = REFRTIME;
    pars.ALIGNFLAG = ALIGNFLAG;
    pars.P2PAMP = P2PAMP;
    pars.W_PRE = W_PRE;
    pars.W_POST = W_POST;
    pars.ART_DIST = ART_DIST;
    pars.NWIN = NWIN;
    pars.WINDUR = WINDUR;
    pars.INIT_THRESH = INIT_THRESH;
    pars.PRESCALED = PRESCALED;
    pars.PKDETECT = PKDETECT;
    pars.FIXED_THRESH = FIXED_THRESH;
    pars.ADPT_N = ADPT_N;
    pars.SNEO_N = SNEO_N;
    pars.NS_AROUND = NS_AROUND;
    pars.ADPT_MIN = ADPT_MIN;
    pars.ART_RATE = ART_RATE;
    pars.M = M;
    pars.B = B;
    
    %Clustering properties
    pars.N_INTERP_SAMPLES = N_INTERP_SAMPLES;
    pars.MIN_SPK = MIN_SPK;
    pars.FEAT = FEAT;
    pars.NINPUT = NINPUT;
    pars.NSCALES = NSCALES;
    pars.TSCALE = TSCALE;
    pars.USE_TS_FEATURE = USE_TS_FEATURE;
    
    %General things about this run
    pars.CHANS = CHANS;
    pars.SD_VER = SD_VER;
    pars.SC_VER = SC_VER;
    pars.LIBDIR = LIBDIR;
    pars.ED_ID = ED_ID;
    pars.RAW_ID = RAW_ID;
    pars.RAW_DATA = RAW_DATA;
    pars.CLUS_DATA = CLUS_DATA;
    pars.USE_CAR = USE_CAR;
    if pars.USE_CAR
        pars.FILT_ID = CAR_ID;
        pars.FILT_DATA = CAR_DATA;
    else
        pars.FILT_ID = FILT_ID;
        pars.FILT_DATA = FILT_DATA;
    end
    pars.SPIKE_ID = SPIKE_ID;
    pars.SPIKE_DATA = SPIKE_DATA;
    pars.SORT_ID = SORT_ID;
    pars.WAVELET = WAVELET;
    pars.USE_CLUSTER = USE_CLUSTER;
    pars.VERSION = VERSION;
    
end