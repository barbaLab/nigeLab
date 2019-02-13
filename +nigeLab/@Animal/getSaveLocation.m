function flag = getSaveLocation(animalObj,tankLoc)
%% GETSAVELOCATION   Set the save location for processed TANK
%
%  flag = blockObj.GETSAVELOCATION;
%  flag = blockObj.GETSAVELOCATION('save/path/here');
%
% By: Max Murphy  v1.0  06/15/2018  Original version (R2017b)

%% Reporter flag for whether this was executed properly
flag = false;

%% Prompt for location using previously set location
if nargin < 2 
   tmp = uigetdir(animalObj.AnimalLocDefault,'Select TANK location');
elseif isempty(tankLoc) % if nargin is < 2, will throw error if above
   tmp = uigetdir(animalObj.TankLocDefault,'Select TANK location');
else
   tmp = tankLoc;
end

%% Abort if cancel was clicked, otherwise set it
if tmp == 0
   disp('Save location selection canceled manually.');
else
   % Make sure it's a valid directory, as it could be provided through
   % second input argument:
   if ~animalObj.genPaths(tmp)
      mkdir(animalObj.Paths.SaveLoc);
      if ~animalObj.genPaths(tmp)
         warning('Still no valid Animal location.');
      else
         flag = true;
      end
   else
      flag = true;
   end
end

end