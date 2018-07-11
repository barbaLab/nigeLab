function init(tankObj)
%% INIT Initialize TANK object
%
%  tankObj.INIT;
%
%  By: Max Murphy v1.0  06/14/2018 Original version (R2017b)
 
%% PARSE NAME AND SAVE LOCATION
tankObj.Name = strsplit(tankObj.DIR,filesep);
tankObj.Name = tankObj.Name{end};

if isempty(tankObj.SaveLoc)
   tankObj.SaveLoc = fullfile(tankObj.DefaultSaveLoc,...
                              tankObj.RecType);
   tankObj.setSaveLocation;
   
   if exist(fullfile(tankObj.SaveLoc,tankObj.Name),'dir')==0
      mkdir(fullfile(tankObj.SaveLoc,tankObj.Name));
      tankObj.ExtractFlag = true;
   else
      tankObj.ExtractFlag = false;
   end
end

%% DO CONVERSION OR CHECK AND CREATE METADATA FOR TANK
% WIP Read the directory structure the tank is pointed to, 
% infer metadata from there such as rats used in experiments and blocks
% associated with rats. Then init Animal array and inside each animal init
% the block array. Might be better to leave the block management entire to
% the rat class.

tankObj.Animals=[];
AnimalsNames=dir(tankObj.DIR);
AnimalsNames=AnimalsNames(~ismember({AnimalsNames.name},{'.','..'}));   % remove . and ..
AnimalsNames=AnimalsNames([AnimalsNames.isdir]); % take only folders, just in case
for rr=1:numel(AnimalsNames)
    AnimalFolder=fullfile(AnimalsNames(rr).folder,AnimalsNames(rr).name);
    tankObj.addAnimal(AnimalFolder);
end
% if tankObj.ExtractFlag
%    tankObj.convert(tankObj.CheckBeforeConversion);
% else
%    tankObj.createMetadata;
% end

tankObj.save;
end