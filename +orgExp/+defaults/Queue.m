function pars = Queue()
%% QUEUE  Template for initializing parameters for submitting jobs to queue
%
%   pars = defaults.Queue;
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
pars = struct;

% UNC path and cluster list for Matlab Distributed Computing Toolbox
pars.UNCPath = {'\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data\'; ...
                '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\'};
pars.ClusterList = {'CPLMJS'; 'CPLMJS2'; 'CPLMJS3'};
pars.Cluster = 'CPLMJS';
% pars.Cluster = [];

end

