function DIR = qSD(varargin)
%% QSD  Queue automated spike detection and clustering to Isilon cluster.
%
%   myTask = QSD('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs, as
%                   listed in INIT_SD. Some more common options are listed
%                   here.
%
%                   -> 'DIR'   :        (default - UI Selection)
%                                       Specifies location of block. 
%
%                   -> 'CLUSTER_LIST' : (default - {'CPLMJS2'; 'CPLMJS3'})
%                                       Can add CPLMJS if you are sure
%                                       nobody is using clusters, otherwise
%                                       leave that one available in case
%                                       extract needs to happen.
%
%                   -> 'USE_CAR'    :   (default - true) 
%                                       Set to false to disable  the 
%                                       virtual common-average 
%                                       re-reference. STRONGLY recommended
%                                       to use this for recordings with 16+
%                                       channels, but also STRONGLY
%                                       recommend to disable for less than
%                                       16 channels, as low channel counts
%                                       can cause physiological spikes to
%                                       be referred into non-spiking
%                                       channels.
%
%                   -> 'USE_EXISTING_SPIKES' : (default - false)
%                                              If spikes have already been
%                                              detected, and you just want
%                                              to do clustering on them.
%                                
%
%                   -> 'DO_AUTO_CLUSTERING' : (default - true)
%                                             Set false in order to skip
%                                             the SPC segment, which saves
%                                             time if you think that the
%                                             auto-sort won't make manual
%                                             curation/sorting any easier.
%
%                   -> 'TIC'        :  (default - NaN) 
%                                       Specify to use a "tic"
%                                       from prior to the start of function
%                                       execution.
%
%                   -> 'STIM_TS'    :  (default - NaN)
%                                       Specify as a vector of time
%                                       stamps (seconds) relative to the
%                                       start of the recordings. This will
%                                       be used in conjunction with
%                                       'PRE_STIM_BLANKING' and
%                                       'POST_STIM_BLANKING' to "zero out"
%                                       areas where there is known stimulus
%                                       delivery.)
%
%                   -> 'ARTIFACT'   :  (default - NaN) 
%                                       Specify as a 2xK matrix,
%                                       where K is the number of artifact
%                                       periods you wish to "blank" from
%                                       the data. Specify values as sample
%                                       indexes (integers). The top row is
%                                       the start of each blanked epoch and
%                                       the bottom row is the end of each
%                                       blanked epoch. Epochs do not need
%                                       to be the same length.
%
%                   -> 'DELETE_OLD_PATH' : (default - false) 
%                                           Set true to delete everything 
%                                           in the directory of old spike 
%                                           files that use the same spike
%                                           detection/clustering method as
%                                           the current run. Optional for
%                                           convenience if re-running
%                                           detection with modified
%                                           parameters.
%
%   --------
%    OUTPUT
%   --------
%   DIR         :   Location of large extraction files, or of smaller
%                   single-channel extractions for a single animal.
%
% See also: SPIKEDETECTCLUSTER, SPIKEDETECTIONARRAY, SPIKECLUSTER_SPC
%   By: Max Murphy  v2.0.1  01/25/2018  Updated documentation. Added option
%                                       to DO_AUTO_CLUSTERING, which
%                                       defaults to true, but can be set
%                                       false to skip SPC.
%                   v2.0.0  08/01/2017  Added STIM_TS blanking capability.
%                                       Added ARTIFACT blanking capability.
%                   v1.6.1  07/31/2017  Reduced available number of
%                                       workers, since passing to more
%                                       workers does not appear to improve
%                                       job completion speed. Need to
%                                       investigate why parellelization is
%                                       not working properly.
%                   v1.6    07/30/2017  Changed 'TANK_LOC' to 'DIR' for
%                                       consistency with other code.
%                   v1.5    07/27/2017  Fixed a few minor bugs with
%                                       useability issues. Improved the
%                                       ability to work in parallel on the
%                                       Isilon clusters with the updated
%                                       findGoodCluster code. -MM
%                   v1.4.1  07/06/2017  Testing possibility for
%                                       implementing findGoodCluster
%                                       function at line 165 -DR
%                   v1.4    06/10/2017  Allows the user to select just the
%                                       recording block instead of the
%                                       RawData folder specifically. Still
%                                       works if you select the RawData
%                                       folder. -MM
%                   v1.3    05/02/2017  Included USECAR option in passing
%                                       arguments to SPIKEDETECTCLUSTER.
%                                       Now just submits job but doesn't
%                                       delete it, so you don't wait for
%                                       jobs to complete that have been
%                                       submitted to the server. -MM
%                   v1.2    03/01/2017  Removed option to specify save
%                                       location for clusters. -MM
%                   v1.1    02/01/2017  Changed output to TANK_LOC so that
%                                       it is easier to keep track of what
%                                       has been run. -MM
%                   v1.0    01/31/2017  Original version -MM

