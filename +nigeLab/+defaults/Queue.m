function pars = Queue()
%% QUEUE  Template for initializing parameters for submitting jobs to queue
%
%   pars = nigeLab.defaults.Queue;
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
pars = struct;

% Only specify this field if you want to force use of a single cluster
pars.Cluster = 'CPLMJS'; 
pars.UseParallel = true; % set to false to switch to serial processing mode

% UNC path and cluster list for Matlab Distributed Computing Toolbox
pars.UNCPath = {'\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data\'; ...
                '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\'};
pars.ClusterList = {'CPLMJS'; 'CPLMJS2'; 'CPLMJS3'};
pars.nWorkerMinMax = [1,4]; % Min & Max # workers to assign to a job
pars.waitTimeSec = 15; % Time to wait between checking for new cluster
pars.initTimeSec = 30; % Time to wait when initializing cluster


end

