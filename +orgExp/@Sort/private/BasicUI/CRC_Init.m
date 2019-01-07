function handles = CRC_Init(varargin)
%% CRC_INIT Initialize handles structure for Combine/Restrict Cluster UI.
%
%   handles = CRC_INIT('NAME',value,...)
%
% By: Max Murphy  v2.0    10/03/2017 Added ability to handle multiple input
%                                    probes with redundant channel labels.
%                 v1.0    08/18/2017 Original version (R2017a)

%% INITIALIZE HANDLES STRUCT
% Turn off warnings to speed up load
warning('off','MATLAB:load:variableNotFound');

% Defaults for handles
handles = struct;                   % carries all parameter variables
handles.OUT_ID  = 'Sorted';         % output folder ID
handles.IN_ID   = 'Clusters';       % input folder ID
handles.DEF_DIR = 'P:\Rat';         % Default directory to look
handles.SDMAX = 4;                  % Max # SD to allow from medroid
handles.SDMIN = 0;                  % Min # SD to allow from medroid
handles.T_RES = 1;      % Time resolution (in minutes)
handles.NZTICK = 5;     % # Z-tick (time ticks)
handles.NPOINTS = 8;    % # circle edge points to plot
handles.DEBUG = false;  % Set to TRUE to move handles to base workspace
handles.MINSPIKES = 30; % Minimum # spikes in order to plot
handles.FORCE_NEXT = false; % Automatically jump to next channel on "confirm"
handles.DISTANCE_METHOD = 'L2';

% Probably don't change these parameters:
handles.FUNC    = 'CRC.m';
handles.SRCPATH = fileparts(which(handles.FUNC));
handles.OUTDIR  = 'out';    % Artifact spikes folder
handles.INDIR   = 'in';     % Good spikes folder
handles.DELIM   = '_';      % Delimiter for parsing file name info
handles.SORT_ID = 'sort';   % Sort file ID
handles.SPK_ID  = 'ptrain'; % Spike file ID
handles.CLU_ID  = 'clus';   % Clusters file ID
handles.OUT_TAG_ID = 11;    % Index for "OUT" tag from cell in CRC_Labels.mat
handles.CL_IND  = 4;        % indices back from end for cluster #
handles.SPKF_IND = 2;       % '_' delimited index to remove for "spikes"
handles.SPKF_ID = 'Spikes'; % append to end of folder name for "spikes"
handles.SC_IND = 3;         % '_' delimited index for clustering method
handles.DEF_RAD = 0.75;     % Default cluster radius
handles.NCLUS_MAX = 9;      % Max. # clusters (per clustering algorithm)
handles.SPK_YLIM = [-250 150];  % Spike axes y-limits
handles.NSPK = 150;             % Max. # Spikes to plot

% Max X   Max Y
handles.SPK_AX = [0.975, 0.925];
handles.AX_SPACE = 0.035;

handles.NFEAT_PLOT_POINTS = 2000; % Max. # feature points to plot
handles.FEAT_VIEW = [-5 13]; % 3-D view angle

%% PARSE VARARGIN
if nargin > 0
   varargin = varargin{1};
end

for iV = 1:2:numel(varargin)
   handles.(upper(varargin{iV})) = varargin{iV+1};
end

%% DETERMINE AXES POSITIONS
if ~isfield(handles,'AX_POS')
   handles = CRC_SetAxesPositions(handles);
end

%% GET DIRECTORY
if ~isfield(handles,'DIR')
   handles = CRC_GetDirectory(handles);
else
    if contains(handles.DIR,handles.IN_ID)
        temp_dir = strsplit(handles.DIR,filesep);
        handles.DIR = strjoin(temp_dir(1:(end-1)),filesep);
    end
    handles = CRC_GetDirectory(handles);
end

%% CHECK FOR ALREADY-SORTED SPIKES
if exist(strrep(handles.DIR,handles.IN_ID,handles.OUT_ID),'dir')~=0
   msg = questdlg('Previous sort detected. Load it instead?',...
      'Select input',...
      'Load previous sort','Load auto-clusters','Load previous sort');
   if strcmpi(msg,'Load previous sort')
      fprintf(1,'\nLoading previous sort.\n');
      handles.DIR = strsplit(handles.DIR,filesep);
      handles.DIR = strjoin(handles.DIR(1:end-1),filesep);
      handles.IN_ID = handles.OUT_ID;
      handles.CLU_ID = handles.SORT_ID;
      handles = CRC_GetDirectory(handles);
   else
      fprintf(1,'\nLoading auto-clusters.\n');
   end
