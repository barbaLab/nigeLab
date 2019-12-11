function par = SPC()


% Filenames
par.FNameIn = 'tmp_data';              % Input name for cluster.exe
par.FNameOut = 'data_tmp_curr.mat';    % Read-out from cluster.exe

% SPC PARAMETERS
par.AbsKNN = 15;                       % Absolute (min) K-Nearest Neighbors
par.RelKNN = 0.0001;                   % Relative K-Nearest Neighbors
% par.TSTEP = 0.001;      Unused??           % Increments for vector of temperatures
par.MaxTemp = 0.300;               % Max. temperature for SPC
par.MinTemp = 0;
par.NminClus = 3;                  % Absolute minimum cluster size diff
par.RminClus = 0.005;              % Relative minimum cluster size diff
par.MaxSpk = 1000;                  % Max. # of spikes for SPC
par.tempstep = 0.01;                 % temperature steps
par.SWCyc = 75;                      % SPC iterations for each temperature (default 100)
par.min_clus = 20;                   % minimum size of a cluster (default 20)
par.max_clus = 200;                  % maximum number of clusters allowed (default 200)
% par.randomseed = 0;                % if 0, random seed is taken as the clock value (default 0)
par.randomseed = 147;                % If not 0, random seed
%par.temp_plot = 'lin';              % temperature plot in linear scale
par.temp_plot = 'log';               % temperature plot in log scale

par.c_ov = 0.7;                      % Overlapping coefficient to use for the inclusion criterion.
par.elbow_min  = 0.4;                %Thr_border parameter for regime border detection.


% FEATURES PARAMETERS
par.min_inputs = 10;         % number of inputs to the clustering
par.max_inputs = 0.75;       % number of inputs to the clustering. if < 1 it will the that proportion of the maximum.
par.scales = 4;                        % number of scales for the wavelet decomposition
par.features = 'wav';                % type of feature ('wav' or 'pca')
%par.features = 'pca'


% TEMPLATE MATCHING
par.match = 'y';                    % force template matching if not assign by SPC
%par.match = 'n';                   % for no template matching
par.permut = 'y';                   % for selection of random 'par.MaxSpk' spikes before starting templ. match.
% par.permut = 'n';                 % for selection of the first 'par.max_spk' spikes before starting templ. match.
par.template_type = 'center';       % template matching strateg; nn, center, ml, mahal
par.force_feature = 'spk';          % feature use for forcing; spk,feat

par.template_sdnum = 3;             % max radius of cluster in std devs.
par.template_k = 10;                % # of nearest neighbors
par.template_k_min = 10;            % min # of nn for vote

