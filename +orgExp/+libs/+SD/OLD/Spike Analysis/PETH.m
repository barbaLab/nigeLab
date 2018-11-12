function [RateData,info] = PETH(varargin)
%% PETH Construct peri-event time histogram and get smoothed rate for all
%
%   PETH('NAME', value, ...)
%
%   --------
%    INPUTS
%   --------
%   varargin        :       'NAME', value optional input argument pairs.
%                           --------------------------------------------
%                           'NAME' : String specifying directory with split
%                                    clusters. If left empty (default), a
%                                    dialog box will prompt user for the
%                                    correct directory.
%
%   --------
%    OUTPUT
%   --------
%   Creates figure of the PETH for each cluster and gets smoothed rate
%   estimate, as well as evaluating whether cell is excited or inhibited
%   relevant to behavioral event.
%
%   RateData        :       Table output containing information about
%                           smoothed peri-event spike rates as well as
%                           nature of putative cell cluster (i.e.
%                           inhibited or excited, relative to event).
%
%      info         :       Information such as the number of events of a
%                           particular kind, etc.
%
% See also: SORTCLUSTERS, MERGEWAVES, ALIGN, PLOTSPIKERASTER
%   By: Max Murphy  v1.1 02/08/2016     Modified selection criterion for
%                                       thresholding which PETH are used.
%                   v1.0 12/28/2016     Original Version (R2016b)

%% DEFAULTS
% Constructing peri-event time histogram
BINSIZE = 0.025;                         % Bin size (sec): per Hyland '98
E_PRE   = 4;                             % Pre-event time (sec)
E_POST  = 2;                             % Post-event time (sec)
FS      = 24414.0625;                    % Sampling frequency
YMAX    = 80;                            % Max rate to plot
LO_RATE = 5;                             % This and under are "low rate"
LO_PK   = 10;                            % If "low rate," but has big peak
OVERWRITE = false;                        % Overwrite existing figures
GENFIG    = false;                        % Make figures

% Inclusion/exclusion
PROP_SIG = 0.025;                        % Proportion significantly active
                                         % (i.e. above or below a threshold
                                         %       for activity)
SD_SCL = 2.5;                            % Number of SD from mean   
WN = 0.2;   % Lowpass normalized cut-off frequency
RP = 0.001; % Passband ripple
RS = 60;    % Stopband attenuation
F_ORD = 8;  % Filter order

% Directory information
IDIR  = 'Data/Aligned';                          % Input data directory

G_ID  = 'graspdata';                             % Grasp data ID
C_ID  = 'clusterdata';                           % Cluster data ID
O_ID  = 'histdata';                              % Output data ID
F_ID  = 'PETH';                                  % Figure ID

%% PARSE VARARGIN
for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% SELECT FILES
% If pre-specified in optional arguments, skip this step.
if exist('NAME', 'var') == 0
    [NAME,~,~] = uigetfile(['*' G_ID '*.mat'], ...
                           'Select file corresponding to animal', ...
                           IDIR);
    NAME = NAME(1:16);
    
    if NAME == 0 % Must select a directory
        error('Must select a valid directory.');
    elseif exist([IDIR '/' NAME(1:5)], 'dir') == 0
        error('Must select a valid directory.');
    end
    
    load([IDIR '/' NAME(1:5) '/' NAME '_' G_ID '.mat']);
    load([IDIR '/' NAME(1:5) '/' NAME '_' C_ID '.mat']);
    
else    % If a pre-specified path exists, must be a valid path.
    
    if NAME == 0  % Must select a directory
        error('Must select a valid rat name.');
    elseif exist([IDIR '/' NAME(1:5)], 'dir') == 0
        error('Must select a valid rat name.');
    end
    
    load([IDIR '/' NAME(1:5) '/' NAME '_' G_ID '.mat']);
    load([IDIR '/' NAME(1:5) '/' NAME '_' C_ID '.mat']);

end

%% CONSTRUCT PERI-EVENT TIME HISTOGRAMS
nClusters = size(GraspData,1);
TVEC      = -E_PRE:BINSIZE:E_POST;
nBins     = numel(TVEC)-1;
nThresh   = round(nBins * PROP_SIG); 
[b,a]     = ellip(F_ORD,RP,RS,WN,'low');

% Pre-allocate storage variables
SuccessfulGrasp = zeros(nClusters,nBins);
SuccessfulReach = zeros(nClusters,nBins);
FailureGrasp    = zeros(nClusters,nBins);
FailureReach    = zeros(nClusters,nBins);

