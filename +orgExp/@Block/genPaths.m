function flag = genPaths(blockObj,tankPath)
%% GENPATHS    Set some useful path variables to file locations
%
%  flag = GENPATHS(blockObj);
%  flag = GENPATHS(blockObj,tankPath);
%
%     Here are defined all the paths where data will be saved.
%     The folder tree is also created here(if not already exsting)
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
flag = false;
paths.TW    = fullfile(blockObj.SaveLoc);

if (nargin > 1) && (~isempty(blockObj.paths))
   paths.TW_ext = [paths.TW_ext; {tankPath}];
   paths.TW_idx = numel(paths.TW_ext);
else
   paths.TW_ext = {fullfile(blockObj.SaveLoc)};
   paths.TW_idx = 1;
end

blockObj.paths = paths;
flag = findCorrectPath(blockObj);

end