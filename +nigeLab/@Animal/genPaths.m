function flag = genPaths(animalObj,SaveLoc)
%% GENPATHS    Set some useful path variables to file locations
%
%  flag = GENPATHS(blockObj);
%  flag = GENPATHS(blockObj,animalPath);
%
%     Here are defined all the paths where data will be saved.
%     The folder tree is also created here(if not already existing)
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% 
flag = false;
if (nargin > 1)
   paths.SaveLoc = fullfile(SaveLoc,animalObj.Name);
else
   paths.SaveLoc     = fullfile(animalObj.TanklLoc,animalObj.Name);
end
if ~exist(paths.SaveLoc,'dir'), mkdir(paths.SaveLoc);end
animalObj.Paths = paths;
% flag = findCorrectPath(animalObj,paths);
flag = true;
end