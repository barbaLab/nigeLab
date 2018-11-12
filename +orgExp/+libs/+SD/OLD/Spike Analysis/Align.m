function [GraspData,ClusterData,SuccessTimes,FailureTimes,ReachSuccessTimes,ReachFailureTimes] = Align(varargin)
%% ALIGN    Align grasp times to spike times for all profiles
%
%   [GraspData,ClusterData,SuccessTimes,FailureTimes,ReachSuccessTimes,ReachFailureTimes] = ALIGN('NAME',value,...)
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
%   Mat file containing aligned output data and statistics relevant to
%   recorded spike trains, by area.
%
%   GraspData       :       Table with each row corresponding to a single
%                           cluster, corresponding to rows of ClusterData.
%                           There are two variables that correspond to
%                           successful and failed grasps; each cell is a
%                           new grasp and the times are relative alignment
%                           times in seconds.
%
%   ClusterData     :       Table with data about each single cluster,
%                           corresponding to row entries of GraspData. 
%
%   SuccessTimes    :       Absolute times (seconds) of successful grasps.
%
%   FailureTimes    :       Absolute times (seconds) of failed grasps.
%
%   ReachSuccessTimes :     Absolute times (seconds) of successful reaches.
%
%   ReachFailureTimes :     Absolute times (seconds) of failed reaches.
%
% See also: MERGEWAVES, SORTCLUSTERS, PLOTSPIKERASTERS
%   By: Max Murphy  v1.1 12/28/2016     Added figure generation for
%                                       rasters. Added reach alignment.
%                   v1.0 12/27/2016     Original Version

%% DEFAULTS
% Alignment parameters
TOL         = eps;                   % Tolerance for matching times
FS          = 24414.0625;            % Sampling frequency
E_PRE       = 4;                     % Epoch pre-alignment (sec)
E_POST      = 2;                     % Epoch post-alignment (sec)
NCH_PROBE   = 16;                    % Number of probe channels
RCH_TOL     = 1;                     % Tolerance for multiple reaches (sec)

% Directory info
VDIR  = 'Data/Scored Behavior Files';            % Directory of scored data
MDIR  = 'Data/Processed Recording Files/Merged'; % Directory of spikes
GDIR  = 'Good';                                  % Sub-directory of spikes
LDIR  = 'Data/Layout Files';                     % Layout directory
ODIR  = 'Data/Aligned';                          % Output directory


L_ID  = 'Summary of implanted hemispheres.xlsx';  % Name of layout file
SP_ID = '*spikes*';                               % Spikes file ID
V_ID  = '*VideoScoredSuccesses*';                 % Video alignment file ID

C_ID  = 'clusterdata';                            % Cluster data ID
G_ID  = 'graspdata';                              % Aligned grasp output ID
F_ID  = 'rasters';                                % Figure ID

% Raster Line Format
LINEFORMAT = struct;
    LINEFORMAT.Color = [0.05 0.05 0.05];
    LINEFORMAT.LineWidth = 1.5;
    LINEFORMAT.LineStyle = '-';

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
    elseif exist([MDIR '/' NAME], 'dir') == 0
        error('Must select a valid directory.');
    end
    
    S = dir([MDIR '/' NAME '/' GDIR '/' SP_ID '.mat']);
    
    if isempty(S) % Must contain valid files
        error([MDIR '/' NAME ' does not contain any files formatted ' ...
               SP_ID '. Check SP_ID or verify that directory' ...
               ' contains appropriate files.']);
    end
    
else    % If a pre-specified path exists, must be a valid path.
    
    if NAME == 0  % Must select a directory
        error('Must select a valid directory.');
    elseif exist([MDIR '/' NAME], 'dir') == 0
        error('Must select a valid directory.');
    end
    
    S = dir([MDIR '/' NAME '/' GDIR '/' SP_ID '.mat']);
    
    if isempty(S) % Must contain valid files
        error([MDIR '/' NAME ' does not contain any files formatted ' ...
               SP_ID '. Check SP_ID or verify that directory' ...
               ' contains appropriate files.']);
    end
end

%% LOAD VIDEO ALIGNMENT DATA
temp = dir([VDIR '/' NAME V_ID '.mat']);
if isempty(temp)
    error(['No video alignment file found. No file of the format ' ...
           NAME V_ID '.mat in directory: ' VDIR]);
