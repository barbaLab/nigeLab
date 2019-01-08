function flag = findCorrectPath(blockObj)
%% FINDCORRECTPATH    Update the paths struct to reflect correct TANK
%   
%  flag = FINDCORRECTPATH(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class object from orgExp package.
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Flag indicating if setting new path was successful.
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%% LOAD IDENTIFIERS
flag = false;
[ID,~]      = nigeLab.defaults.Block;
delim       = ID.Delimiter;
RAW_ID      = [delim ID.Raw.Folder];                 % Raw stream ID
FILT_ID     = [delim ID.Filt.Folder];                % Filtered stream ID
CAR_ID      = [delim ID.CAR.Folder];                 % Spatial re-reference stream ID
DIG_ID      = [delim ID.Dig.Folder];                 % Digital stream ID
LFP_ID      = [delim ID.LFP.Folder];                 % LFP stream ID
SD_ID       = [delim ID.Spikes.Folder];              % Spike detection ID
META_ID     = [delim ID.Meta.Folder];

%% PARSE CORRECT ROOT PATH
N = numel(blockObj.paths.TW_ext);
blockObj.paths.TW_idx = 0;
while blockObj.paths.TW_idx < N
   blockObj.paths.TW_idx = blockObj.paths.TW_idx + 1;
   tankExists = exist( ...
      fullfile(blockObj.paths.TW_ext{blockObj.paths.TW_idx}),'dir')~=0;
   
   if tankExists
      blockObj.paths.TW = blockObj.paths.TW_ext{blockObj.paths.TW_idx};
      break;
   end   
end

if ~tankExists % If it still doesn't exist, check for new one
   updatePaths(blockObj);
end

%% UPDATE ALL OTHER PATHS TO REFLECT CORRECT ROOT PATH
blockObj.paths.RW    = fullfile(blockObj.paths.TW,[blockObj.Name RAW_ID] );
blockObj.paths.FW    = fullfile(blockObj.paths.TW,[blockObj.Name FILT_ID]);
blockObj.paths.CARW  = fullfile(blockObj.paths.TW,[blockObj.Name CAR_ID] );
blockObj.paths.DW    = fullfile(blockObj.paths.TW,[blockObj.Name DIG_ID] );
blockObj.paths.LW    = fullfile(blockObj.paths.TW,[blockObj.Name LFP_ID] );
blockObj.paths.SDW   = fullfile(blockObj.paths.TW,[blockObj.Name SD_ID]  );
blockObj.paths.MW    = fullfile(blockObj.paths.TW,[blockObj.Name META_ID]);

all_fields = fieldnames(blockObj.paths);
all_fields = reshape(all_fields,1,numel(all_fields));

for paths_ = all_fields
    % Checks if all the target paths exist, if not mkdir
    if ~iscell(blockObj.paths.(paths_{:}))
       if ~isnumeric(blockObj.paths.(paths_{:}))
          if exist(blockObj.paths.(paths_{:}),'dir')==0
              mkdir(blockObj.paths.(paths_{:}));
          end
       end
    end
end

if exist(fullfile(blockObj.paths.DW,'STIM_DATA'),'dir')==0
    mkdir(fullfile(blockObj.paths.DW,'STIM_DATA'));
end

if exist(fullfile(blockObj.paths.DW,'DC_AMP'),'dir')==0
    mkdir(fullfile(blockObj.paths.DW,'DC_AMP'));
end

% ProbeChannel    = ID.ProbeChannel;
blockObj.paths.TW_N       = fullfile(blockObj.paths.TW,  [blockObj.Name ID.Time.File  '.mat']);
blockObj.paths.RW_N      = fullfile(blockObj.paths.RW,  [blockObj.Name ID.Raw.File  '.mat']);
blockObj.paths.FW_N      = fullfile(blockObj.paths.FW,  [blockObj.Name ID.Filt.File '.mat']);
blockObj.paths.CARW_N    = fullfile(blockObj.paths.CARW,[blockObj.Name ID.CAR.File '.mat']);
blockObj.paths.DW_N      = fullfile(blockObj.paths.DW,  [blockObj.Name '_DIG_%s.mat']);
blockObj.paths.LW_N      = fullfile(blockObj.paths.LW,  [blockObj.Name ID.LFP.File '.mat']);
blockObj.paths.SDW_N     = fullfile(blockObj.paths.SDW,  [blockObj.Name ID.Spikes.File '.mat']);
for ii = 1:numel(ID.Meta.File)
   propName = lower(strrep(ID.Meta.Tag{ii},'_',''));
   propName = strsplit(propName,'.');
   propName = propName{1};
   blockObj.paths.MW_N.(propName) = ...
      fullfile(blockObj.paths.MW,  [blockObj.Name ID.Meta.File{ii}]);
end
flag = true;

end