nSuccessfulGrasp = numel(GraspData.Successes{1});
nFailureGrasp    = numel(GraspData.Failures{1});
nSuccessfulReach = numel(GraspData.ReachSuccesses{1});
nFailureReach    = numel(GraspData.ReachFailures{1});

% Loop through and aggregate all spikes around events
h = waitbar(0, 'Please wait, constructing and smoothing PETHs...');
for iC = 1:nClusters
    
    x = GraspData.Successes{iC};
    for ii = 1:nSuccessfulGrasp
        temp = histcounts(x{ii},TVEC);
        SuccessfulGrasp(iC,:) = SuccessfulGrasp(iC,:) + temp;
    end    
    
    x = GraspData.Failures{iC};
    for ii = 1:nFailureGrasp
        temp = histcounts(x{ii},TVEC);
        FailureGrasp(iC,:) = FailureGrasp(iC,:) + temp;
    end 
    
    x = GraspData.ReachSuccesses{iC};
    for ii = 1:nSuccessfulReach
        temp = histcounts(x{ii},TVEC);
        SuccessfulReach(iC,:) = SuccessfulReach(iC,:) + temp;
    end 
    
    x = GraspData.ReachFailures{iC};
    for ii = 1:nFailureReach
        temp = histcounts(x{ii},TVEC);
        FailureReach(iC,:) = FailureReach(iC,:) + temp;
    end 
    
    waitbar(iC/nClusters);
end
delete(h);



%% GET RATE INFORMATION
TRec = size(ClusterData.SpikeTimes,2)/FS;
TRecVec   = 0:BINSIZE:TRec;
SpikeRate = nan(nClusters,1);
SpikeDev  = nan(nClusters,1);

for iC = 1:nClusters
    ts = find(ClusterData.SpikeTimes(iC,:))/FS;
    TrialBlocRate = histcounts(ts,TRecVec)/BINSIZE;
    RandBlocRate  = vec2mat(TrialBlocRate,nBins);
    SpikeRate(iC) = mean(mean(RandBlocRate));
    SpikeDev(iC)  = std(mean(RandBlocRate));
    clear ts TrialBlocRate RandBlocRate;
end


%% OUTPUTS
RateData = table(SuccessfulGrasp,FailureGrasp, ...
                 SuccessfulReach,FailureReach, ...
                 SpikeRate,SpikeDev);
             
info.nSuccessfulGrasp = nSuccessfulGrasp;
info.nFailureGrasp    = nFailureGrasp;
info.nSuccessfulReach = nSuccessfulReach;
info.nFailureReach    = nFailureReach; 
nrow = ceil(sqrt(nClusters));
ncol = nrow;
info.UseRows = cell(1,4);
info.Conditions = {'Successful Grasp', 'Failed Grasp', ...
                   'Successful Reach', 'Failed Reach'};

%% FIGURES
% Grasp successes
if GENFIG
    figure('Name', 'Grasp Success PETH', ...
               'Units', 'Normalized', ...
               'Position', [0.1 0.1 0.8 0.8], ...
               'Color', 'w');
end

DIR = [IDIR filesep NAME(1:5) filesep NAME];
if exist(DIR,'dir')==0
    mkdir(DIR);
end

