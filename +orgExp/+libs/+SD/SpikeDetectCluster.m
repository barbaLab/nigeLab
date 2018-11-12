function SpikeDetectCluster(varargin)
%% SPIKEDETECTCLUSTER  Detect spikes and group into potential unit clusters
%
%     SPIKEDETECTCLUSTER('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%
%   varargin    :   (Optional) 'NAME', value input argument pairs
%                   corresponding to constants appearing in DEFAULTS
%                   section.
%
%   --------
%    OUTPUT
%   --------
%   File structure at specified location containing a folder with the
%   raw per-channel data, a folder with the filtered and re-referenced 
%   per-channel data, a folder with the raw detected spikes, and a folder
%   with the per-channel spikes split out by putative cluster (from SPC).
%
% By: Max Murphy    v4.1.1  01/25/2017  Added 'DO_AUTO_CLUSTERING'
%                                       parameter in case user wants to
%                                       only run spike detection and then
%                                       do manual sorting using CRC.m
%                                       later (possibly saves time).
%                   v4.1.0  01/04/2017  Added SNEO to try and improve
%                                       detection in high-noise recordings
%                                       where many spikes are missed.
%                   v4.0.0  12/13/2017  Adding adaptive thresholding to
%                                       account for periods of high noise
%                                       during long recordings.
%                   v3.3.0  08/14/2017  Added spike time as a feature for
%                                       SPC, allowing SPC to "track"
%                                       clusters through time in order to
%                                       assign good clusters. Increased
%                                       number of Swendsen-Wang cycles
%                                       (SWCYC) from 100 to 300 to help SPC
%                                       have enough iterations to converge.
%                   v3.2.0  08/11/2017  Cleaned up a lot of the old code to
%                                       remove things that were leftover
%                                       from v1.0. Completely changed the
%                                       way that clusters are formatted for
%                                       saves in order to reduce redundancy
%                                       with "spikes" files.
%                   v3.1.0  08/07/2017  Reverted from KMEANS to SPC, and
%                                       from 'mix' to 'wav'. Changed number
%                                       of wavelet inputs and mother
%                                       wavelet; appears to be doing SPC
%                                       much better now. Changed the way
%                                       that it estimates which wavelet
%                                       coefficients to use for SPC based
%                                       on sorting kurtosis of the wavelet
%                                       coefficient distribution. 
%                   v3.0.0  08/03/2017  Added independent components
%                                       analysis (ica) feature
%                                       decomposition. Added KMEANS option
%                                       for clustering. These seem to work
%                                       better than pca-SPC.
%                   v2.2.0  08/03/2017  Cleaned up some of the code, added
%                                       peak prominence (pp) and peak width
%                                       (pw) as variables to be saved in
%                                       the original spike detection
%                                       output. These are only acquired for
%                                       the 'neg' and 'pos' methods.
%                                       Added Init_SD function to organize
%                                       parameters at start.
%                   v2.1.1  08/02/2017  Changed TEMPSD to a 1x2 vector
%                                       that specifies the minimum and
%                                       maximum # SD for cluster radius
%                                       during template matching. The range
%                                       is set by the adaptive number of
%                                       PC's that gets selected due to the
%                                       % variance explained. Returned STAB
%                                       to 0.95 from 0.90.
%                   v2.1.0  08/02/2017  Changed PERMUT to 'y' so that the
%                                       spikes used in the first 2000
%                                       sets of features for generating the
%                                       cluster templates are randomized.
%                                       Added new spike detection methods
%                                       for isolating monopolar
%                                       (negative-going only or
%                                       positive-going only spikes).
%                                       Reduced ARTIFACT_THRESH from 1000
%                                       to 300. Reduced STAB to 0.90 from
%                                       0.95.
%                                       Increased REFRTIME from 1.5 to 2.0.
%                                       Reduced MAX_SPK from 20000 to 2000
%                                       and RMINCLUS from 0.05 to 0.001.
%                                       Reduced NMINCLUS from 100 to 30
%                                       (which was its original value).
%                   v2.0.0  08/01/2017  Added STIM_TS blanking capability.
%                                       Added ARTIFACT blanking capability.
%                                       Increased ARTIFACT_THRESH from 500
%                                       to 1000. 
%                                       Increased P2PAMP to 85 (tried 120 
%                                       and 100 but seemed too
%                                       restrictive).
%                                       Added DELETE_OLD_PATH as an option
%                                       Increased RMINCLUS from 0.005 to
%                                       0.05. Had tried to set this lower
%                                       but that seems to WAY increase the
%                                       run time and also decrease
%                                       performance.
%                   v1.8.3  07/31/2017  Increased PKDURATION from 1.2 to
%                                       1.6 ms.
%                   v1.8.2  07/30/2017  Increased PKDURATION from 0.75 to
%                                       1.2 ms. Increased TEMPSD from 1.0
%                                       to 1.2.
%                   v1.8.1  07/28/2017  Reverted to pca-PT since wav-PT
%                                       does not look good so far. Reverted
%                                       to 'center' from 'mahal'. Reduced
%                                       TEMPSD from 1.5 to 1.0.
%                   v1.8    07/28/2017  Changed PKDURATION from 0.55ms to
%                                       0.75 ms. Increased TEMPSD from 0.7
%                                       to 1.5. Returned TSTEP to 0.01 from
%                                       0.03. Changed feature-selection to
%                                       'wav'. Changed TEMPLATE to 'mahal'.
%                                       Updated SD folder name scheme to
%                                       reflect wav-PT instead of ad-PT.
%                   v1.7    07/27/2017  Changed a few defaults for skipping
%                                       UI prompts when not submitting the
%                                       detection to the cluster (to
%                                       facilitate future times when
%                                       clusters go down and everything has
%                                       to be done locally).
%                   v1.6    07/26/2017  Changed artifact threshold from 400
%                                       to 500. Reduced PKDURATION from 2 
%                                       ms to 0.55ms (think this was causing 
%                                       "up-swing" in tails of some spike
%                                       artifacts). Increased TSTEP from
%                                       0.01 to 0.03 for SPC in order to
%                                       improve the speed of the clustering
%                                       step. Increased NMINCLUSfrom 30
%                                       spikes to 100 spikes. Reduced
%                                       REFRTIME from 2 ms to 1.5 ms.
%                   v1.5    05/02/2017  Added options to include CAR 
%                                       handling. Added a bunch of
%                                       constants to correspond to string
%                                       "ID tags" for unique file type
%                                       identifiers (i.e. _ptrain_ etc).
%                   v1.4    03/29/2017  Removed check for 'R' in front of
%                                       extracted data name.
%                   v1.3    02/16/2017  Added some ability to deal with
%                                       improperly formatted or extracted
%                                       data files.
%                   v1.2    02/03/2017  Fixed it to run on clusters
%                                       properly. Also tweaked some of the
%                                       feature decomposition parameters,
%                                       and slightly modified the PTSD_core
%                                       compiled file to improve alignment.
%                   v1.1    02/02/2017  Switched CAR to after the bandpass
%                                       filter. Added _Raw_ and _Filt_ to
%                                       make raw and filtered
%                                       single-channel save names unique.
%                   v1.0    01/29/2017  Made old code more
%                                       cohesive/generalizable.

%% INITIALIZE PARAMETERS
pars = Init_SD(varargin);
warning('off','all'); % turn off all warnings

%% PATH INFORMATION
if pars.USE_CLUSTER % If on cluster, get path that cluster can "see"
    myJob = getCurrentJob;
    set(myJob,'Tag','Attaching worker files...');
    
    UNC_Paths = {'\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\', ...
                 '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data\'}; 
    pars.DIR = [UNC_Paths{1} ...
        pars.DIR((find(pars.DIR == filesep,1,'first')+1):end)]; 
    pars.SAVE_LOC = [UNC_Paths{1} ...
        pars.SAVE_LOC((find(pars.SAVE_LOC == filesep,1,'first')+1):end)]; 
    p  = gcp('nocreate');
    if isempty(p)
        p = parpool(max(myJob.NumWorkersRange), ...
                    'AttachedFiles',myJob.AttachedFiles);
    end
    clear UNC_Paths
    
    
else % Otherwise, make a local parallel pool
   
    if ~isfield(pars,'DIR')
        prompt = 'Select the folder containing extracted TDT data';
        pars.DIR = uigetdir(pars.DEF_DIR,prompt);
        if pars.DIR == 0
            errordlg('Selection Failed - End of Session', 'Error');
            return
        end
    end

    
    temp = strsplit(pars.DIR, filesep);
    
    test = fullfile(pars.DIR,[temp{end} '_Filtered*']);
    if isempty(test)
        pars.SAVE_LOC = strjoin(temp(1:end-1), filesep); clear temp
    else
        pars.SAVE_LOC = pars.DIR;
    end
    
    % Check for library directory
    if exist(pars.LIBDIR,'dir')==0
        pars.LIBDIR = uigetdir(pwd,'Select APP_Code Directory');
        if pars.LIBDIR==0
            error('Must select APP_Code directory containing sub-functions.');
        end
    end
    
    
end
if exist(pars.LIBDIR,'dir')~=0
    addpath(pars.LIBDIR);
end

paths = struct;

paths.SL = pars.SAVE_LOC; 
paths.TL = pars.DIR;  % Note: "TL" is for TANK_LOC, used previously

Name = strsplit(pars.DIR,filesep);
Name = Name{end};
paths.N = Name;


paths.FF = [paths.N pars.FILT_ID]; % Filtered folder
exp = dir(fullfile(pars.DIR,paths.FF,pars.ED_ID));
exp = {exp.name}.';             % Get names of extracted data (mat) files
temp = strsplit(exp{1}, '_'); 
Ch_check = find(strcmp(temp,'Ch'),1,'first');
paths.E = exp; 
paths.RF = [paths.N pars.RAW_ID]; % Raw folder

%% GET PROBE/SITE LAYOUT INFO FROM FILENAME FORMATTING

if pars.USE_CLUSTER
    set(myJob,'Tag',['Getting layout info for ' Name '...']);
end

if ~isempty(Ch_check)
    P_check = ls(fullfile(paths.SL,paths.FF,'\*P*.mat'));
    nProbes = numel(unique(P_check(:,end-11))); 
    if nProbes > 0
        CHANS = cell(nProbes,3);
        for iP = 1:nProbes
            CHANS{iP,3} = ['P' num2str(iP)];
            if iP == 1
                CHANS{iP,1} = 'Wave';
            else
                CHANS{iP,1} = ['Wav' num2str(iP)];
            end
        end
    else
        nProbes = 1;
        if abs(size(CHANS,1)-1)>eps %#ok<NODEF>
            error(['No P# naming convention on input files.' ...
                   'Must specify probe layout in CHANS input.']);
        end
    end


    for iCh = 1:numel(paths.E)
        temp = strsplit(paths.E{iCh}(1:(end-4)), '_');
        iP = str2double(temp{end-2}(2:end));
        ch = str2double(temp{end});
        CHANS{iP,2} = [CHANS{iP,2}, ch];

    end
    pars.CHANS = CHANS;
    clear temp P_check Ch_check Name ch iP iCh

end


if pars.USE_CAR % "Peaks" folder (spikes folder)
    paths.PF = [paths.N '_' pars.SD_VER '_CAR' pars.SPIKE_ID];
else
    paths.PF = [paths.N '_' pars.SD_VER pars.SPIKE_ID];
end
if pars.USE_CAR % "Sorted" folder (clusters folder)
    paths.SF = [paths.N '_' pars.SD_VER '_' pars.SC_VER '_CAR' pars.SORT_ID];
else
    paths.SF = [paths.N '_' pars.SD_VER '_' pars.SC_VER pars.SORT_ID];
end

% Check existence of spike folder
if ~exist(fullfile(paths.SL,paths.PF),'dir')
    mkdir(fullfile(paths.SL,paths.PF))
elseif (pars.DELETE_OLD_PATH && ~pars.USE_EXISTING_SPIKES)
    rmdir(fullfile(paths.SL,paths.PF),'s'); % remove old
    mkdir(fullfile(paths.SL,paths.PF));
end

 % Check for save directory (or overwrite old contents) for clusters
if ~exist(fullfile(paths.SL,paths.SF),'dir')
    mkdir(fullfile(paths.SL,paths.SF))
elseif pars.DELETE_OLD_PATH
    rmdir(fullfile(paths.SL,paths.SF),'s'); % remove old
    mkdir(fullfile(paths.SL,paths.SF));
end


%% SPIKE DETECTION
for iP = 1:nProbes % For each "probe index" ...
    SiteLayout = pars.CHANS{iP,2};        
    nCh = numel(SiteLayout);

    spk = cell(nCh,1);
    if pars.USE_CLUSTER
        set(myJob,'Tag',['Detecting spikes for ' paths.N '...']);
    else
        disp('Beginning spike detection...'); %#ok<*UNRCH>
    end

    FS = nan(nCh,1);
    Fspk = dir(fullfile(paths.SL, ...
        paths.PF,['*' pars.SPIKE_DATA '*.mat']));
    if (~isempty(Fspk) && pars.USE_EXISTING_SPIKES)
        for ii = 1:numel(Fspk)
            tempname = strsplit(Fspk(ii).name(1:end-4),'_');
            ind = find(ismember(tempname,'Ch'),1,'last')+1;
            iCh = str2double(tempname{ind});
            ch = find(abs(SiteLayout-iCh)<eps,1,'first');
            spk{ch} = load(fullfile(paths.SL, ...
                paths.PF,Fspk(ii).name));
            FS(ch) = spk{ch}.pars.FS;
        end
    else
        % Many low-memory computations; parallelize this
        if pars.USE_CLUSTER
            parfor iCh = 1:nCh % For each "channel index"...
                [spk{iCh},FS(iCh)] = PerChannelDetection( ...
                                  iP,SiteLayout(iCh),pars,paths);
            end
        else
            for iCh = 1:nCh % For each "channel index"...
                [spk{iCh},FS(iCh)] = PerChannelDetection( ...
                                  iP,SiteLayout(iCh),pars,paths);
            end
        end
    end
    
    pars.FS = FS(1); % Done this way because of the parfor
    clc;

%% AUTOMATED CLUSTERING/SORTING
   if pars.DO_AUTO_CLUSTERING
       if pars.USE_CLUSTER
           set(myJob,'Tag',['Clustering spikes for ' paths.N '...']);
       else
           disp('Beginning automated sorting...')
       end

       if pars.USE_CLUSTER
           parfor iCh = 1:nCh % For each "channel index" ...
               % Perform SPC
               cluster_exe = sprintf('cluster_%03d.exe',SiteLayout(iCh));
               if exist(fullfile(pwd,cluster_exe),'file')~=0
                   delete(fullfile(pwd,cluster_exe));
               end


               if pars.USE_TS_FEATURE %#ok<PFBNS>
                  ts = find(spk{iCh,1}.peak_train);
                  features = [spk{iCh,1}.features, ...
                              ts./max(ts)*pars.TSCALE];
               else
                  features = spk{iCh,1}.features;
               end

               SPC_results = SpikeCluster_SPC(features,...
                                          SiteLayout(iCh), ...
                                          pars);

               fname = sprintf('P%d_Ch_%03d.mat',iP,SiteLayout(1,iCh)); %#ok<PFBNS>
               newname = [paths.N pars.CLUS_DATA fname]; %#ok<PFBNS>

               parsavedata(fullfile(paths.SL,paths.SF,newname), ...
                   'class',SPC_results.class,...
                   'clu',  SPC_results.clu,...
                   'tree', SPC_results.tree, ...
                   'pars', SPC_results.pars);

               if exist(cluster_exe,'file')~=0
                   delete(cluster_exe);
               end
           end
       else
           for iCh = 1:nCh % For each "channel index" ...
               % Perform SPC
               cluster_exe = sprintf('cluster_%03d.exe',SiteLayout(iCh));
               if exist(fullfile(pwd,cluster_exe),'file')~=0
                   delete(fullfile(pwd,cluster_exe));
               end

               SPC_results = SpikeCluster_SPC(spk{iCh,1}.features,...
                                          SiteLayout(iCh), ...
                                          pars);

               fname = sprintf('P%d_Ch_%03d.mat',iP,SiteLayout(1,iCh)); 
               newname = [paths.N pars.CLUS_DATA fname]; 

               parsavedata(fullfile(paths.SL,paths.SF,newname), ...
                   'class',SPC_results.class,...
                   'clu',  SPC_results.clu,...
                   'tree', SPC_results.tree, ...
                   'pars', SPC_results.pars);

               if exist(cluster_exe,'file')~=0
                   delete(cluster_exe);
               end
           end
       end

       % Delete any files that weren't properly removed
       delete('*.param'); 
       delete('*.mag');
       delete('*.edges');
       delete('*.run');
   end

end

%% SHUTDOWN AND NOTIFY USER
if pars.USE_CLUSTER
    set(myJob,'Tag',['Complete: detect and cluster spikes for ' paths.N]);
else
    clc;
    disp('Completed automated pre-processing for the following files:');
    disp('-----------------------------');
    disp(paths.E);
    disp('-----------------------------');
    disp('Total time elapsed:');
end

warning('on','all'); % turn warnings back on

end