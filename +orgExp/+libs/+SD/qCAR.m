function qCAR(varargin)
%% QCAR     Queue adHocCAR to run on an Isilon cluster.
%
%   QCAR('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin        (Optional) 'NAME', value input argument pairs.
%
%                   -> 'DIR' (def: none; specify as string that is the
%                                  BLOCK directory path).
%
%                   -> 'FIND_CLUSTER' (def: true; set false if you don't
%                                           want it to automatically look
%                                           for a cluster to use)
%
%                   -> 'CLUSTER' (def: 'CPLMJS2'; specifies the cluster to
%                                                use, but only if
%                                                FIND_CLUSTER is false).
%
%   --------
%    OUTPUT
%   --------
%   Submits adHocCAR job to the specified Isilon cluster. Useful for
%   performing CAR on long multi-channel recordings that can't be fully
%   loaded onto a local machine.
%
% By: Max Murphy    v1.2	12/13/2017	Fixed adHocCAR and associated
%                                      parameters in qCAR.
%                   v1.1    07/26/2017  Added FIND_CLUSTER and
%                                       findGoodCluster. Added
%                                       documentation for varargin. Changed
%                                       NumWorkersRange property for job to
%                                       be [2 4] because having many
%                                       workers can slow down the task by
%                                       forcing to create many copies of
%                                       the large files.
%                   v1.0    06/03/2017  Original version (R2017a)
%   See also: ADHOCCAR, QSD

%% DEFAULTS
% For qCAR use
DEF_DIR = 'P:\Rat';     % Default directory for UI prompt

% For finding clusters
CLUSTER_LIST = {'CPLMJS2'; 'CPLMJS3'}; % MJS cluster profiles
NWR          = [1,2];     % Number of workers to use
WAIT_TIME    = 4;        % Wait time for looping if using findGoodCluster
INIT_TIME    = 2;         % Wait time before initializing findGoodCluster
ASSIGN_DELAY = 4;        % Delay time after starting job, to allow worker 
                          % assignment to complete.

% Other
FS = 24414.0625;        % Default sampling frequency (if not found; should
                        % only affect really files using the earliest
                        % extraction versions).

%% PARSE INPUT
TEMP_ARGS = cell(1,numel(varargin));
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
    TEMP_ARGS{iV} = varargin{iV};
    TEMP_ARGS{iV+1} = varargin{iV+1};
end

%% SELECT RECORDING
if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR, ...
        'Select recording block to re-reference');
    if DIR == 0
        error('Must select a directory.');
    end
    
end

if exist(DIR,'dir')==0
    error('Invalid directory name. Check path.');
end

%% CREATE JOB AND SUBMIT TO ISILON
IN_ARGS = {'FS', FS, 'DIR', DIR,'USE_CLUSTER',true};
IN_ARGS = [IN_ARGS, TEMP_ARGS];
Name = strsplit(DIR, filesep);
Name = Name{end};

% Get current time
if exist('TIC','var')==0
    tStartJob = tic;
else
    tStartJob = TIC;
end

fprintf(1,'\n\tCreating job...');
if exist('CLUSTER','var')==0 % Otherwise, use "default" profile
    fprintf(1,'Searching for Idle Workers...');
    CLUSTER = findGoodCluster('CLUSTER_LIST',CLUSTER_LIST,...
                              'NWR',NWR, ...
                              'WAIT_TIME',WAIT_TIME, ...
                              'INIT_TIME',INIT_TIME);
    fprintf(1,'Beating them into submission...');
end
myCluster = parcluster(CLUSTER);
AttachedFiles = which('parsave.m');
myJob     = createCommunicatingJob(myCluster, ...
          'Type','pool', ...
          'Name', ['qCAR ' Name], ...
          'AttachedFiles',AttachedFiles, ...
          'NumWorkersRange',NWR, ...
          'FinishedFcn',@JobFinishedAlert, ...
          'Tag', ['Queued: ad hoc Common Average Re-reference for ' Name]);
createTask(myJob,@adHocCAR,0,IN_ARGS);
fprintf(1,'complete. Submitting to %s...\n',CLUSTER);
submit(myJob);
fprintf(1,'\n\n\n----------------------------------------------\n\n');
wait(myJob, 'queued');
fprintf(1,'Queued job:  %s\n',Name);
fprintf(1,'\n');
wait(myJob, 'running');
fprintf(1,'\n');
fprintf(1,'->\tJob running.\n');
pause(ASSIGN_DELAY); % Needs up to 1 minute to register all worker assignments.
fprintf(1,'Using Server: %s\n->\t %d/%d workers assigned.\n', ...
        CLUSTER,...
        myCluster.NumBusyWorkers, myCluster.NumWorkers);

fprintf(1,'Job [%s] submitted to server. Total time elapsed:\n', Name);
ElapsedTime(tStartJob);

end