for iC = 1:nClusters
    if GENFIG
        subplot(nrow,ncol,iC); ...
        bar(TVEC(1:end-1)+BINSIZE/2, ...
            RateData.SuccessfulGrasp(iC,:)/nSuccessfulGrasp/BINSIZE, ...
            1,'FaceColor','b','EdgeColor','b'); ...
        hold on;
        line([0 0],[0 YMAX], ...
             'Color', [0 0 0.8], ...
             'LineWidth', 2, ...
             'LineStyle', '--'); 

        line([min(TVEC) max(TVEC)], ...
             [RateData.SpikeRate(iC) RateData.SpikeRate(iC)], ...
             'Color', 'k', ...
             'LineWidth', 2, ...
             'LineStyle', '--');
    end
     
    dev = RateData.SpikeDev(iC);
    mu = RateData.SpikeRate(iC);
    smoothed = filtfilt(b,a,RateData.SuccessfulGrasp(iC,:)/nSuccessfulGrasp/BINSIZE);
    
    sortRate = sort(smoothed,'descend');
    
    if (((sortRate(nThresh)       > mu+dev*SD_SCL  || ...
          sortRate(end-nThresh+1) < mu-dev*SD_SCL) && ...
         mu > LO_RATE) || ...
         (mu <= LO_RATE && (max(smoothed) > LO_PK)))
        info.UseRows{1} = [info.UseRows{1}, iC];
    end

    
    if GENFIG
        plot(TVEC(1:end-1)+BINSIZE/2,smoothed,'LineWidth',3, ...
                           'Color',[0.9 0.9 0.9]);
        line([min(TVEC) max(TVEC)], ...
           [mu-dev*SD_SCL mu-dev*SD_SCL], ...
           'Color', 'm', ...
           'LineWidth', 2, ...
           'LineStyle', '-.');

        line([min(TVEC) max(TVEC)], ...
           [mu+dev*SD_SCL mu+dev*SD_SCL], ...
           'Color', 'm', ...
           'LineWidth', 2, ...
           'LineStyle', '-.');

        hold off;
        set(gca,'Xlim',[-E_PRE E_POST]); 
        set(gca,'Ylim',[0 YMAX]);
        title([ClusterData.Hemisphere(iC) ' ' ...
               ClusterData.ML(iC) ' ' ...
               ClusterData.Area(iC,:) ': ' ...
               ClusterData.Channel(iC,:) '-' ClusterData.ICMS{iC}]);
    end
end

if (OVERWRITE && GENFIG)
    suptitle([strrep(NAME,'_',' ') ': Successful Grasps']);
    savefig(gcf,[DIR filesep NAME '_successfulgrasp_' F_ID '.fig']);
    saveas(gcf,[DIR filesep NAME '_successfulgrasp_' F_ID '.jpeg']);
    delete(gcf);
else
    if exist([IDIR filesep NAME(1:5) filesep NAME '_successfulgrasp_' F_ID '.fig'], 'file')~=0
        movefile([IDIR filesep NAME(1:5) filesep NAME '_successfulgrasp_' F_ID '.fig'], ...
                 [DIR filesep NAME '_successfulgrasp_' F_ID '.fig']);
        movefile([IDIR filesep NAME(1:5) filesep NAME '_successfulgrasp_' F_ID '.jpeg'], ...
                 [DIR filesep NAME '_successfulgrasp_' F_ID '.jpeg']);
    end
end

% Grasp failures
if GENFIG
    figure('Name', 'Grasp Failure PETH', ...
               'Units', 'Normalized', ...
               'Position', [0.1 0.1 0.8 0.8], ...
               'Color', 'w');
end
 
for iC = 1:nClusters
    if GENFIG
        subplot(nrow,ncol,iC); ...
        bar(TVEC(1:end-1)+BINSIZE/2, ...
            RateData.FailureGrasp(iC,:)/nFailureGrasp/BINSIZE, ...
            1,'FaceColor','r','EdgeColor','r'); ...
        hold on;
        line([0 0],[0 YMAX], ...
             'Color', [0.8 0 0], ...
             'LineWidth', 2, ...
             'LineStyle', '--'); 

        line([min(TVEC) max(TVEC)], ...
             [RateData.SpikeRate(iC) RateData.SpikeRate(iC)], ...
             'Color', 'k', ...
             'LineWidth', 2, ...
             'LineStyle', '--');
    end
     
    dev = RateData.SpikeDev(iC);
    mu = RateData.SpikeRate(iC);
    smoothed = filtfilt(b,a,RateData.FailureGrasp(iC,:)/nFailureGrasp/BINSIZE);
    sortRate = sort(smoothed, 'descend');
    
    if (((sortRate(nThresh)       > mu+dev*SD_SCL  || ...
          sortRate(end-nThresh+1) < mu-dev*SD_SCL) && ...
         mu > LO_RATE) || ...
         (mu <= LO_RATE && (max(smoothed) > LO_PK)))
        info.UseRows{2} = [info.UseRows{2}, iC];
    end
    
    if GENFIG
        plot(TVEC(1:end-1)+BINSIZE/2,smoothed,'LineWidth',3, ...
                           'Color',[0.9 0.9 0.9]);
        line([min(TVEC) max(TVEC)], ...
           [mu-dev*SD_SCL mu-dev*SD_SCL], ...
           'Color', 'm', ...
           'LineWidth', 2, ...
           'LineStyle', '-.');

        line([min(TVEC) max(TVEC)], ...
           [mu+dev*SD_SCL mu+dev*SD_SCL], ...
           'Color', 'm', ...
           'LineWidth', 2, ...
           'LineStyle', '-.');

        hold off;
        set(gca,'Xlim',[-E_PRE E_POST]); 
        set(gca,'Ylim',[0 YMAX]);
        title([ClusterData.Hemisphere(iC) ' ' ...
               ClusterData.ML(iC) ' ' ...
               ClusterData.Area(iC,:) ': ' ...
               ClusterData.Channel(iC,:) '-' ClusterData.ICMS{iC}]);
    end