elseif numel(temp)>1
    error(['Multiple video alignment files found. Check the format ' ...
           NAME V_ID '.mat in directory: ' VDIR]);
else
    V = load([VDIR '/' temp(1).name]);
    clear temp
end

%% GET LAYOUT DATA
[~,~,L]         = xlsread([LDIR '/' L_ID], NAME(1:5));
if strcmpi(L{3,2},L{3,3})
    Lesion   = 'N';
elseif strcmp(L{3,2},'CFA')
    Lesion   = 'L';
elseif strcmp(L{3,3},'CFA')
    Lesion   = 'R';
else
    Lesion   = '?';
end

%% GET ALL GRASP SUCCESSES AND FAILURES
gs = V.SuccessfulGrasp;
nSuccesses = numel(gs);
temp = [];
for ii = 1:nSuccesses
    temp = [temp, find(abs(V.Grasps - gs(ii)) < TOL, 1, 'first')];
end
vec = 1:numel(V.Grasps);
vec(temp) = [];
gf = V.Grasps(vec);
nFails = numel(gf);
clear temp ii vec

%% GET ALL SUCCESSFUL REACHES AND FAILURES
nReach = numel(V.Reaches);
reach  = V.Reaches(1);
ii = 1;
for iR = 2:nReach %Get all reaches not part of multi-reach
    if V.Reaches(iR) > V.Reaches(iR-1) + RCH_TOL
        if V.Reaches(iR) > reach(ii) + RCH_TOL
            reach = [reach, V.Reaches(iR)];
            ii = ii + 1;
        end
    end   
end

if numel(reach) > 1
    reachflag = true;
    rs = [];
    rf = [];
    
    for ii = 1:nSuccesses
        if isempty(find(reach<gs(ii),1,'last'))
            continue
        end
        rs = [rs, reach(find(reach<gs(ii),1,'last'))];
        reach(find(reach<gs(ii),1,'last')) = [];
        rf = [rf, reach(reach<gs(ii))];
        reach(reach<gs(ii)) = [];
    end
    nRS = numel(rs);
    nRF = numel(rf);
else
    reachflag = false;
end
clear V reach nBreaks ii

%% GET NUMBER OF SAMPLES
temp = load([MDIR '/' NAME '/' GDIR '/' S(1).name]);
nSamples = length(temp.peak_train);
clear temp

%% IMPORT ALL SPIKE TIMES
nClusters   = numel(S);
SpikeTimes  = [];
Waveforms   = cell(nClusters,1);
Channel     = repmat('??',nClusters,1);
Cluster     = repmat('?',nClusters,1);
Probe       = repmat('?',nClusters,1);
Area        = repmat('???',nClusters,1);
Hemisphere  = repmat('?',nClusters,1);
Lesion      = repmat(Lesion,nClusters,1);
ICMS        = cell(nClusters,1);
ML          = repmat('?',nClusters,1);

