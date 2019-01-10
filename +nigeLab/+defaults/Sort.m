function pars = Sort()
%% SORT      Template for initializing params for Spike Sorting UI
%
%   pars = nigeLab.defaults.Sort;
%
% By: MAECI 2018 collaboration (MM, FB)

%% Defaults for SORT parameters
pars = struct;                   % carries all parameter variables
pars.OUT_ID  = 'Sorted';         % output folder ID
pars.IN_ID   = 'Clusters';       % input folder ID

% Defaults for selecting input files
pars.INFILE_FILT = {'*_Block.mat';'*_Animal.mat';'*_Tank.mat'};
pars.INFILE_PROMPT = 'Select BLOCK(S), ANIMAL(S), or TANK';
pars.INFILE_DEF_DIR = 'P:\Rat';     

pars.SDMAX = 4;                  % Max # SD to allow from medroid
pars.SDMIN = 0;                  % Min # SD to allow from medroid
pars.T_RES = 1;      % Time resolution (in minutes)
pars.NZTICK = 5;     % # Z-tick (time ticks)
pars.NPOINTS = 8;    % # circle edge points to plot
pars.DEBUG = false;  % Set to TRUE to move handles to base workspace
pars.MINSPIKES = 30; % Minimum # spikes in order to plot
pars.FORCE_NEXT = false; % Automatically jump to next channel on "confirm"
pars.DISTANCE_METHOD = 'L2';

% Probably don't change these parameters:
pars.TAG = {'';...
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
pars.INIT_TAG = [11,2,7,ones(1,6)];
pars.SPIKETAGS = [0,1,1,1,0,1,1,1,0,0,0,0,0,0];
pars.COLS =   {[0.00,0.00,0.00];...
               [0.20,0.20,0.90];...
               [0.80,0.20,0.20];...
               [0.90,0.80,0.30];...
               [0.10,0.70,0.10];...
               [1.00,0.00,1.00];...
               [0.93,0.69,0.13];...
               [0.30,0.95,0.95];...
               [0.00,0.45,0.75]};

pars.DELIM   = '_';      % Delimiter for parsing file name info
pars.SORT_ID = 'sort';   % Sort file ID
pars.SPK_ID  = 'ptrain'; % Spike file ID
pars.CLU_ID  = 'clus';   % Clusters file ID
pars.OUT_TAG_ID = 11;    % Index for "OUT" tag from cell in CRC_Labels.mat
pars.CL_IND  = 4;        % indices back from end for cluster #
pars.SPKF_IND = 2;       % '_' delimited index to remove for "spikes"
pars.SPKF_ID = 'Spikes'; % append to end of folder name for "spikes"
pars.SC_IND = 3;         % '_' delimited index for clustering method
pars.DEF_RAD = 0.75;     % Default cluster radius
pars.NCLUS_MAX = 9;      % Max. # clusters (per clustering algorithm)
pars.SPK_YLIM = [-250 150];  % Spike axes y-limits
pars.NSPK = 150;             % Max. # Spikes to plot

% Max X   Max Y
pars.SPK_AX = [0.975, 0.925];
pars.AX_SPACE = 0.035;

pars.NFEAT_PLOT_POINTS = 2000; % Max. # feature points to plot
pars.FEAT_VIEW = [-5 13]; % 3-D view angle

end

