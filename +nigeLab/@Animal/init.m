function init(animalObj)
% INIT  Initialize nigeLab.Animal class object
%
%  animalObj.init;

%%
[~,animalName] = fileparts(animalObj.RecDir);
animalObj.Name = animalName;

%% GET/CREATE SAVE LOCATION FOR BLOCK
% animalObj.TankLoc is probably empty [] at this point, which will prompt 
% a UI to point to the block save directory:
if ~animalObj.getSaveLocation(animalObj.TankLoc)
   flag = false;
   warning('Save location not set successfully.');
   return;
end

supportedFormats = animalObj.Pars.SupportedFormats;

%% GET BLOCKS
% Remove other folder names
Recordings = dir(fullfile(animalObj.RecDir));
Recordings = Recordings(~ismember({Recordings.name},{'.','..'}));

animalObj.Blocks = nigeLab.Block.Empty([1,numel(Recordings)]);
skipVec = false([1,numel(Recordings)]);
for bb=1:numel(Recordings)
   if skipVec(bb)
      continue;
   end
   
   [~,~,ext] = fileparts(Recordings(bb).name);
   
   % Cases where block is to be added will toggle this flag
   addBlock = false;
   if Recordings(bb).isdir
      
      % handling tdt case
      if ~isempty(dir(fullfile(animalObj.RecDir,Recordings(bb).name,'*.tev')))
         addBlock = true;
         tmp = dir(fullfile(animalObj.RecDir,Recordings(bb).name,'*.tev'));
         RecFile = fullfile(tmp.folder,tmp.name);
         
      % handling already extracted to matfile case
      elseif ~isempty(dir(fullfile(animalObj.RecDir,Recordings(bb).name,'*Info.mat')))
         addBlock = true;
         tmp = dir(fullfile(animalObj.RecDir,Recordings(bb).name,'*Info.mat'));
         RecFile = fullfile(tmp.folder,tmp.name);
      
      % handling already-extracted in nigelFormat case 
      else 
         RecFile = nigeLab.utils.getUNCPath(fullfile(...
               animalObj.RecDir,Recordings(bb).name,...
               nigeLab.defaults.Block('FolderIdentifier')));
         if exist(RecFile,'file')~=0
            addBlock = true;
            RecFile = nigeLab.utils.getUNCPath(...
               animalObj.RecDir,Recordings(bb).name);
            blockFileName = [Recordings(bb).name '_Block.mat'];
            tmpName = {Recordings.name};
            idx = ismember(tmpName,blockFileName);
            skipVec(idx) = true;
            if any(idx)
               RecFile = [RecFile '_Block.mat']; %#ok<*AGROW>
               load(RecFile,'blockObj');
               RecFile = blockObj;
            end
         elseif animalObj.Pars.OnlyBlockFoldersAtAnimalLevel
            addBlock = true;
            % Don't "double-count" Block from Folder and _Block.mat
            tmpName = {Recordings.name};
            blockFileName = [Recordings(bb).name '_Block.mat'];
            idx = ismember(tmpName,blockFileName);
            skipVec(idx) = true;
            if any(idx)
               load(nigeLab.utils.getUNCPath(animalObj.RecDir,...
                  blockFileName),'blockObj');
               RecFile = blockObj;
            else
               RecFile = nigeLab.utils.getUNCPath(animalObj.RecDir,...
                                                Recordings(bb).name);
            end
         end
      end
      
   elseif any(strcmp(ext,supportedFormats))
      addBlock = true;
      RecFile = fullfile(Recordings(bb).folder,Recordings(bb).name);

   elseif strcmp(ext,'.mat')
      addBlock = true;
      load(fullfile(Recordings(bb).folder,Recordings(bb).name),'blockObj');
      RecFile = blockObj;

   end
   
   if  addBlock
      animalObj.addBlock(RecFile);
      animalObj.MultiAnimals = any([animalObj.Blocks.MultiAnimals]);
   end
   skipVec(bb) = ~addBlock;
end
animalObj.Blocks(skipVec) = [];
animalObj.save;
end