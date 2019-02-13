function init(animalObj)
%% INIT  Initialize nigeLab.Animal class object
%
%  animalObj.init;
%
% By: Federico Barban & Max Murphy MAECI 2018 Collaboration

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
Recordings = dir(fullfile(animalObj.RecDir));
Recordings = Recordings(~ismember({Recordings.name},{'.','..'}));

for bb=1:numel(Recordings)
   [~,~,ext] = fileparts(Recordings(bb).name);
   addBlock = false;
   if Recordings(bb).isdir
      tmp = dir(fullfile(animalObj.RecDir,Recordings(bb).name,'*.tev'));
      if ~isempty(tmp)
         addBlock = true;
         RecFile = fullfile(tmp.folder,tmp.name);
      end
   elseif any(strcmp(ext,supportedFormats))
      addBlock = true;
      RecFile = fullfile(Recordings(bb).folder,Recordings(bb).name);
   end
   
   if  addBlock
      animalObj.addBlock(RecFile);
   end
end
animalObj.save;
end