%% DEFAULTS
% For finding clusters
CLUSTER_LIST = {'CPLMJS2'; 'CPLMJS3'}; % MJS cluster profiles
NWR = [1 4];              % Number of workers to use
WAIT_TIME = 15;           % Wait time for looping if using findGoodCluster
INIT_TIME = 2;            % Wait time for initializing findGoodCluster

% Default path for SPIKEDETECTCLUSTER:
[SD_PATH, ~] = fileparts(mfilename('fullpath'));
LIBDIR  = fullfile(SD_PATH,'APP_Code'); 
RAWDATA_ID = '_RawData';
SUBMIT  = true;
USE_CLUSTER = true;

% Default to Use CAR data
USE_CAR  = true;

% Default UI search paths for save and load:
DEF_DIR = 'P:';

% Other optional flags
TIC = nan;
STIM_TS = nan;
ARTIFACT = nan;

if exist(SD_PATH,'dir')==0
    SD_PATH(1) = 'T';
    LIBDIR(1) = 'T';
    DEF_DIR = 'T:';
    if exist(SD_PATH,'dir')==0
        error('Check SD_PATH variable.');
    end
end
addpath(SD_PATH);
addpath(LIBDIR);

%% USE UI TO GET DIRECTORY INFO
% Optional input arguments to be passed to SPIKEDETECTCLUSTER
IN_ARGS = {'LIBDIR', LIBDIR};

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) ' = varargin{iV+1};']);
    IN_ARGS{1,iV+2}             = upper(varargin{iV});      
    IN_ARGS{1,iV+3}             =       varargin{iV+1};     
end

%% CHECK FOR PATH INFO
if exist(LIBDIR,'dir')==0
    LIBDIR = uigetdir(pwd,'Select APP_Code Directory');
    if LIBDIR==0
        error('Must select APP_Code directory containing sub-functions.');
    end
    
end
IN_ARGS = [IN_ARGS, {'LIBDIR', LIBDIR,'USE_CAR',USE_CAR}];

if exist('DIR','var')==0
    prompt = 'Select recording BLOCK';
    DIR = uigetdir(DEF_DIR,prompt);
    if ~DIR
        errordlg('Selection Failed - End of Session', 'Error');
        return
    end
end
IN_ARGS = [IN_ARGS, {'DIR', DIR}]; clear temp;

fprintf(1,'\n\tDetecting spikes on channels in:\n\t%s\n', DIR);
IN_ARGS = [IN_ARGS, {'SAVE_LOC', DIR}];

%% ADD SPIKEDETECTCLUSTER AND LIBRARY TO PATH
if exist([SD_PATH '\SpikeDetectCluster.m'], 'file')==0
    SD_PATH = uigetdir(pwd,'Add path with SpikeDetectCluster.m');
    if SD_PATH==0
        error('Must select path.');
    end
    
    if exist([SD_PATH '\SpikeDetectCluster.m'], 'file')==0
        error('That path does not contain SpikeDetectCluster.m');
    end
end
addpath(SD_PATH);
addpath(LIBDIR);        

%% SUBMIT JOB/TASK TO SERVER QUEUE
if isnan(TIC)
    tStartJob = tic;
else
    tStartJob = TIC;
end

Name = strsplit(DIR, filesep);
Name = Name{end};


if USE_CLUSTER
   libs = what(LIBDIR);
   fprintf(1,'\n\tSearching for dependencies...');
   ATTACHEDFILES = ...
       matlab.codetools.requiredFilesAndProducts('SpikeDetectCluster.m');
   ATTACHEDFILES = [ATTACHEDFILES, which('cluster.exe'), ...
                                   which('SpikeDetection_PTSD_core.cpp'), ...
                                   which('SpikeDetection_PTSD_core.mex')];
   fprintf(1,'complete.\n');   
   
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
    myJob     = createCommunicatingJob(myCluster, ...
             'AttachedFiles', ATTACHEDFILES, ...
             'Name', ['qSD ' Name], ...
             'NumWorkersRange', NWR, ...
             'FinishedFcn', @JobFinishedAlert, ...
             'Type','pool', ...
             'Tag', ['Queued: spike detection and clustering for ' Name]);

    createTask(myJob,@SpikeDetectCluster,0,IN_ARGS);
    fprintf(1,'complete. Submitting to %s...\n',CLUSTER);
    submit(myJob);
    fprintf(1,'\n\n\n----------------------------------------------\n\n');
    wait(myJob, 'queued');
    fprintf(1,'Queued job:  %s\n',Name);
    fprintf(1,'\n');
    wait(myJob, 'running');
    fprintf(1,'\n');
    fprintf(1,'->\tJob running.\n');
    pause(60); % Needs about 1 minute to register all worker assignments.
    fprintf(1,'Using Server: %s\n->\t %d/%d workers assigned.\n', ...
        CLUSTER,...
        myCluster.NumBusyWorkers, myCluster.NumWorkers);
    

else    % Set USE_CLUSTER = false for DEBUG
    SpikeDetectCluster(IN_ARGS);
end

fprintf(1,'Job [%s] submitted to server. Total time elapsed:\n', Name);
ElapsedTime(tStartJob);

end