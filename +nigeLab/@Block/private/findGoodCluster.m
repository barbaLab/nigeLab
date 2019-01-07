function myCluster = findGoodCluster(varargin)
%% FINDGOODCLUSTER Find and/or wait for available workers.
%
%   myCluster = findGoodCluster('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin        :   (Optional) 'NAME', value input argument pairs.
%
%   ->  CLUSTER_LIST    :   Cell array containing strings that are 
%                           each of the clusters' names.
%                           Default: {'CPLMJS'; 'CPLMJS2'; 'CPLMJS3'};
%
%   ->  NWR             :   1 x 2 array of integers; [Nmin, Nmax], where 
%                           Nmin is the minimum number of workers to assign
%                           to a job and Nmax is the maximum number of 
%                           workers to assign. Default: [1, 4].
%
%   ->  WAIT_TIME       :   Number of seconds to wait between iterations.
%                           Default: 15 (seconds)
%
%   ->  INIT_TIME       :   Number of seconds to wait between iterations.
%                           Default: 60 (seconds)
%
%   --------
%    OUTPUT
%   --------
%   myCluster   :   Name of the currently available cluster
%                   
%   By: Daniel Rittle   v1.0    07/06/2017  Original Version
%       Max Murphy      v2.0    07/27/2017  Upgraded to check from list of
%                                           host machines, then assign job
%                                           to idle workers if there are
%                                           sufficient idle workers on a
%                                           given machine. Now takes input 
%                                           arguments to specify
%                                           CLUSTERLIST, NUMWORKERSRANGE,
%                                           and WAITTIME.

%% DEFAULTS
CLUSTER_LIST = {'CPLMJS'; ...
                'CPLMJS2'; ...   % Names of MJS cluster profiles
                'CPLMJS3'};      
           
NWR = [1, 1];                    % Min and Max # workers for job

WAIT_TIME = 15;                  % Wait between loops (seconds)

INIT_TIME = 60;                  % Wait before loop (seconds)

%% PARSE VARARGIN
for iV = 1:2:numel(varargin) % allow optional specification of parameters
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% INFINITELY LOOP UNTIL A CLUSTER IS ASSIGNED
% Create dummy variable because it is referenced several times
N = numel(CLUSTER_LIST);
myCluster = cell(N,1);  % pre-allocate cell for MJS objects
for iC = 1:N
    myCluster{iC,1} = parcluster(CLUSTER_LIST{iC}); % get MJS objects
end
pause(INIT_TIME); % Make sure it has time to process previous commands
AssignedCluster = false; % Just to keep the infinite loop going
while ~AssignedCluster
    for iC = 1:N
        % All logic reduced to 1 line:
        if myCluster{iC,1}.NumIdleWorkers >= min(NWR)
            myCluster = myCluster{iC,1}.Profile;
            AssignedCluster = true; % Actually unnecessary; for clarity
            break;
        end
        pause(WAIT_TIME); % I think this reduces the loop processing burden
    end
    
end


end