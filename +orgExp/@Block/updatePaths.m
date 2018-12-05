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
   tankPath = uigetdir(blockObj.SaveLocDefault,'Select TANK path');
   if tankPath == 0
      fprintf(1,'Paths not updated.\n');
      return;
   end
elseif exist(tankPath,'dir')==0
   fprintf(1,'tankPath (%s) does not exist.\n',tankPath);
   return;
end

%% IF NEW TANK PATH EXISTS, APPEND TO PATHS STRUCTURE AND UPDATE
flag = genPaths(blockObj,tankPath);

end

