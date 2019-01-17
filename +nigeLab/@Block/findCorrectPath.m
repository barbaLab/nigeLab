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
N = numel(blockObj.Paths.Animal_ext);
blockObj.Paths.Animal_idx = 0;
while blockObj.Paths.Animal_idx < N
   blockObj.Paths.Animal_idx = blockObj.Paths.Animal_idx + 1;
   idx = blockObj.Paths.Animal_idx;
   animalExists = exist(fullfile(blockObj.Paths.Animal_ext{idx}),'dir')~=0;
   if animalExists
      blockObj.Paths.Animal = blockObj.Paths.Animal_ext{idx};
      blockObj.Paths.Block = fullfile(blockObj.Paths.Animal,blockObj.Name);
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
   
   if contains(p.Folder,'%s') % Parse for spikes stuff
      p.Folder = sprintf(strrep(p.Folder,'\','/'),...
         blockObj.SDPars.ID.(F{iF}));
   end
   
   % Set folder name for this particular Field
   paths.(F{iF}).dir = fullfile(blockObj.Paths.Animal,blockObj.Name,...
      [blockObj.Name,blockObj.Delimiter,p.Folder]);
   
   % Parse for both old and new versions of file naming convention
   paths.(F{iF}).file = fullfile(paths.(F{iF}).dir,[blockObj.Name p.File]);
   paths.(F{iF}).old = getOldFiles(p,paths.(F{iF}));
   paths.(F{iF}).info = fullfile(paths.(F{iF}).dir,[blockObj.Name p.Info]);
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
         if isempty(O)
            old.(f) = O;
         else
            if O(1).isdir
               old.(f) = dir(fullfile(O(1).folder,O(1).name,...
                  p.OldFile{iO}));
            else
               old.(f) = O;
            end
         end
      end
   end

end