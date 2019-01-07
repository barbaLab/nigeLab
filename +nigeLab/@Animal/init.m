function init(animalObj)
[~,NAME] = fileparts(animalObj.DIR);
animalObj.Name = NAME;

animalObj.setSaveLocation(animalObj.SaveLoc);

if exist(animalObj.SaveLoc,'dir')==0
    mkdir(animalObj.SaveLoc);
    animalObj.ExtractFlag = true;
else
    animalObj.ExtractFlag = false;
end


supportedFormats={'rhs','rhd','tdt'};
Recordings=[];
for i=supportedFormats
 Recordings = [ Recordings dir(fullfile(animalObj.DIR,['*.' i{:}]))];
end
Recordings=Recordings(~ismember({Recordings.name},{'.','..'}));
Recordings=Recordings(~[Recordings.isdir]);

for bb=1:numel(Recordings)
    RecFile=fullfile(Recordings(bb).folder,Recordings(bb).name);
    animalObj.addBlock(RecFile);
end
animalObj.save;
end

