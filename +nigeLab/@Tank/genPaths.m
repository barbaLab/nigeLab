function flag = genPaths(tankObj,SaveLoc)
% GENPATHS    Set some useful path variables to file locations
%
%  flag = tankObj.genPaths();
%  flag = tankObj.genPaths(animalPath);
%
%     Here are defined all the paths where data will be saved.
%     The folder tree is also created here(if not already existing)

%% 
flag = false;
if (nargin > 1)
   paths.SaveLoc = fullfile(SaveLoc,tankObj.Name);
else
   paths.SaveLoc = fullfile(tankObj.TankLoc,tankObj.Name);
end

if exist(paths.SaveLoc,'dir')==0
   mkdir(paths.SaveLoc);
end

tankObj.Paths = paths;
flag = true;
end