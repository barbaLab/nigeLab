function setSaveLocation(blockObj)
%% SETSAVELOCATION   Set the save location for processed TANK
%
%  tankObj.SETSAVELOCATION;
%
% By: Max Murphy  v1.0  06/15/2018  Original version (R2017b)

%% Prompt for location using previously set location
tmp = uigetdir(blockObj.SaveLoc,...
   'Set Processed Tank Location');

%% Abort if cancel was clicked, otherwise set it
if tmp == 0
   error('Process canceled.');
else
   blockObj.SaveLoc = tmp;
end

end