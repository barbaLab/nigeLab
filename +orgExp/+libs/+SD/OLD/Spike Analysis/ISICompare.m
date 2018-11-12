function ISIdata = ISICompare(varargin)
%% ISICOMPARE  Compare inter-spike interval for whole vs. aligned recording
%
%   ISIdata = ISICompare('NAME',value,...)
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
%
%   --------
%    OUTPUT
%   --------
%   Mat file containing table ISIdata, which contains the ISI for each
%   cluster for the entire recording in addition to one ISI on the
%   shortened periods corresponding to event-alignment for each of the four
%   behaviors (grasp success/failure; reach success/failure). 
%
%
% See also: MERGEWAVES, SORTCLUSTERS, ALIGN
%   By: Max Murphy  v1.0    01/09/2017  Original Version

%% DEFAULTS
% ISI parameters
MAX_INTERVAL= 1;                     % Maximum inter-event interval (sec)
BINSIZE     = 0.0015;                % Bin window (sec)
FS          = 24414.0625;            % Sampling frequency (Hz)
MINRATE     = 5;                     % Minimum average rate for recording

% Directory info
MDIR  = 'Data/Processed Recording Files/Merged'; % Directory of names
ODIR  = 'Data/ISI';                              % Output directory
IDIR  = 'Data/Aligned';                          % Input directory
FDIR  = 'ClusterFigs';                           % Figure directory

G_ID  = 'graspdata';                             % Aligned data input ID
C_ID  = 'clusterdata';                           % Cluster data input ID
O_ID  = 'ISI';                                   % Selected data output ID

% Figure parameters
YLIM  = [0 0.050];                               % Y-limits for ISI
FTITLE= {'Full-Trial ISI';    ...
         'Grasp Success ISI'; ...
         'Grasp Failure ISI'; ...
         'Reach Success ISI'; ...
         'Reach Failure ISI'};
     
% Spike sample parameters
MAXSPIKES = 200;
TVEC = (0:31)/FS * 1000;

%% ADD HELPER FUNCTIONS
pname = mfilename('fullpath');
fname = mfilename;
pname = pname(1:end-length(fname));

addpath([pname 'libs']);
clear pname fname

