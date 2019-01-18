function init(animalObj)
%% INIT  Initialize nigeLab.Animal class object
%
%  animalObj.init;
%
% By: Federico Barban & Max Murphy MAECI 2018 Collaboration

%%
[~,animalName] = fileparts(animalObj.RecDir);
animalObj.Name = animalName;

animalObj.setSaveLocation(animalObj.AnimalLoc);

if exist(animalObj.SaveLoc,'dir')==0
    mkdir(animalObj.SaveLoc);
    animalObj.ExtractFlag = true;
else
    animalObj.ExtractFlag = false;
end

supportedFormats = animalObj.Pars.Animal.SupportedFormats;


Recordings = dir(fullfile(animalObj.RecDir));
Recordings=Recordings(~ismember({Recordings.name},{'.','..'}));

for bb=1:numel(Recordings)
   [~,~,ext] = fileparts(Recordings(bb).name);
   addBlock=false;
   if Recordings(bb).isdir
      tmp=dir(fullfile(animalObj.RecDir,Recordings(bb).name,'*.tev'));
      if ~isempty(tmp)
         addBlock=true;
         RecFile=fullfile(tmp.folder,tmp.name);
      end
   elseif any(strcmp(ext,supportedFormats))
      addBlock=true;
      RecFile=fullfile(Recordings(bb).folder,Recordings(bb).name);
   end
   
   if  addBlock
      animalObj.addBlock(RecFile);
   end
end
animalObj.save;
end

