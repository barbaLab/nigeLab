function flag = convert(blockObj)
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



%% GET GENERIC INFO
% DIR = [UNC_PATH{1}, ...
%     tankObj.DIR((find(tankObj.DIR == filesep,1,'first')+1):end)];
% SAVELOC = [UNC_PATH{2}, ...
%     tankObj.SaveLoc((find(tankObj.SaveLoc == filesep,1,'first')+1):end)];

%% GET CURRENT VERSION INFORMATION WIP
% [repoPath, ~] = fileparts(mfilename('fullpath'));
% gitInfo = getGitInfo(repoPath);
% attach_files = dir(fullfile(repoPath,'**'));
% attach_files = attach_files((~contains({attach_files(:).folder},'.git')))';
% dir_files = ~cell2mat({attach_files(:).isdir})';
% ATTACHED_FILES = fullfile({attach_files(dir_files).folder},...
%     {attach_files(dir_files).name})';

%% PARSE NAME DEPENDING ON RECORDING TYPE

switch blockObj.RecType
    case 'Intan'

            switch blockObj.File_extension
                case '.rhs'
                    blockObj.RHS2Block()
                case '.rhd'
                    blockObj.RHD2Block()
                otherwise
                    error('Invalid file type (%s).',blockObj.File_extension);
            end
            
            fprintf(1,['complete.' newline]);
            
        
    case 'TDT'
        fprintf(1,'Unsupported yet')
    case 'mat'
        fprintf(1,'Unsupported yet')
    otherwise
        error('%s is not a supported acquisition system (case-sensitive).');
end

flag = true;
end