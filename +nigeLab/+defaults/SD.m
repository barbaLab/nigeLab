function varargout = SD(varargin)
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

pars = struct;

 
% %% OLD SPIKE DETECTION PARAMETERS
% % Parameters
% pars.ARTIFACT_THRESH = 450;    % Threshold for artifact

% pars.PRE_STIM_BLANKING  = 0.5; % Window to blank before specifieid stim times (ms)
% pars.POST_STIM_BLANKING = 1.5; % Window to blank after specified stim times (ms)
% pars.ARTIFACT_SPACE  = 4;    % Window to ignore around artifact (suggest: 4 ms MIN for stim rebound)
% pars.MULTCOEFF       = 4.5;  % Multiplication coefficient for noise
% pars.PKDURATION      = 1.0;  % Pulse lifetime period (suggest: 2 ms MAX)
% pars.REFRTIME        = 0.5;  % Refractory period (suggest: 2 ms MAX).
% pars.PKDETECT        = 'sneo';% 'both' or 'pos' or 'neg' or 'adapt' or 'sneo' for peak type
% pars.ALIGNFLAG       = 1;    % Alignment flag for detection
% % [0 -> highest / 1 -> most negative]
% pars.P2PAMP          = 60;   % Minimum peak-to-peak amplitude

% pars.ART_DIST        = 1/35; % Max. time between stimuli (sec)
% pars.NWIN            = 120;  % Number of windows for automatic thresholding
% pars.WINDUR          = 200*1e-3; % Minimum window length (msec)
% pars.INIT_THRESH     = 50;       % Pre-adaptive spike threshold (micro-volts)
% pars.ART_RATE        = 0.0035;   % Empirically determined rate for artifacts based on artifact rejection
% pars.M               = (-7/3);   % See ART_RATE
% pars.B               = 1.05;     % See ART_RATE
% 
% 
% % Parameters
% pars.MIN_SPK  = 100;       % Minimum spikes before sorting
% pars.TEMPSD   = 3.5;      % Cluster template max radius for template matching
% pars.TSCALE   = 3.5;      % Scaling for timestamps of spikes as a feature



%% User defined parameters for spike detection

pars.STIM_TS  = [];            % Pre-specified stim times
pars.ARTIFACT = [];            % Pre-specified artifact times
pars.MinSpikes = 100;          % Minimum number of spikes to compute feature detection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Spike Detection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pars.WPre = 0.4;  % Pre-spike window  (ms)
pars.WPost = 0.8;  % Post-spike window (ms)

pars.SDMethodName = 'SWTTEO';
pars.ID.Spikes = 'SWTTEO';                % implemented to date (2020/06/16):
                                        % SNEO, SWTTEO, WTEO, TIFCO, SWT, 
                                        % PTSD, fixed and variable Threshold.
                                        % See documentation for references.
                            
                                        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Artefact Rejection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                        
                            
pars.ArtefactRejMethodName = 'HardThresh';  
pars.ID.Artifact = 'HardThresh';        % implemented to date (2020/06/16):
                                        % HardThresh (hard threshold)


                                        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Feature Extraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                        
                                        
pars.ID.SpikeFeatures = 'wavelet';
pars.InterpSamples = 250;                     % Number of interpolated 
                                              % samples per spike. Can help
                                              % with feature extraction.
pars.FeatureExtractionMethodName = 'wavelet'; % implemented to date (2020/06/16):
                                              % wavelet, pca







%% UNLIKELY TO CHANGE
% Parameters for each type stored as individual files in ~/+SD
SDPath = fullfile(nigeLab.utils.getNigelPath,...
   '+nigeLab','+defaults','+SD');
% Load all the method-specific parameters:
SDConfigFiles = dir(fullfile(SDPath,'*.m'));
for ff = SDConfigFiles(:)'
   parName = ff.name(1:end-2); % dropping .m
   pars.(parName) = eval(sprintf('nigeLab.defaults.SD.%s',...
      parName));
end

%% Parse output
if nargin < 1
   varargout = {pars};
else
   varargout = cell(1,nargin);
   f = fieldnames(pars);
   for i = 1:nargin
      idx = ismember(lower(f),lower(varargin{i}));
      if sum(idx) == 1
         varargout{i} = pars.(f{idx});
      end
   end
end

end