end
if (GENFIG && OVERWRITE)
    suptitle([strrep(NAME,'_',' ') ': Failed Grasps']);
    savefig(gcf,[DIR filesep NAME '_failuregrasp_' F_ID '.fig']);
    saveas(gcf,[DIR filesep NAME '_failuregrasp_' F_ID '.jpeg']);
    delete(gcf);
else
    if exist([IDIR filesep NAME(1:5) filesep NAME '_failuregrasp_' F_ID '.fig'], 'file')~=0
        movefile([IDIR filesep NAME(1:5) filesep NAME '_failuregrasp_' F_ID '.fig'], ...
                 [DIR filesep NAME '_failuregrasp_' F_ID '.fig']);
        movefile([IDIR filesep NAME(1:5) filesep NAME '_failuregrasp_' F_ID '.jpeg'], ...
                 [DIR filesep NAME '_failuregrasp_' F_ID '.jpeg']);
    end
end

% Reach successes
if GENFIG
    figure('Name', 'Reach Success PETH', ...
               'Units', 'Normalized', ...
               'Position', [0.1 0.1 0.8 0.8], ...
               'Color', 'w');
end
    
for iC = 1:nClusters
    if GENFIG
        subplot(nrow,ncol,iC); ...
        bar(TVEC(1:end-1)+BINSIZE/2, ...
            RateData.SuccessfulReach(iC,:)/nSuccessfulReach/BINSIZE, ...
            1,'FaceColor','b','EdgeColor','b'); ...
        hold on;
        line([0 0],[0 YMAX], ...
             'Color', [0 0 0.8], ...
             'LineWidth', 2, ...
             'LineStyle', '--'); 
        line([min(TVEC) max(TVEC)], ...
             [RateData.SpikeRate(iC) RateData.SpikeRate(iC)], ...
             'Color', 'k', ...
             'LineWidth', 2, ...
             'LineStyle', '--');
    end
     
    dev = RateData.SpikeDev(iC);
    mu = RateData.SpikeRate(iC);
    smoothed = filtfilt(b,a,RateData.SuccessfulReach(iC,:)/nSuccessfulReach/BINSIZE);
    sortRate = sort(smoothed, 'descend');
    
    if (((sortRate(nThresh)       > mu+dev*SD_SCL  || ...
          sortRate(end-nThresh+1) < mu-dev*SD_SCL) && ...
         mu > LO_RATE) || ...
         (mu <= LO_RATE && (max(smoothed) > LO_PK)))
        info.UseRows{3} = [info.UseRows{3}, iC];
    end
    
    if GENFIG
        plot(TVEC(1:end-1)+BINSIZE/2,smoothed,'LineWidth',3, ...
                           'Color',[0.9 0.9 0.9]);
        line([min(TVEC) max(TVEC)], ...
           [mu-dev*SD_SCL mu-dev*SD_SCL], ...
           'Color', 'm', ...
           'LineWidth', 2, ...
           'LineStyle', '-.');

        line([min(TVEC) max(TVEC)], ...
           [mu+dev*SD_SCL mu+dev*SD_SCL], ...
           'Color', 'm', ...
           'LineWidth', 2, ...
           'LineStyle', '-.');
        hold off;
        set(gca,'Xlim',[-E_PRE E_POST]); 
        set(gca,'Ylim',[0 YMAX]);
        title([ClusterData.Hemisphere(iC) ' ' ...
               ClusterData.ML(iC) ' ' ...
               ClusterData.Area(iC,:) ': ' ...
               ClusterData.Channel(iC,:) '-' ClusterData.ICMS{iC}]);
    end
end

