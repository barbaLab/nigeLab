function flag = genPaths(blockObj,animalLoc)
% GENPATHS    Set some useful path variables to file locations
%
%  flag = GENPATHS(blockObj);
%  flag = GENPATHS(blockObj,animalLoc);
%
%     Here are defined all the paths where data will be saved.
%     The folder tree is also created here(if not already existing)
%
%  blockObj.Paths is updated in this method.

%% Check input; if animalLoc is given, update blockObj property
flag = false;
if (nargin > 1)
   blockObj.AnimalLoc = animalLoc;
end

%% Update paths struct
% Initialize paths struct
paths = struct;
paths.SaveLoc = struct;


paths.SaveLoc.dir = nigeLab.utils.getUNCPath(blockObj.AnimalLoc,...
   blockObj.Name);
paths = blockObj.getFolderTree(paths);

% Iterate on all the fieldnames, making the folder if it doesn't exist yet
F = fieldnames(paths);
for ff=1:numel(F)
   if exist(paths.(F{ff}).dir,'dir')==0
      mkdir(paths.(F{ff}).dir);
   end 
end
blockObj.Paths = paths;
flag = true;

end