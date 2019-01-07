function flag = initParams(sortObj)
%% INIT Initialize handles structure for Combine/Restrict Cluster UI.
%
%  flag = INITPARAMS(sortObj);
%
% By: Max Murphy  v3.0    01/07/2019 Port to object-oriented architecture.
%                 v2.0    10/03/2017 Added ability to handle multiple input
%                                    probes with redundant channel labels.
%                 v1.0    08/18/2017 Original version (R2017a)

%% MODIFY SORT CLASS OBJECT PROPERTIES HERE
flag = false;

% Defaults for handles
pars = struct;                   % carries all parameter variables
pars.OUT_ID  = 'Sorted';         % output folder ID
pars.IN_ID   = 'Clusters';       % input folder ID
pars.DEF_DIR = 'P:\Rat';         % Default directory to look
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
pars.FUNC    = 'CRC.m';
pars.SRCPATH = fileparts(which(pars.FUNC));
pars.OUTDIR  = 'out';    % Artifact spikes folder
pars.INDIR   = 'in';     % Good spikes folder
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

%% COULD ADD PARSING FOR PROPERTY VALIDITY HERE?
% To look into for future...

%% UPDATE PARS PROPERTY
sortObj.pars = pars;
flag = true;

end