if (GENFIG && OVERWRITE)
    suptitle([strrep(NAME,'_',' ') ': Successful Reaches']);
    savefig(gcf,[DIR filesep NAME '_successfulreach_' F_ID '.fig']);
    saveas(gcf,[DIR filesep NAME '_successfulreach_' F_ID '.jpeg']);
    delete(gcf);
else
    if exist([IDIR filesep NAME(1:5) filesep NAME '_successfulreach_' F_ID '.fig'], 'file')~=0
        movefile([IDIR filesep NAME(1:5) filesep NAME '_successfulreach_' F_ID '.fig'], ...
                 [DIR filesep NAME '_successfulreach_' F_ID '.fig']);
        movefile([IDIR filesep NAME(1:5) filesep NAME '_successfulreach_' F_ID '.jpeg'], ...
                 [DIR filesep NAME '_successfulreach_' F_ID '.jpeg']);
    end
end

% Reach Failures
if GENFIG
    figure('Name', 'Reach Failure PETH', ...
               'Units', 'Normalized', ...
               'Position', [0.1 0.1 0.8 0.8], ...
               'Color', 'w');
end
    
for iC = 1:nClusters
    if GENFIG
        subplot(nrow,ncol,iC); ...
        bar(TVEC(1:end-1)+BINSIZE/2, ...
            RateData.FailureReach(iC,:)/nFailureReach/BINSIZE, ...
            1,'FaceColor','r','EdgeColor','r'); ...
        hold on;
        line([0 0],[0 YMAX], ...
             'Color', [0.8 0 0], ...
             'LineWidth', 2, ...
             'LineStyle', '--'); 
        line([min(TVEC) max(TVEC)], ...
             [RateData.SpikeRate(iC) RateData.SpikeRate(iC)], ...
             'Color', 'k', ...
             'LineWidth', 2, ...
             'LineStyle', '--');
    end
     
    dev = RateData.SpikeDev(iC);
    mu = RateData.SpikeRate(iC);
    smoothed = filtfilt(b,a,RateData.FailureReach(iC,:)/nFailureReach/BINSIZE);
    sortRate = sort(smoothed, 'descend');
    
    if (((sortRate(nThresh)       > mu+dev*SD_SCL  || ...
          sortRate(end-nThresh+1) < mu-dev*SD_SCL) && ...
         mu > LO_RATE) || ...
         (mu <= LO_RATE && (max(smoothed) > LO_PK)))
        info.UseRows{4} = [info.UseRows{4}, iC];
    end
    
    if GENFIG
        plot(TVEC(1:end-1)+BINSIZE/2,smoothed,'LineWidth',3, ...
                           'Color',[0.9 0.9 0.9]);
        line([min(TVEC) max(TVEC)], ...
           [mu-dev*SD_SCL mu-dev*SD_SCL], ...
           'Color', 'm', ...
           'LineWidth', 2, ...
           'LineStyle', '-.');

        line([min(TVEC) max(TVEC)], ...
           [mu+dev*SD_SCL mu+dev*SD_SCL], ...
           'Color', 'm', ...
           'LineWidth', 2, ...
           'LineStyle', '-.');
        hold off;
        set(gca,'Xlim',[-E_PRE E_POST]); 
        set(gca,'Ylim',[0 YMAX]);
        title([ClusterData.Hemisphere(iC) ' ' ...
               ClusterData.ML(iC) ' ' ...
               ClusterData.Area(iC,:) ': ' ...
               ClusterData.Channel(iC,:) '-' ClusterData.ICMS{iC}]);
    end
end

if (GENFIG && OVERWRITE)
    suptitle([strrep(NAME,'_',' ') ': Failed Reaches']);
    savefig(gcf,[DIR filesep NAME '_failurereach_' F_ID '.fig']);
    saveas(gcf,[DIR filesep NAME '_failurereach_' F_ID '.jpeg']);
    delete(gcf);
else
    if exist([IDIR filesep NAME(1:5) filesep NAME '_failurereach_' F_ID '.fig'], 'file')~=0
        movefile([IDIR filesep NAME(1:5) filesep NAME '_failurereach_' F_ID '.fig'], ...
                 [DIR filesep NAME '_failurereach_' F_ID '.fig']);
        movefile([IDIR filesep NAME(1:5) filesep NAME '_failurereach_' F_ID '.jpeg'], ...
                 [DIR filesep NAME '_failurereach_' F_ID '.jpeg']);
    end
end

save([DIR filesep NAME '_' O_ID '.mat'], 'RateData', 'info', ...
      '-v7.3');

end