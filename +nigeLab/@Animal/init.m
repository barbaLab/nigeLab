function init(animalObj)
[~,NAME] = fileparts(animalObj.RecDir);
animalObj.Name = NAME;

animalObj.setSaveLocation(animalObj.SaveLoc);

if exist(animalObj.SaveLoc,'dir')==0
    mkdir(animalObj.SaveLoc);
    animalObj.ExtractFlag = true;
else
    animalObj.ExtractFlag = false;
end


supportedFormats={'rhs','rhd','tdt'};

Recordings = dir(fullfile(animalObj.RecDir));
Recordings=Recordings(~ismember({Recordings.name},{'.','..'}));

for bb=1:numel(Recordings)
   [PATHSTR,NAME,ext] = fileparts(Recordings(bb).name);
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

