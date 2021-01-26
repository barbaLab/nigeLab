function varargout = SD(varargin)
%% defaults.SD    Initialize parameters for spike detection, Artefact rejection and feature extraction
%
%   pars = nigeLab.defaults.SD('NAME',value,...);
%
%   General SD pars are defined here as well as the default method to use.
%   To customize specific methods parameters, please refer to the SD folder
%   inside here
%
%
% By: MAECI 2018 collaboration (Max Murphy & Federico Barban)

pars = struct;


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
pars.ID.Spikes = 'SWTTEO';               % implemented to date (2020/06/16):
                                        % SNEO, SWTTEO, WTEO, TIFCO, SWT, 
                                        % PTSD, fixed and variable Threshold.
                                        % See documentation for references.
                            
                                        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Artefact Rejection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                        
                            
pars.ArtefactRejMethodName = 'HardThresh';  
pars.ID.Artifact = 'HardThresh';        % implemented to date (2020/06/16):
                                        % HardThresh (hard threshold) and
                                        % PowerThresh (power threshold)


                                        
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