h = waitbar(0, 'Please wait, gathering cluster data...');
for iS = 1:nClusters
    data         = load([MDIR '/' NAME '/' GDIR '/' S(iS).name]);
    if length(data.peak_train) < nSamples
        nSamples = length(data.peak_train);
        SpikeTimes = SpikeTimes(:,1:nSamples);
    end
    
    SpikeTimes   = [SpikeTimes; data.peak_train(1:nSamples).'];
    Waveforms{iS}= data.spikes;
    
    Cluster(iS)  = S(iS).name(end-4);
    ch = str2double(S(iS).name(end-7:end-6));
    if ch > NCH_PROBE
        Probe(iS) = 'B';
        ch = ch - 16;
    else
        Probe(iS) = 'A';
    end
    
    ch_match = ch + 6;
    chstr = num2str(ch);
    if length(chstr) < 2
        chstr = ['0' chstr];
    end
    Channel(iS,:)= chstr;
    
    if strcmp(L{4,2},Probe(iS))
        Hemisphere(iS) = L{1,2}(1);
        ICMS{iS} = L{ch_match,2}(3:end);
        ML(iS) = L{ch_match,2}(1);
        Area(iS,:) = L{2,2};
    else
        Hemisphere(iS) = L{1,3}(1);
        ICMS{iS} = L{ch_match,3}(3:end);
        ML(iS) = L{ch_match,3}(1);
        Area(iS,:) = L{2,3};
    end   
    waitbar(iS/nClusters);
end
delete(h);

ClusterData = table(Lesion,Hemisphere,Area,Probe,Channel,Cluster,ML,ICMS, ...
                    SpikeTimes,Waveforms);

if exist([ODIR '/' NAME(1:5)], 'dir') == 0
    mkdir([ODIR '/' NAME(1:5)]);
end
                
save([ODIR '/' NAME(1:5) '/' NAME '_' C_ID '.mat'], 'ClusterData', '-v7.3');                

%% ALIGN ALL SPIKE TIMES
Successes = cell(nClusters,1);
Failures  = cell(nClusters,1);
ReachSuccesses = cell(nClusters,1);
ReachFailures  = cell(nClusters,1);
h = waitbar(0,'Please wait, aligning spikes to behavior...');
for iS = 1:nClusters
    ts = find(SpikeTimes(iS,:))/FS;
    succ = cell(nSuccesses,1);
    for iG = 1:nSuccesses
        succ{iG} = ts(ts>=gs(iG)-E_PRE & ts<=gs(iG)+E_POST) - gs(iG);
    end
    Successes{iS} = succ; clear succ;
    
    fail = cell(nFails,1);
    for iG = 1:nFails
        fail{iG} = ts(ts>=gf(iG)-E_PRE & ts<=gf(iG)+E_POST) - gf(iG);
    end
    Failures{iS} = fail; clear fail;
    
    
    rsucc = cell(nRS,1);
    for iR = 1:nRS
        rsucc{iR} = ts(ts>=rs(iR)-E_PRE & ts<=rs(iR)+E_POST) - rs(iR);
    end
    ReachSuccesses{iS} = rsucc; clear rsucc;
    
    rfail = cell(nRF,1);
    for iR = 1:nRF
        rfail{iR} = ts(ts>=rf(iR)-E_PRE & ts<=rf(iR)+E_POST) - rf(iR);
    end
    ReachFailures{iS} = rfail; clear rfail;
    waitbar(iS/nClusters);
end
delete(h);
SuccessTimes = gs; clear gs;
FailureTimes = gf; clear gf;
ReachSuccessTimes = rs;  clear rs;
ReachFailureTimes = rf;  clear rf;

GraspData = table(Successes,Failures,ReachSuccesses,ReachFailures);

save([ODIR '/' NAME(1:5) '/' NAME '_' G_ID '.mat'],'GraspData', ...
      'SuccessTimes','FailureTimes', ...
      'ReachSuccessTimes','ReachFailureTimes','-v7.3'); 
  
%% PLOT RASTERS
nrow = ceil(sqrt(nClusters));
ncol = nrow;

% Plot grasp failures
if nFails>1
    figure('Name', 'Failure Rasters', ...
           'Units', 'Normalized', ...
           'Position', [0.1 0.1 0.8 0.8], ...
           'Color', 'w');
    
    for ii = 1:nClusters
        if ~any(~cellfun(@isempty,GraspData.Failures{ii}))
            continue
        end
        subplot(nrow,ncol,ii); ...
        
        
        plotSpikeRaster(GraspData.Failures{ii}, ...
                        'PlotType','vertline', ...
                        'LineFormat',LINEFORMAT); ...
        hold on;
        line([0 0],[0 nFails + 1], ...
             'Color', 'm', ...
             'LineWIdth', 2, ...
             'LineStyle', '--'); 
        hold off;
        set(gca,'Xlim',[-E_PRE E_POST]); 
        title([ClusterData.Hemisphere(ii) ' ' ...
               ClusterData.ML(ii) ' ' ...
               ClusterData.Area(ii,:) ': ' ...
               ClusterData.Channel(ii,:) '-' ClusterData.ICMS{ii}]);
    end
    
    suptitle([strrep(NAME,'_',' ') ': Failed Grasps']);
end

savefig(gcf,[ODIR '/' NAME(1:5) '/' NAME '_failure' F_ID '.fig']);
saveas(gcf,[ODIR '/' NAME(1:5) '/' NAME '_failure' F_ID '.jpeg']);
delete(gcf);

% Plot grasp successes
if nSuccesses>1
    
    figure('Name', 'Success Rasters', ...
           'Units', 'Normalized', ...
           'Position', [0.1 0.1 0.8 0.8], ...
           'Color', 'w');
    
    for ii = 1:nClusters
        if ~any(~cellfun(@isempty,GraspData.Successes{ii}))
            continue
        end
        subplot(nrow,ncol,ii); ...
        plotSpikeRaster(GraspData.Successes{ii}, ...
                        'PlotType','vertline', ...
                        'LineFormat',LINEFORMAT); ...
        hold on;
        line([0 0],[0 nSuccesses + 1], ...
             'Color', 'm', ...
             'LineWIdth', 2, ...
             'LineStyle', '--'); 
        hold off;
        set(gca,'Xlim',[-E_PRE E_POST]); 
        title([ClusterData.Hemisphere(ii) ' ' ...
               ClusterData.ML(ii) ' ' ...
               ClusterData.Area(ii,:) ': ' ...
               ClusterData.Channel(ii,:) '-' ClusterData.ICMS{ii}]);
    end
    
    suptitle([strrep(NAME,'_',' ') ': Successful Grasps']);
    
end
savefig(gcf,[ODIR '/' NAME(1:5) '/' NAME '_success' F_ID '.fig']);
saveas(gcf,[ODIR '/' NAME(1:5) '/' NAME '_success' F_ID '.jpeg']);
delete(gcf);

% Plot reach failures
if nRF>1
    figure('Name', 'Reach Failure Rasters', ...
           'Units', 'Normalized', ...
           'Position', [0.1 0.1 0.8 0.8], ...
           'Color', 'w');
    
    for ii = 1:nClusters
        if ~any(~cellfun(@isempty,GraspData.ReachFailures{ii}))
            continue
        end
        subplot(nrow,ncol,ii); ...
        plotSpikeRaster(GraspData.ReachFailures{ii}, ...
                        'PlotType','vertline', ...
                        'LineFormat',LINEFORMAT); ...
        hold on;
        line([0 0],[0 nRF + 1], ...
             'Color', 'm', ...
             'LineWIdth', 2, ...
             'LineStyle', '--'); 
        hold off;
        set(gca,'Xlim',[-E_PRE E_POST]); 
        title([ClusterData.Hemisphere(ii) ' ' ...
               ClusterData.ML(ii) ' ' ...
               ClusterData.Area(ii,:) ': ' ...
               ClusterData.Channel(ii,:) '-' ClusterData.ICMS{ii}]);
    end
    
    suptitle([strrep(NAME,'_',' ') ': Failed Reaches']);
end

savefig(gcf,[ODIR '/' NAME(1:5) '/' NAME '_reachfailure' F_ID '.fig']);
saveas(gcf,[ODIR '/' NAME(1:5) '/' NAME '_reachfailure' F_ID '.jpeg']);
delete(gcf);

% Plot grasp successes
if nRS>1
    figure('Name', 'Reach Success Rasters', ...
           'Units', 'Normalized', ...
           'Position', [0.1 0.1 0.8 0.8], ...
           'Color', 'w');
    
    for ii = 1:nClusters
        if ~any(~cellfun(@isempty,GraspData.ReachSuccesses{ii}))
            continue
        end
        subplot(nrow,ncol,ii); ...
        plotSpikeRaster(GraspData.ReachSuccesses{ii}, ...
                        'PlotType','vertline', ...
                        'LineFormat',LINEFORMAT); ...
        hold on;
        line([0 0],[0 nRS + 1], ...
             'Color', 'm', ...
             'LineWIdth', 2, ...
             'LineStyle', '--'); 
        hold off;
        set(gca,'Xlim',[-E_PRE E_POST]); 
        title([ClusterData.Hemisphere(ii) ' ' ...
               ClusterData.ML(ii) ' ' ...
               ClusterData.Area(ii,:) ': ' ...
               ClusterData.Channel(ii,:) '-' ClusterData.ICMS{ii}]);
    end
    
    suptitle([strrep(NAME,'_',' ') ': Successful Reaches']);
    
end
savefig(gcf,[ODIR '/' NAME(1:5) '/' NAME '_reachsuccess' F_ID '.fig']);
saveas(gcf,[ODIR '/' NAME(1:5) '/' NAME '_reachsuccess' F_ID '.jpeg']);
delete(gcf);

end