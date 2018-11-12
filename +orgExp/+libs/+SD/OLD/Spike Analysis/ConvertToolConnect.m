function ConvertToolConnect(varargin)
%% CONVERTTOOLCONNECT    Build directory structure and convert for ToolConnect
%
%   CONVERTTOOLCONNECT('NAME',value,...)
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
%   Directory structure consistent with experiment data directory tree
%   structure used by the compiled C# program ToolConnect. At the highest
%   level of the tree is a given recording session. Below that, the
%   experiment contains a Peak_Detection subfolder. Within Peak_Detection,
%   each event alignment has a subfolder, which is considered to be 
%   the "phase" folder. Within the phase folder, every identified 
%   cluster has its timestamps converted to a .txt format:
%
%   5000000  <--- First line is # of samples in recording
%   1000
%   10000
%   10030    <--- Each subsequent line is a spike timestamp (samples) 
%   200000
%   210000     
%
%
% See also: MERGEWAVES, SORTCLUSTERS, PLOTSPIKERASTERS, ALIGN
% ToolConnect from: "ToolConnect: A Functional Connectivity Toolbox for In
%                   Vitro Networks." By Vito Paolo Pastore, Daniele Poli,
%                   Aleksandar Godjoski, Sergio Martinoia, and Paolo
%                   Massobrio. Frontiers (2016).
%   By: Max Murphy  v1.0    1/3/2017    Original Version

%% DEFAULTS
clearvars -except varargin; close all force; clc

% Sampling info
FS = 24414.0625;

% Directory info
MDIR  = 'Data/Processed Recording Files/Merged';                  % Select
ODIR  = 'C:/Users/Max Murphy/Desktop/Data Analysis/ToolConnect';  % Output 
IDIR  = 'Data/Aligned';                                           % Input

G_ID  = 'graspdata';                             % Aligned data input ID
C_ID  = 'clusterdata';                           % Cluster data input ID

SF_ID = {'GS','GF','RS','RF'};                   % Sub-experiments

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
ClusterData     = C.ClusterData;
GraspData       = G.GraspData;
AlignmentTimes  = {G.SuccessTimes; ...
                   G.FailureTimes; ...
                   G.ReachSuccessTimes; ...
                   G.ReachFailureTimes};
clear C G

%% MAKE OUTPUT DIRECTORY FILE STRUCTURE
nPhase = numel(SF_ID);
nClusters = size(ClusterData,1);
odir = cell(nPhase,1);
for iP = 1:nPhase
    odir{iP,1} = [ODIR '/' NAME(1:5) '/' NAME '/' ...
                       '/Peak_Detection/' SF_ID{iP}];
    if exist(odir{iP},'dir')==0
        mkdir(odir{iP});
    end    
end

%% CONVERT SPIKE TIMESTAMPS TO .TXT FILES
h = waitbar(0,'Please wait, converting spike times for ToolConnect...');

nSamples = numel(ClusterData.SpikeTimes(1,:));
for iP = 1:nPhase
    nTrials = numel(AlignmentTimes{iP});
    for iC = 1:nClusters
        % Get absolute timestamps of all spikes
        ts      = [];
        for iG = 1:nTrials
            ts_add = round((GraspData{iC,iP}{1}{iG} + ...
                            AlignmentTimes{iP}(iG)) * FS);
            ts = [ts, ts_add];
        end
        
        fid = fopen([odir{iP} '/' NAME '_ptrain' ...
              '_' ClusterData.Hemisphere(iC) ...
              '_' ClusterData.Area(iC,:) ...
              '_' ClusterData.Probe(iC) ClusterData.Channel(iC,:) ...
              '_' ClusterData.Cluster(iC) ...
              '_' num2str(iC) ...
              '.txt'],'wt');
        fprintf(fid, '%d\n' ,nSamples);
        fprintf(fid, '%d\n',ts(1:end-1));
        fprintf(fid, '%d',ts(end));
        fclose(fid);
        waitbar(iC/nClusters/nPhase + (iP-1)/nPhase);
    end
end
delete(h);

end