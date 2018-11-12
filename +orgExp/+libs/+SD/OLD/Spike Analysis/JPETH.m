function JointData = JPETH(varargin)
%% JPETH     Construct joint peri-event time histogram 
%
%   JPETH('NAME', value, ...)
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
%   Creates figure of the JPETH for each set of good cluster pairs.
%
%   JointData       :       Table output containing information about
%                           joint PETH distributions.
%
% See also: SORTCLUSTERS, MERGEWAVES, ALIGN, PLOTSPIKERASTER, PETH
%   By: Max Murphy    v1.0 12/29/2016     Original Version

%% DEFAULTS
% Constructing peri-event time histogram
BINSIZE = 0.025;                         % Bin size (sec): per Hyland '98
E_PRE   = 4;                             % Pre-event time (sec)
E_POST  = 2;                             % Post-event time (sec)
FS      = 24414.0625;                    % Sampling frequency

% Directory information
IDIR  = 'Data/Aligned';                          % Input data directory

G_ID  = 'graspdata';                             % Grasp data ID
C_ID  = 'clusterdata';                           % Cluster data ID
H_ID  = 'histdata';                              % Histogram data ID
O_ID  = 'jpethdata';                             % Output data ID
F_ID  = 'JPETH';                                 % Figure ID

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
    load([IDIR '/' NAME(1:5) '/' NAME '_' H_ID '.mat']);
    
else    % If a pre-specified path exists, must be a valid path.
    
    if NAME == 0  % Must select a directory
        error('Must select a valid rat name.');
    elseif exist([IDIR '/' NAME(1:5)], 'dir') == 0
        error('Must select a valid rat name.');
    end
    
    load([IDIR '/' NAME(1:5) '/' NAME '_' G_ID '.mat']);
    load([IDIR '/' NAME(1:5) '/' NAME '_' C_ID '.mat']);
    load([IDIR '/' NAME(1:5) '/' NAME '_' H_ID '.mat']);

end

%% CREATE JOINT-PERI EVENT TIME HISTOGRAMS
nClusters    = numel(info.UseRows);
TVEC      = -E_PRE:BINSIZE:E_POST;
nBins     = numel(TVEC)-1;

nComparisons = nClusters * (nClusters-1) /2;

nTrials      = [info.nSuccessfulGrasp, ...
                info.nFailureGrasp, ...
                info.nSuccessfulReach, ...
                info.nFailureReach];

tempCell = cell(nComparisons,4);
predCell = cell(nComparisons,4);
Comparison = nan(nComparisons,2);
            
for iE = 1:4
    iComp = 0;
    for iC1 = 1:nClusters
        x1 = GraspData{info.UseRows(iC1),iE};
        
        for iC2 = (iC1+1):nClusters
            iComp = iComp + 1;
            x2 = GraspData{info.UseRows(iC2),iE};
            
            
            Comparison(iComp,:) = [info.UseRows(iC1), info.UseRows(iC2)];
            tempCell{iComp,iE} = zeros(nBins);
            predCell{iComp,iE} = zeros(nBins);
            shiftcount = 0;
            for iT = 1:nTrials(iE)
                temp = zeros(nBins);
                h1 = histcounts(x1{1}{iT},TVEC);
                [~,i1,v1] = find(h1);
                h2 = histcounts(x2{1}{iT},TVEC);
                [~,i2,v2] = find(h2);
                for ii1 = 1:numel(i1)
                    for ii2 = 1:numel(i2)
                        temp(i1(ii1),i2(ii2)) = v1(ii1) + v2(ii2);
                    end
                end
                tempCell{iComp,iE} = tempCell{iComp,iE} + temp;
                
                for iTT = iT+1:nTrials(iE)
                    shiftcount = shiftcount + 1;
                    temp = zeros(nBins);
                    h2 = histcounts(x2{1}{iTT},TVEC);
                    [~,i2,v2] = find(h2);
                    for ii1 = 1:numel(i1)
                        for ii2 = 1:numel(i2)
                            temp(i1(ii1),i2(ii2)) = v1(ii1) + v2(ii2);
                        end
                    end
                    predCell{iComp,iE} = predCell{iComp,iE} + temp;
                end
            end
            predCell{iComp,iE} = predCell{iComp,iE}/shiftcount;
        end
    end
end

%% ORGANIZE OUTPUT
SuccessfulGrasp = tempCell(:,1);
FailureGrasp    = tempCell(:,2);
SuccessfulReach = tempCell(:,3);
FailureReach    = tempCell(:,4);

SuccessfulGraspPred = predCell(:,1);
FailureGraspPred    = predCell(:,2);
SuccessfulReachPred = predCell(:,3);
FailureReachPred    = predCell(:,4);

clear tempCell predCell

JointData = table(Comparison,SuccessfulGrasp,FailureGrasp, ...
                             SuccessfulReach,FailureReach, ...
                             SuccessfulGraspPred, FailureGraspPred, ...
                             SuccessfulReachPred, FailureReachPred);
                         
%% SAVE OUTPUT

save([IDIR '/' NAME(1:5) '/' NAME '_' O_ID '.mat'], 'JointData', 'info', ...
      '-v7.3');

end