%% PARSE VARARGIN
for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% SELECT RECORDING
% If pre-specified in optional arguments, skip this step.
if exist('NAME', 'var') == 0
    NAME = uigetdir(MDIR);
    NAME = strsplit(NAME, '\');
    NAME = NAME{end};
    
    if NAME == 0 % Must select a directory
        error('Must select a valid directory.');
    elseif exist([IDIR '/' NAME(1:5)], 'dir') == 0
        error('Must select a valid directory.');
    end
    
    G = dir([IDIR '/' NAME(1:5) '/' NAME '_' G_ID '.mat']);
    C = dir([IDIR '/' NAME(1:5) '/' NAME '_' C_ID '.mat']);
    
    if (isempty(G) || isempty(C)) % Must contain valid files
        error([MDIR '/' NAME ' does not contain any files formatted ' ...
               C_ID ' or ' G_ID '. Check SP_ID or verify that directory' ...
               ' contains appropriate files.']);
    end
    
else    % If a pre-specified path exists, must be a valid path.
    
    if NAME == 0 % Must select a directory
        error('Must select a valid directory.');
    elseif exist([IDIR '/' NAME(1:5)], 'dir') == 0
        error('Must select a valid directory.');
    end
    
    G = dir([IDIR '/' NAME(1:5) '/' NAME '_' G_ID '.mat']);
    C = dir([IDIR '/' NAME(1:5) '/' NAME '_' C_ID '.mat']);
    
    if (isempty(G) || isempty(C)) % Must contain valid files
        error([MDIR '/' NAME ' missing files formatted ' ...
               C_ID ' or ' G_ID '. Check SP_ID or verify that directory' ...
               ' contains appropriate files.']);
    end
end

%% LOAD DATA
G = load([IDIR '/' NAME(1:5) '/' G(1).name]);
C = load([IDIR '/' NAME(1:5) '/' C(1).name]);
ClusterData = C.ClusterData;
clear C

%% MAKE OUTPUT DIRECTORIES
if exist([ODIR '/' NAME(1:5) '/' FDIR], 'dir')==0
    mkdir([ODIR '/' NAME(1:5) '/' FDIR]);
end

%% MAKE FULL-TRIAL ISI FOR ALL CLUSTERS
EDGEVEC     = 0:BINSIZE:MAX_INTERVAL;
nClusters   = size(ClusterData,1);

ISI         = nan(nClusters, length(EDGEVEC)-1);
nIntervals  = nan(nClusters,1);

for iC = 1:nClusters
    ts              = find(ClusterData.SpikeTimes(iC,:))/FS;
    ts              = diff(ts);
    nIntervals(iC)  = numel(ts);
    ISI(iC,:)       = histcounts(ts,EDGEVEC)./nIntervals(iC);
end

%% MAKE ALIGNMENT ISI FOR ALL CLUSTERS AND ALL BEHAVIORS
ISIgs       = nan(nClusters, length(EDGEVEC)-1);
ISIgf       = nan(nClusters, length(EDGEVEC)-1);
ISIrs       = nan(nClusters, length(EDGEVEC)-1);
ISIrf       = nan(nClusters, length(EDGEVEC)-1);

nIntervalsGS  = nan(nClusters,1);
nIntervalsGF  = nan(nClusters,1);
nIntervalsRS  = nan(nClusters,1);
nIntervalsRF  = nan(nClusters,1);


for iC = 1:nClusters
    % Grasp Successes
    ts = [];
    for iG = 1:numel(G.GraspData.Successes{iC})
        x = G.GraspData.Successes{iC}{iG};
        ts = [ts, diff(x)];        
    end

    nIntervalsGS(iC)  = numel(ts);
    ISIgs(iC,:)       = histcounts(ts,EDGEVEC)./nIntervalsGS(iC);
    
    % Grasp Failures
    ts = [];
    for iG = 1:numel(G.GraspData.Failures{iC})
        x = G.GraspData.Failures{iC}{iG};
        ts = [ts, diff(x)];        
    end

    nIntervalsGF(iC)  = numel(ts);
    ISIgf(iC,:)       = histcounts(ts,EDGEVEC)./nIntervalsGF(iC);
    
    % Reach Successes
    ts = [];
    for iG = 1:numel(G.GraspData.ReachSuccesses{iC})
        x = G.GraspData.ReachSuccesses{iC}{iG};
        ts = [ts, diff(x)];        
    end

    nIntervalsRS(iC)  = numel(ts);
    ISIrs(iC,:)       = histcounts(ts,EDGEVEC)./nIntervalsRS(iC);
    
    % Reach Failures
    ts = [];
    for iG = 1:numel(G.GraspData.ReachFailures{iC})
        x = G.GraspData.ReachFailures{iC}{iG};
        ts = [ts, diff(x)];        
    end

    nIntervalsRF(iC)  = numel(ts);
    ISIrf(iC,:)       = histcounts(ts,EDGEVEC)./nIntervalsRF(iC);
end

% Combine output
ISIdata = table(ISI,nIntervals,ISIgs,nIntervalsGS,...
                               ISIgf,nIntervalsGF,...
                               ISIrs,nIntervalsRS,...
                               ISIrf,nIntervalsRF);

save([ODIR '/' NAME(1:5) '/' NAME '_' O_ID '.mat'], 'ISIdata', '-v7.3');
clear ISI nIntervals ISIgs nIntervalsGS
clear ISIgf nIntervalsGF ISIrs nIntervalsRS ISIrf nIntervalsRF

%% PLOT ALL CLUSTER ISI FOR FULL-TRIAL AND ALL CONDITIONS (1 FIG EACH)
nRow = ceil(sqrt(nClusters));
nCol = nRow;

for iO = 1:5
    y = ISIdata(:,2*(iO-1)+1);
    figure('Name', FTITLE{iO}, ...
           'Units', 'Normalized', ...
           'Position', [0.1 0.1 0.8 0.8]);
    
    for iC = 1:nClusters
        subplot(nRow, nCol, iC);
        bar(EDGEVEC(1:end-1)+BINSIZE/2,y{iC,1},'hist');
        ylim(YLIM);
        xlim([min(EDGEVEC) max(EDGEVEC)]);
        title([ClusterData.Hemisphere(iC) ' ' ...
               ClusterData.ML(iC) ' ' ...
               ClusterData.Area(iC,:) ': ' ...
               ClusterData.Channel(iC,:) '-' ClusterData.ICMS{iC}]);
    end
    suptitle([strrep(NAME,'_',' ') ': ' FTITLE{iO}]);
    
    savefig(gcf,[ODIR '/' NAME(1:5) '/' FDIR '/' NAME '_' ...
                strrep(FTITLE{iO},' ', '') '.fig']);
    saveas(gcf,[ODIR '/' NAME(1:5) '/' FDIR '/' NAME '_' ...
                strrep(FTITLE{iO},' ', '') '.jpeg']);
    delete(gcf);
end

%% FOR EACH CLUSTER, PLOT EACH ISI AND EVENT ALIGNMENT RASTER TIMELINE
if exist([ODIR '/' NAME(1:5) '/' FDIR '/' NAME(7:end)],'dir')==0
    mkdir([ODIR '/' NAME(1:5) '/' FDIR '/' NAME(7:end)]);    
end

maxT = length(ClusterData.SpikeTimes(1,:))/FS;

for iC = 1:nClusters
    if ISIdata.nIntervals(iC)/maxT < MINRATE
        disp([NAME '_' ClusterData.Hemisphere(iC) '_' ...
                 ClusterData.Area(iC,:) '-' ...
                 ClusterData.Channel(iC,:) ' rate too low. Skipped.']);
        continue
    end
    figure('Name', 'ISI Comparison', ...
           'Units', 'Normalized', ...
           'Position', [0.1 0.1 0.8 0.8]);
    
    % Get maximum ylim
    yMax = max([max(ISIdata.ISIgs(iC,:)), ...
                max(ISIdata.ISI(iC,:)), ...
                max(ISIdata.ISIgf(iC,:)), ...
                max(ISIdata.ISIrs(iC,:)), ...
                max(ISIdata.ISIrf(iC,:))]);
       
    % Relative timing
    subplot(9,10,1:20) 
    scatter(G.SuccessTimes, ones(size(G.SuccessTimes)), ...
        's', 'filled')
    hold on
    scatter(G.FailureTimes, ones(size(G.FailureTimes))*2, ...
        's', 'filled')
    scatter(G.ReachSuccessTimes, ones(size(G.ReachSuccessTimes))*3, ...
        's', 'filled')
    scatter(G.ReachFailureTimes, ones(size(G.ReachFailureTimes))*4, ...
        's', 'filled')
    hold off    
    ylim([0 5]);
    xlim([0 maxT]);
    xlabel('Time (sec)');
    title('Behavior Occurrence Times');
    
    set(gca,'YTick', [1 2 3 4]);
    set(gca,'YTickLabel',{'Grasp Successes', 'Grasp Failures', ...
                          'Reach Successes', 'Reach Failures'});
    
    % Grasp Successes
    subplot(9,10,[21:23,31:33,41:43]);
    bar(EDGEVEC(1:end-1)+BINSIZE/2,ISIdata.ISIgs(iC,:),'hist');
    ylim([0 yMax])
    xlim([min(EDGEVEC) max(EDGEVEC)]);
    title('Grasp Successes');
    
    % Grasp Failures
    subplot(9,10,[28:30,38:40,48:50]);
    bar(EDGEVEC(1:end-1)+BINSIZE/2,ISIdata.ISIgf(iC,:),'hist');
    ylim([0 yMax])
    xlim([min(EDGEVEC) max(EDGEVEC)]);
    title('Grasp Failures');
    
    % Reach Successes
    subplot(9,10,[61:63,71:73,81:83]);
    bar(EDGEVEC(1:end-1)+BINSIZE/2,ISIdata.ISIrs(iC,:),'hist');
    ylim([0 yMax])
    xlim([min(EDGEVEC) max(EDGEVEC)]);
    title('Reach Successes');
    
    % Reach Failures
    subplot(9,10,[68:70,78:80,88:90]);
    bar(EDGEVEC(1:end-1)+BINSIZE/2,ISIdata.ISIrf(iC,:),'hist');
    ylim([0 yMax])
    xlim([min(EDGEVEC) max(EDGEVEC)]);
    title('Reach Failures');
    
    % Full Recording
    subplot(9,10,[35:36,45:46]);
    bar(EDGEVEC(1:end-1)+BINSIZE/2,ISIdata.ISI(iC,:),'hist');
    ylim([0 yMax])
    xlim([min(EDGEVEC) max(EDGEVEC)]);
    title('Full Trial');
    
    % Sample Spikes
    subplot(9,10,[65:66, 75:76]);
    
    SpikeTemplate = mean(ClusterData.Waveforms{iC});
            
    nspk = size(ClusterData.Waveforms{iC},1);
    if nspk >= MAXSPIKES
        spkvec = RandSelect(1:nspk,MAXSPIKES);
        plot(TVEC, ClusterData.Waveforms{iC}(spkvec,:).', ...
             'Color', [0.92 0.92 0.92]);
    else
        plot(TVEC, ClusterData.Waveforms{iC}.', ...
             'Color', [0.92 0.92 0.92]);
    end
    hold on;
    plot(TVEC, SpikeTemplate, ...
                         'LineWidth', 2.5, ...
                         'Color', 'k', ...
                         'LineStyle', '--');
    set(gca, 'XLim', [min(TVEC) max(TVEC)]);
    set(gca, 'YLim', [-120 120]);
    title([ClusterData.Hemisphere(iC) ' ' ...
           ClusterData.Area(iC,:) ' ' ...
           'Ch' ClusterData.Channel(iC,:) ...
            '-' ClusterData.ICMS{iC}], 'Color', 'k');
    
    xlabel('Time (mSec)');
    ylabel('Amplitude (\muV)');
    
    % Save figures
    savefig(gcf,[ODIR '/' NAME(1:5) '/' FDIR '/' NAME(7:end) '/' ...
                 NAME '_' ClusterData.Hemisphere(iC) '_' ...
                 ClusterData.Area(iC,:) '-' ...
                 ClusterData.Channel(iC,:) '.fig']);
    saveas(gcf,[ODIR '/' NAME(1:5) '/' FDIR '/' NAME(7:end) '/' ...
                NAME '_' ClusterData.Hemisphere(iC) '_' ...
                ClusterData.Area(iC,:) '-' ...
                ClusterData.Channel(iC,:) '.jpeg']);
    delete(gcf);
    
end


end