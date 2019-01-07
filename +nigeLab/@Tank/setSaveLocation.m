function setSaveLocation(tankObj,saveloc)
%% SETSAVELOCATION   Set the save location for processed TANK
%
%  tankObj.SETSAVELOCATION;
%
% By: Max Murphy  v1.0  06/15/2018  Original version (R2017b)

%% Prompt for location using previously set location
if nargin<2 || isempty(saveloc)
tmp = uigetdir(tankObj.DIR,...
   'Set Processed Tank Location');
elseif nargin==2
   tmp = saveloc;
end
%% Abort if cancel was clicked, otherwise set it
if tmp == 0
   error('Process canceled.');
else
   tankObj.SaveLoc = fullfile(tmp,tankObj.Name);
   for aa=tankObj.Animals
       aa.setSaveLocation(tankObj.SaveLoc);
   end
end

end