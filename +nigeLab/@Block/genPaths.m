function flag = genPaths(blockObj,animalPath)
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
if (nargin > 1)
   paths.Animal = animalPath;
   if isempty(blockObj.paths)
      paths.Animal_ext = [blockObj.paths.AnimalLoc; {animalPath}];
      paths.Animal_idx = 2;
   else
      paths.Animal_ext = [blockObj.paths.Animal_ext; {animalPath}];
      paths.Animal_idx = numel(blockObj.paths.Animal_ext);
   end
else
   paths.Animal     = fullfile(blockObj.AnimalLoc);
   paths.Animal_ext = {fullfile(blockObj.AnimalLoc)};
   paths.Animal_idx = 1;
end

blockObj.paths = paths;
flag = findCorrectPath(blockObj,paths);

end