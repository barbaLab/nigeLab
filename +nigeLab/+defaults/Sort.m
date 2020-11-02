function varargout = Sort(varargin)
%SORT      Template for initializing params for Spike Sorting UI
%
%   pars = nigeLab.defaults.Sort;

% Defaults for SORT parameters
pars = struct;                   % carries all parameter variables

% Defaults for UI usability
pars.InFileFilt     = {'*_Block.mat';'*_Animal.mat';'*_Tank.mat'};
pars.InFilePrompt   = 'Select BLOCK(S), ANIMAL(S), or TANK';
pars.InFileDefDir   = 'P:\Rat';

pars.ID.Sorted      = 'Manual'; % Label attached to the Sorted folder 

pars.ForceNext = false; % Automatically jump to next channel on "confirm"
pars.Debug = false;  % Set to TRUE to move handles to base workspace

pars.SpikePlotN = 9;      % Max. # clusters (per clustering algorithm)
pars.SpikePlotYLim = [-250 150];  % Spike axes y-limits
pars.SpikePlot = 150;             % Max. # Spikes to plot
pars.SpikePlotXYExtent = [0.975, 0.925]; % [X, Y] norm. limits on figure
pars.SpikePlotSpacing = 0.035;      % Spacing between spike plot elements
pars.SpikePlotLabOffset = 0.03;     % Offset for spike plot label (heigh)

% Defaults for displaying cluster "type/tag" labels
pars.TagOpts = {'';...
            'Multi';...
            'FS';...
            'RS';...
            'Unsure';...
            'SU-Large';...
            'SU-Med';...
            'SU-Small';...
            'Stim';...
            '60Hz';...
            'Noise';...
            'Other1';...
            'Other2';...
            'Other3'};
pars.TagInit = [11,2,7,ones(1,6)];
pars.TagSpikes = [0,1,1,1,0,1,1,1,0,0,0,0,0,0];
pars.ClusterColors =   {[0.00,0.00,0.00];...
                        [0.20,0.20,0.90];...
                        [0.80,0.20,0.20];...
                        [0.90,0.80,0.30];...
                        [0.10,0.70,0.10];...
                        [1.00,0.00,1.00];...
                        [0.93,0.69,0.13];...
                        [0.30,0.95,0.95];...
                        [0.00,0.45,0.75]};

% Defaults for manipulating based on cluster qualities in feature space
pars.DistMethod = 'L2'; % Method for computing distance (defunct)
pars.DistRadius = 0.75; % Initial radius for keeping clusters (defunct)
pars.DistSDMax = 4;     % Max # SD to allow from medroid (defunct)
pars.DistSDMin = 0;     % Min # SD to allow from medroid (defunct)

% Defaults for plotting feature scatters
pars.FeatTRes = 1;            % Time resolution (in minutes)
pars.FeatTTick = 5;           % # Z-tick (time ticks)
pars.FeatPointsMax = 2000;    % Max. # feature points to plot
pars.FeatView = [-5 13];      % 3-D view angle
pars.FeatMinSpikes = 30;      % Minimum # spikes in order to plot

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

