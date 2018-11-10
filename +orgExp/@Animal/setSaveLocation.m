function  setSaveLocation(animalObj,saveloc)
%% SETSAVELOCATION   Set the save location for processed ANIMAL
%
%  animalObj.SETSAVELOCATION;
%
% By: Max Murphy  v1.0  06/15/2018  Original version (R2017b)

%% Prompt for location using previously set location
if nargin<2 || isempty(saveloc)
tmp = uigetdir(animalObj.DIR,...
   'Set Processed Tank Location');
elseif nargin==2
   tmp = saveloc;
end
%% Abort if cancel was clicked, otherwise set it
if tmp == 0
   error('Process canceled.');
else
   animalObj.SaveLoc = fullfile(tmp,animalObj.Name);
   for bb=animalObj.Blocks
       bb.setSaveLocation(animalObj.SaveLoc);
   end
end

end