end
      

%% GET "SPIKES" INFO
F = dir(fullfile(handles.SPKDIR,['*' handles.SPK_ID '*.mat']));
handles.files.N = numel(F);
temp = strsplit(F(1).name,'_');
handles.files.spk.folder = handles.SPKDIR;
ind = find(ismember(temp,handles.SPK_ID),1,'last')+1;
handles.files.spk.ch = cell(handles.files.N,1);
handles.files.prefix = cell(handles.files.N,1);
handles.spk.fname = cell(handles.files.N,1);

fprintf(1,'\n->\tGetting features and classes...');
for iF = 1:handles.files.N % get all naming info
   handles.spk.fname{iF,1} = fullfile(handles.SPKDIR,F(iF).name);
   temp = strsplit(F(iF).name,'.');
   temp = temp{1};
   temp = strsplit(temp,handles.DELIM);
   handles.files.spk.ch{iF,1} = strjoin(temp(ind:end),handles.DELIM);
   handles.files.prefix{iF,1} = strjoin(temp(1:(ind-2)),handles.DELIM);
end
handles.files.submitted = false(size(handles.files.spk.ch));

%% GET "CLUSTERS" INFO
F = dir(fullfile(handles.DIR,['*' handles.CLU_ID '*.mat']));
if isempty(F) % Then automated sorting hasn't been done
   sorted_flag = false;
   F = dir(fullfile(handles.SPKDIR,['*' handles.SPK_ID '*.mat']));
else
   sorted_flag = true;
end
temp = strsplit(F(1).name,'_');
handles.files.cl.folder   = handles.DIR;
handles.files.sort.folder = strrep(handles.files.cl.folder,...
   handles.IN_ID,handles.OUT_ID);
ind = find(ismember(temp,handles.CLU_ID),1,'last')+1;
if isempty(ind)
   ind = find(ismember(temp,handles.SPK_ID),1,'last')+1; 
end
handles.files.cl.ch = cell(handles.files.N,1);
handles.files.sort.ch = cell(handles.files.N,1);
handles.cl.fname = cell(handles.files.N,1);

for iF = 1:handles.files.N % get all naming info
   % Use dummy variables because must match order
   tempfile = fullfile(handles.DIR,F(iF).name);
   if ~sorted_flag
      strrep(tempfile,handles.SPK_ID,handles.CLU_ID);
   end
   temp = strsplit(F(iF).name,'.');
   temp = temp{1};
   temp = strsplit(temp,'_');
   tempchannel = strjoin(temp(ind:end),'_');

   % Make sure order matches spike files
   ind_match = find(ismember(handles.files.spk.ch,{tempchannel}),1,'first');
   handles.files.cl.ch{ind_match,1} = tempchannel;
   handles.cl.fname{ind_match,1} = tempfile;
end

%% GET UNSUPERVISED CLASS ASSIGNMENTS & FEATURES
in = load('CRC_Tags.mat','TAGS');
handles.cl.tag.defs = in.TAGS;
in = load('CRC_Colors.mat','Colors');
handles.COLS = in.Colors;
in = load('CRC_Labels.mat','Labels');
handles.Labels = in.Labels;
handles.spk.feat = cell(handles.files.N,1);
handles.spk.include.in = cell(handles.files.N,1);
handles.spk.include.cur = cell(handles.files.N,1);
handles.spk.fs = nan(handles.files.N,1);
handles.spk.nfeat = nan(handles.files.N,1);
handles.spk.peak_train = cell(handles.files.N,1);
handles.cl.num.centroid=cell(handles.files.N,handles.NCLUS_MAX);
handles.cl.tag.name = cell(handles.files.N,1);
handles.cl.tag.val = cell(handles.files.N,1);
handles.cl.num.class.in=cell(handles.files.N,1);
handles.cl.num.class.cur = cell(handles.files.N,1);
handles.cl.sel.in = cell(handles.files.N,handles.NCLUS_MAX);
handles.cl.sel.base = cell(handles.files.N,handles.NCLUS_MAX);
handles.cl.sel.cur = cell(handles.files.N,handles.NCLUS_MAX);

