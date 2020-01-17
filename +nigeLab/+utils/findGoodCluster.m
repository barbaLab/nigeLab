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
%    Cluster    :  Matlab Cluster object name (optional; char array)
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

NWorkerMinMax = [1, 4];            % Min and Max # workers for job
if isfield(qParams,'NWorkerMinMax')
   NWorkerMinMax = qParams.NWorkerMinMax;
end

WaitTimeSec = 15;                  % Wait between loops (seconds)
if isfield(qParams,'WaitTimeSec')
   WaitTimeSec = qParams.WaitTimeSec;
end

InitTimeSec = 60;                  % Wait before loop (seconds)
if isfield(qParams,'InitTimeSec')
   InitTimeSec = qParams.InitTimeSec;
end

%% Make sure the profiles are actually configured and available
% if no cluster profiles are available return the local one
ClusterList = intersect(ClusterList,parallel.clusterProfiles);
if isempty(ClusterList)
   myCluster = parcluster;
   return
end

%% INFINITELY LOOP UNTIL A CLUSTER IS ASSIGNED
if nargin < 1
   % Create dummy variable because it is referenced several times
   N = numel(ClusterList);
   myCluster = cell(N,1);  % pre-allocate cell for MJS objects
   for iC = 1:N
      myCluster{iC,1} = parcluster(ClusterList{iC}); % get MJS objects
   end
   pause(InitTimeSec); % Make sure it has time to process previous commands
   
   AssignedCluster = false; % Just to keep the infinite loop going
   while ~AssignedCluster
      for iC = 1:N
         % All logic reduced to 1 line:
         if myCluster{iC,1}.NumIdleWorkers >= min(NWorkerMinMax)
            myCluster = myCluster{iC,1};
            AssignedCluster = true; % Actually unnecessary; for clarity
            break;
         end
         pause(WaitTimeSec); % I think this reduces the loop processing burden
      end
   end
   
else % Otherwise just make sure there are idle workers to assign
   Cluster = parcluster(Cluster);
   pause(InitTimeSec);
   
   while true
      % All logic reduced to 1 line:
      if Cluster.NumIdleWorkers >= min(NWorkerMinMax)
         myCluster = Cluster;
         break;
      end
      pause(WaitTimeSec); % I think this reduces the loop processing burden
   end
   
end


end