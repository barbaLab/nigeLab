function flag = findCorrectPath(blockObj,paths)
%% FINDCORRECTPATH    Update the paths struct to reflect correct ANIMAL
%
%  flag = FINDCORRECTPATH(blockObj,paths);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     BLOCK class object from orgExp package.
%
%   paths      :     Struct containing file/path string formatting fields.
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Flag indicating if setting new path was successful.
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%% PARSE CORRECT ROOT PATH
flag = false;
N = numel(blockObj.paths.Animal_ext);
blockObj.paths.Animal_idx = 0;
while blockObj.paths.Animal_idx <= N
   blockObj.paths.Animal_idx = blockObj.paths.Animal_idx + 1;
   idx = blockObj.paths.Animal_idx;
   animalExists = exist(fullfile(blockObj.paths.Animal_ext{idx}),'dir')~=0;
   if animalExists
      blockObj.paths.Animal = blockObj.paths.Animal_ext{idx};
      blockObj.paths.Block = fullfile(blockObj.paths.Animal,blockObj.Name);
      break;
   end
end

if ~animalExists
   warning('Could not find ANIMAL path.');
   return;
end

%% UPDATE ALL OTHER PATHS TO REFLECT CORRECT ROOT (ANIMAL) PATH
F = fieldnames(blockObj.BlockPars);
for iF = 1:numel(F) % For each field, update field type
   p = blockObj.BlockPars.(F{iF});
   % Set folder name for this particular Field
   paths.(F{iF}).dir = fullfile(blockObj.paths.Animal,blockObj.Name,...
      [blockObj.Name,blockObj.Delimiter,p.(F{iF}).Folder]);
   % If folder does not exist, make it
   if exist(paths.(F{iF}).dir,'dir')==0
      mkdir(paths.(F{iF}).dir);
   end
   % Parse for both old and new versions of file naming convention
   paths.(F{iF}).file = fullfile(paths.(F{iF}).dir,[blockObj.Name p.File]);
   paths.(F{iF}).old = getOldFiles(p,paths.(F{iF}));
end

blockObj.Paths = paths; % Assign the paths struct
flag = true;

   function old = getOldFiles(p,fieldPath)
      %% GETOLDFILES  Get struct with file info for possible old files
      old = struct;
      for iO = 1:numel(p.OldFile)
         f = strsplit(p.OldFile{iO},'.');
         f = deblank(strrep(f{1},'*',''));
         O = dir(fullfile(fieldPath.dir,p.OldFile{iO}));
         if O(1).isdir
            old.(f) = dir(fullfile(O(1).folder,O(1).name,...
               p.OldFile{iO}));
         else
            old.(f) = O;
         end
      end
   end

end