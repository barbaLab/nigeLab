function flag = genPaths(blockObj,animalLoc)
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
   paths.Animal = animalLoc;
   if isempty(blockObj.Paths)
      paths.Animal_ext = {animalLoc};
      paths.Animal_idx = 1;
   else
      paths.Animal_ext = [blockObj.Paths.Animal_ext; {animalLoc}];
      paths.Animal_idx = numel(blockObj.Paths.Animal_ext);
   end
else
   paths.Animal     = fullfile(blockObj.AnimalLoc);
   paths.Animal_ext = {fullfile(blockObj.AnimalLoc)};
   paths.Animal_idx = 1;
end

paths.Block = fullfile(paths.Animal,blockObj.Name);
blockObj.Paths = paths;
flag = findCorrectPath(blockObj,paths);

end