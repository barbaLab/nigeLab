function flag = convert(tankObj,confirm)
%% CONVERT  Convert raw data files to Matlab TANK-BLOCK structure object
%
%  flag = tankObj.CONVERT;
%  flag = tankObj.CONVERT(confirm);
%
%  --------
%   INPUTS
%  --------
%   confirm    :     (Optional) flag that if true requires user
%                               confirmation
%
%  --------
%   OUTPUT
%  --------
%   flag       :     Returns true if conversion was successful.
%
%  By: Max Murphy v1.0  06/15/2018 Original version (R2017b)

%% DEFAULT CONVERSION CONSTANTS
% For filtering (these should be detected by TANK)
STIM_SUPPRESS = false;      % set true to do stimulus suppression (must change STIM_P_CH also)
STIM_P_CH = [nan nan];      % [probe, channel] for stimulation channel
STIM_BLANK = [0.2 1.75];    % [pre stim ms, post stim ms] for offline suppress
STATE_FILTER = true;

% For finding clusters
CLUSTER_LIST = {'CPLMJS'; ...
   'CPLMJS2'; ... % MJS profiles to use
   'CPLMJS3'};
NWR          = [1 2];     % Number of workers to use
WAIT_TIME    = 60;        % Wait time for looping if using findGoodCluster
INIT_TIME    = 2;         % Wait time before initializing findGoodCluster
UNC_PATH = {'\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data\'; ...
   '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\'};

%% CHECK WHETHER TO PROCEED
flag = false;
if nargin > 1
   if confirm
      choice = questdlg('Do file conversion (can be long)?',...
         'Continue?',...
         'Yes','Cancel','Yes');
      if strcmp(choice,'Cancel')
         error('File conversion aborted. Process canceled.');
      end
      
%       % Give chance to alter save location based on default settings
%       setSaveLocation(tankObj);
   end
end

%% GET GENERIC INFO
DIR = [UNC_PATH{1}, ...
   tankObj.DIR((find(tankObj.DIR == filesep,1,'first')+1):end)];
SAVELOC = [UNC_PATH{2}, ...
   tankObj.SaveLoc((find(tankObj.SaveLoc == filesep,1,'first')+1):end)];

%% GET CURRENT VERSION INFORMATION
[repoPath, ~] = fileparts(mfilename('fullpath'));
gitInfo = getGitInfo(repoPath);
attach_files = dir(fullfile(repoPath,'**'));
attach_files = attach_files((~contains({attach_files(:).folder},'.git')))';
dir_files = ~cell2mat({attach_files(:).isdir})';
ATTACHED_FILES = fullfile({attach_files(dir_files).folder},...
                          {attach_files(dir_files).name})';

%% PARSE NAME DEPENDING ON RECORDING TYPE
switch tankObj.RecType
   case 'Intan'
      F = dir(fullfile(tankObj.DIR,'*.rh*'));
      Name = strsplit(tankObj.DIR,filesep);
      Name = Name{numel(Name)};
      
      if numel(F) > 1
         ind = listdlg('PromptString','Select files to extract:',...
            'SelectionMode','multiple',...
            'ListString',{F.name}.');
         temp = F;
         F = cell(numel(ind),1);
         iCount = 1;
         for iF = ind
            F{iCount} = temp(iF).name;
            iCount = iCount + 1;
         end
         clear temp
      else
         F = {F.name};
      end
      
      ftype = cell(numel(F),1);
      for iF = 1:numel(F)
         ftype{iF} = F{iF}(end-2:end);
      end
      
      
      
      %% GET CLUSTER WITH AVAILABLE WORKERS
      for iF = 1:numel(F)
         if exist('CLUSTER','var')==0 % Otherwise, use "default" profile
            fprintf(1,'Searching for Idle Workers...');
            CLUSTER = findGoodCluster('CLUSTER_LIST',CLUSTER_LIST,...
               'NWR',NWR, ...
               'WAIT_TIME',WAIT_TIME, ...
               'INIT_TIME',INIT_TIME);
            fprintf(1,'Beating them into submission...');
         end
         
         myCluster = parcluster(CLUSTER);
         fprintf(1,'Creating Job...');
         j = createCommunicatingJob(myCluster, ...
            'AttachedFiles', ATTACHED_FILES,...
            'Type', 'pool', ...
            'Name', ['Intan extraction ' Name], ...
            'NumWorkersRange', NWR, ...
            'FinishedFcn', @JobFinishedAlert, ...
            'Type','pool', ...
            'Tag', ['Extracting INTAN files for: ' Name '...']);
         
         IN_ARGS = {tankObj,'NAME',fullfile(DIR,F{iF}),...
            'GITINFO',gitInfo,...
            'SAVELOC',SAVELOC,...
            'STIM_SUPPRESS',STIM_SUPPRESS,...
            'STIM_P_CH',STIM_P_CH,...
            'STIM_BLANK',STIM_BLANK,...
            'STATE_FILTER',STATE_FILTER,...
            'FILE_TYPE',ftype{iF}};
         
         switch ftype{iF}
            case 'rhs'
               createTask(j, @intanRHS2Block, 0,{IN_ARGS});
            case 'rhd'
               createTask(j, @intanRHD2Block, 0,{IN_ARGS});
            otherwise
               error('Invalid file type (%s).',ftype{iF});
         end
         
         fprintf(1,'Submitting...');
         submit(j);
         pause(WAIT_TIME);
         fprintf(1,'complete.\n');
         
      end
   case 'TDT'
      
   otherwise
      error('%s is not a supported acquisition system (case-sensitive).');
end

flag = true;
end