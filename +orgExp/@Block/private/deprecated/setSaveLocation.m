function flag = setSaveLocation(blockObj,saveLoc)
%% SETSAVELOCATION   Set the save location for processed TANK
%
%  flag = tankObj.SETSAVELOCATION;
%  flag = tankObj.SETSAVELOCATION('save/path/here');
%
% By: Max Murphy  v1.0  06/15/2018  Original version (R2017b)

%% Reporter flag for whether this was executed properly
flag = false;

%% Prompt for location using previously set location
if nargin<2 || isempty(saveLoc)
   tmp = uigetdir(blockObj.SaveLocDefault,...
               'Set Processed BLOCK Location');
elseif nargin==2
   tmp = saveLoc;
end

%% Abort if cancel was clicked, otherwise set it
if tmp == 0
   disp('Save location selection canceled manually.');
else
   % Make sure it's a valid directory, as it could be provided through
   % second input argument:
   if exist(tmp,'dir')~=0
      blockObj.SaveLoc = fullfile(tmp,blockObj.Name);
      blockObj.genPaths;
      flag = true;
   elseif blockObj.ForceSaveLoc
      blockObj.SaveLoc = fullfile(tmp,blockObj.Name);
      mkdir(blockObj.SaveLoc);
      blockObj.genPaths;
      flag = true;
   end
end

end