function flag = getSaveLocation(tankObj,tankLoc)
% GETSAVELOCATION   Set the save location for processed TANK
%
%  flag = tankObj.getSaveLocation();
%  flag = tankObj.getSaveLocation('save/path/here');

%% Reporter flag for whether this was executed properly
flag = false;

%% Prompt for location using previously set location
if nargin < 2 
   tmp = uigetdir(tankObj.DefaultSaveLoc,'Select TANK location');
elseif isempty(tankLoc) % if nargin is < 2, will throw error if above
   tmp = uigetdir(tankObj.DefaultSaveLoc,'Select TANK location');
else
   tmp = tankLoc;
end
tmp = nigeLab.utils.getUNCPath(tmp);
%% Abort if cancel was clicked, otherwise set it
if tmp == 0
   error(['nigeLab:' mfilename ':selectionCanceled'],...
          'No TANK save location selected. Object not created.');
else
   % Make sure it's a valid directory, as it could be provided through
   % second input argument:
   if ~tankObj.genPaths(tmp)
      mkdir(tankObj.Paths.SaveLoc);
      if ~tankObj.genPaths(tmp)
         warning('Still no valid Animal location.');
      else
         flag = true;
      end
   else
      flag = true;
   end
end

end