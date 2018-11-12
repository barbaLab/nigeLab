function RunIntanExtraction(List)
%% RUNINTANEXTRACTION Submit list of Intan files to be extracted by cluster.
%
%   RUNINTANEXTRACTION(List)
%
%   --------
%    INPUTS
%   --------
%     List      :       N x 1 cell of names of *.rhd files to extract.
%
%   --------
%    OUTPUT
%   --------
%   Submits to the cluster queue in order to extract the raw and filtered,
%   as well as any digital and auxiliary streams in the *.rhd files
%   contained within List.
%
% By: Max Murphy    v1.0    01/31/2017

%% DEFAULTS

CLUSTER = 'CPLMJS3';   % CPLMJS has 16-workers but may get overridden
                       % CPLMJS2 and CPLMJS3 both have 8-workers. 
                       
ATTACHEDFILES = {'INTAN2single_ch.m'; ...
                 'ExtractIntanList.m'};
             
IN_ARGS = {List};

%% CREATE CLUSTER, JOB, and TASK
tStartJob = tic;

myCluster = parcluster(CLUSTER);
% IN_ARGS   = [IN_ARGS, {myCluster}];

myJob     = createCommunicatingJob(myCluster, ...
                                   'AttachedFiles', ATTACHEDFILES, ...
                                   'Type','pool');
                               
createTask(myJob,@ExtractIntanList,0,IN_ARGS);

%% SUBMIT TO QUEUE AND GIVE FEEDBACK WHEN COMPLETE
disp('Running job on server...');
submit(myJob);
wait(myJob, 'finished');
clc;
disp('Job complete. Total time elapsed:');
ElapsedTime(tStartJob);

%% CLOSE OBJECTS
delete(myJob);

end