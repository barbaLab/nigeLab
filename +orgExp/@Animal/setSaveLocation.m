function setSaveLocation(animalObj)
%% SETSAVELOCATION   Set the save location for processed ANIMAL
%
%  animalObj.SETSAVELOCATION;
%
% By: Max Murphy  v1.0  06/15/2018  Original version (R2017b)

%% Prompt for location using previously set location
tmp = uigetdir(animalObj.SaveLoc,...
   'Set Processed Animal Location');

%% Abort if cancel was clicked, otherwise set it
if tmp == 0
   error('Process canceled.');
else
   animalObj.SaveLoc = tmp;
end

end