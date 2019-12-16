function flag = getSaveLocation(blockObj,animalLoc)
% GETSAVELOCATION   Set the save location for ANIMAL, the container folder
%                   that holds the file hierarchy referenced by BLOCK.
%
%  flag = blockObj.GETSAVELOCATION;
%  --> Prompts for ANIMAL location from a user interface (UI)
%
%  flag = blockObj.GETSAVELOCATION('save/path/here');
%  --> Skips the selection interface

%% Reporter flag for whether this was executed properly
flag = false;

%% Prompt for location using previously set location
if nargin < 2 
   tmp = uigetdir(blockObj.AnimalLocDefault,'Select folder with ANIMAL name');
elseif isempty(animalLoc) % if nargin is < 2, will throw error if above
   tmp = uigetdir(blockObj.AnimalLocDefault,'Select folder with ANIMAL name');
else
   tmp = animalLoc;
end

%% Abort if cancel was clicked, otherwise set it
if tmp == 0
   error(['nigeLab:' mfilename ':selectionCanceled'],...
          'No ANIMAL container for BLOCK selected. Object not created.');
else
   % Make sure it's a valid directory, as it could be provided through
   % second input argument:
   if ~blockObj.genPaths(tmp)
      mkdir(nigeLab.utils.getUNCPath(blockObj.Paths.Block));
      if ~blockObj.genPaths(tmp)
         warning('Still no valid Animal/Block location.');
      else
         flag = true;
      end
   else
      blockObj.AnimalLoc = nigeLab.utils.getUNCPath(tmp);
      flag = true;
   end
end

end