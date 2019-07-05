function flag = updatePaths(blockObj,tankPath)
%% UPDATEPATHS    Update the paths struct to reflect a new TANK
%
%  load('blockObj.mat'); % A block object extracted using a different file
%                        %    system, with a different naming convention
%                        %    for each mapped drive.
%
%  flag = updatePaths(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class object from orgExp package.
%
%  tankPath    :     New tank path, where animal and block structure are
%                       still the same as before.
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Flag indicating if setting new path was successful.
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%% PARSE INPUT
flag = false;

if nargin < 2
   if exist(blockObj.SaveLoc,'dir')==0
      tankPath = uigetdir(blockObj.AnimalLocDefault,'Select ANIMAL path');
      if tankPath == 0
         fprintf(1,'Paths not updated.\n');
         return;
      end
   else
      flag = genPaths(blockObj);
      return;
   end
elseif exist(tankPath,'dir')==0
   fprintf(1,'tankPath (%s) does not exist.\n',tankPath);
   return;
end

%% IF NEW TANK PATH EXISTS, APPEND TO PATHS STRUCTURE AND UPDATE
if ~genPaths(blockObj,tankPath)
   warning('Could not generate new paths.');
   return;
end

%% UPDATE MAT FILES WITH NEW FILE LOCATIONS
flag = linkToData(blockObj);

end