handles.zmax = 0;
handles.nfeatmax = 0;
for iCh = 1:handles.files.N % get # clusters per channel   
   in_feat = load(handles.spk.fname{iCh},'features');
   handles.spk.feat{iCh,1} = in_feat.features; 
   
   handles.spk.include.in{iCh,1} = true(size(in_feat.features,1),1);
   handles.spk.include.cur{iCh,1} = true(size(in_feat.features,1),1);
   handles.spk.nfeat(iCh) = size(in_feat.features,2);
   
   handles.nfeatmax = max(handles.nfeatmax,handles.spk.nfeat(iCh));

   
   % Load classes. 1 == OUT; all others (up to NCLUS) are valid
   if sorted_flag
      in_class = load(handles.cl.fname{iCh},'class');
   else
      in_class = struct;
      in_class.class = ones(size(in_feat.features,1),1);
   end
   
   if min(in_class.class) < 1
      in_class.class = in_class.class + 1;
   end
   
   % Assign "other" clusters as OUT
   in_class.class(in_class.class > numel(handles.cl.tag.defs)) = 1;
   in_class.class(isnan(in_class.class)) = 1;
   
   % For "selected" make copy of original as well.
   handles.cl.num.class.in{iCh} = in_class.class;
   handles.cl.num.class.cur{iCh} = in_class.class;
   handles.cl.tag.name{iCh} = handles.cl.tag.defs(in_class.class);
   
   % Get each cluster centroid and membership
   val = [];
   for iN = 1:handles.NCLUS_MAX
      if isempty(handles.cl.tag.defs{iN})
         tags_val = 1;
      else
         tags_val = find(ismember(handles.Labels(2:end),...
            handles.cl.tag.defs(iN)),1,'first');
         if isempty(tags_val)
            tags_val = 1;
         else
            tags_val = tags_val + 1;
         end
      end
      val = [val, tags_val]; %#ok<AGROW>
      handles.cl.num.centroid{iCh,iN} = median(in_feat.features(...
         in_class.class==iN,:));
      handles.cl.sel.in{iCh,iN}=find(handles.cl.num.class.in{iCh}==iN);
      handles.cl.sel.base{iCh,iN}=find(handles.cl.num.class.in{iCh}==iN);
      handles.cl.sel.cur{iCh,iN}=find(handles.cl.num.class.in{iCh}==iN);
   end
   handles.cl.tag.val{iCh} = val;
   
end
clear features
fprintf(1,'complete.\n');

%% UI CONTROLLER VARIABLES
handles.UI.ch = 1;
handles.UI.cl = 1;
handles.UI.zm = ones(handles.NCLUS_MAX,1) * 100;
handles.UI.spk_ylim = repmat(handles.SPK_YLIM,handles.NCLUS_MAX,1);

% Initialize first set of spikes
handles.plot = load(handles.spk.fname{handles.UI.ch},'spikes');

% Initialize cluster assignments
handles.cl.num.assign.cur = cell(handles.files.N,1);

% Initialize cluster radii and feature plots properties
handles.cl.num.rad = cell(handles.files.N,1);
fprintf(1,'->\tGetting spike times...');
for iCh = 1:handles.files.N
   in = load(handles.spk.fname{iCh},'pars','peak_train');
   handles.spk.fs(iCh) = in.pars.FS;
   handles.spk.peak_train{iCh,1} = in.peak_train;
   handles.zmax = max(handles.zmax,numel(in.peak_train)/in.pars.FS/60);
   
   handles.cl.num.assign.cur{iCh,1} = 1:handles.NCLUS_MAX;
   handles.cl.num.rad{iCh,1} = inf*ones(1,handles.NCLUS_MAX);
end
fprintf(1,'complete.\n');

% Initialize "features" info
handles.feat.this = 1;
handles.featcomb = flipud(...
   combnk(1:handles.spk.nfeat(handles.UI.ch),2));
handles.featname = cell(handles.nfeatmax,1);
for iN = 1:size(handles.featcomb,1)
   handles.featname{iN,1} = sprintf('x: %s-%d || y: %s-%d',handles.sc,...
      handles.featcomb(iN,1),handles.sc,handles.featcomb(iN,2));
end

% Initialize string for channels in nice format for popupmenu
handles.UI.channels = cell(handles.files.N,1);
for iCh = 1:handles.files.N
   handles.UI.channels{iCh} = strrep(handles.files.spk.ch{iCh},'_',' ');
end

warning('on','MATLAB:load:variableNotFound');

end