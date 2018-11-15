function genPaths(blockObj)
%% Set some useful path variables
% Here are defined all the paths where data will be saved.
% The folder tree is also created here(if not already exsting)
[ID,~] = orgExp.defaults.blockDefaults;
delim       = ID.Delimiter;
RAW_ID      = [delim ID.Raw.Folder];                 % Raw stream ID
FILT_ID     = [delim ID.Filt.Folder];                % Filtered stream ID
CAR_ID      = [delim ID.CAR.Folder];                 % Spatial re-reference stream ID
DIG_ID      = [delim ID.Digital.Folder];             % Digital stream ID
LFP_ID      = [delim ID.LFP.Folder];                 % LFP stream ID
SD_ID       = [delim ID.Spikes.Folder];              % Spike detection ID

paths.RW    = fullfile(blockObj.SaveLoc,[blockObj.Name RAW_ID] );
paths.FW    = fullfile(blockObj.SaveLoc,[blockObj.Name FILT_ID]);
paths.CARW  = fullfile(blockObj.SaveLoc,[blockObj.Name CAR_ID] );
paths.DW    = fullfile(blockObj.SaveLoc,[blockObj.Name DIG_ID] );
paths.LW    = fullfile(blockObj.SaveLoc,[blockObj.Name LFP_ID] );
paths.SDW   = fullfile(blockObj.SaveLoc,[blockObj.Name SD_ID]  );

for paths_ = fields(paths)'
    % Checks if all the target paths exist, if not mkdir
    if exist(paths.(paths_{:}),'dir')==0
        mkdir(paths.(paths_{:}));
    end
end

if exist(fullfile(paths.DW,'STIM_DATA'),'dir')==0
    mkdir(fullfile(paths.DW,'STIM_DATA'));
end

if exist(fullfile(paths.DW,'DC_AMP'),'dir')==0
    mkdir(fullfile(paths.DW,'DC_AMP'));
end

% ProbeChannel    = ID.ProbeChannel;
paths.RW_N      = fullfile(paths.RW,  [blockObj.Name ID.Raw.File  '.mat']);
paths.FW_N      = fullfile(paths.FW,  [blockObj.Name ID.Filt.File '.mat']);
paths.CARW_N    = fullfile(paths.CARW,[blockObj.Name ID.Filt.File '.mat']);
paths.DW_N      = fullfile(paths.DW,  [blockObj.Name '_DIG_%s.mat']);
paths.LW_N      = fullfile(paths.LW,  [blockObj.Name ID.LFP.File '.mat']);
paths.SDW_N     = fullfile(paths.SDW,  [blockObj.Name ID.Spikes.File '.mat']);
blockObj.paths  = paths;

end