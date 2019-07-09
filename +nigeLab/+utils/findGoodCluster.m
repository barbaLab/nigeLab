function myCluster = findGoodCluster(Cluster)
%% FINDGOODCLUSTER Find and/or wait for available workers.
%
%   myCluster = findGoodCluster() % Automatically find first cluster
%                                 % with available workers from ClusterList
%
%   myCluster = findGoodCluster(Cluster) % Forces to use Cluster once
%                                        % available.
%
%   --------
%    INPUTS
%   --------
%    Cluster    :  Matlab Cluster object (optional)
%
%   --------
%    OUTPUT
%   --------
%   myCluster   :  Currently available cluster
%
%   By: Daniel Rittle   v1.0    07/06/2017  Original Version
%
%       Max Murphy      v2.0    07/27/2017  Upgraded to check from list of
%                                           host machines, then assign job
%                                           to idle workers if there are
%                                           sufficient idle workers on a
%                                           given machine. Now takes input
%                                           arguments to specify
%                                           CLUSTERLIST, NUMWORKERSRANGE,
%                                           and WAITTIME.
%
%       Max Murphy      v2.1   07/09/2019   Adapted for generalized use
%                                            with NigeLab package.

%% DEFAULTS
qParams = nigeLab.defaults.Queue;

% Note: modify these things in nigeLab/defaults/Queue.m
ClusterList = {'YourJobServerClusterNamesHere'};
if isfield(qParams,'ClusterList')
   ClusterList = qParams.ClusterList;
end

nWorkerMinMax = [1, 4];            % Min and Max # workers for job
if isfield(qParams,'nWorkerMinMax')
   nWorkerMinMax = qParams.nWorkerMinMax;
end

waitTimeSec = 15;                  % Wait between loops (seconds)
if isfield(qParams,'waitTimeSec')
   waitTimeSec = qParams.waitTimeSec;
end

initTimeSec = 60;                  % Wait before loop (seconds)
if isfield(qParams,'initTimeSec')
   initTimeSec = qParams.initTimeSec;
end

%% INFINITELY LOOP UNTIL A CLUSTER IS ASSIGNED
if nargin < 1
   % Create dummy variable because it is referenced several times
   N = numel(ClusterList);
   myCluster = cell(N,1);  % pre-allocate cell for MJS objects
   for iC = 1:N
      myCluster{iC,1} = parcluster(ClusterList{iC}); % get MJS objects
   end
   pause(initTimeSec); % Make sure it has time to process previous commands
   
   AssignedCluster = false; % Just to keep the infinite loop going
   while ~AssignedCluster
      for iC = 1:N
         % All logic reduced to 1 line:
         if myCluster{iC,1}.NumIdleWorkers >= min(nWorkerMinMax)
            myCluster = myCluster{iC,1};
            AssignedCluster = true; % Actually unnecessary; for clarity
            break;
         end
         pause(waitTimeSec); % I think this reduces the loop processing burden
      end
   end
   
else % Otherwise just make sure there are idle workers to assign
   while true
      % All logic reduced to 1 line:
      if Cluster.NumIdleWorkers >= min(nWorkerMinMax)
         myCluster = Cluster;
         break;
      end
      pause(waitTimeSec); % I think this reduces the loop processing burden
   end
   
end


end