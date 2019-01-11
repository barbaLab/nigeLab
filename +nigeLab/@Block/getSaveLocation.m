function flag = getSaveLocation(blockObj,animalLoc)
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
   tmp = uigetdir(blockObj.AnimalLocDefault,'Select ANIMAL location');
elseif isempty(animalLoc) % if nargin is < 2, will throw error if above
   tmp = uigetdir(blockObj.AnimalLocDefault,'Select ANIMAL location');
else
   tmp = animalLoc;
end

%% Abort if cancel was clicked, otherwise set it
if tmp == 0
   disp('Save location selection canceled manually.');
else
   % Make sure it's a valid directory, as it could be provided through
   % second input argument:
   flag = blockObj.genPaths(animalPath);
end

end