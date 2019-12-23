function flag = init(tankObj)
% INIT Initialize TANK object
%
%  flag = tankObj.init;
 
%% PARSE NAME AND SAVE LOCATION
flag = false;
tmpName = strsplit(tankObj.RecDir,filesep);
tankObj.Name = tmpName{end};


if ~tankObj.getSaveLocation(tankObj.SaveLoc)
   flag = false;
   warning('Save location not set successfully.');
   return;
end

%% DO CONVERSION OR CHECK AND CREATE METADATA FOR TANK
% Read the directory structure the tank is pointed to, 
% infer metadata from there such as rats used in experiments and blocks
% associated with rats. Then init Animal array and inside each animal init
% the block array. Might be better to leave the block management entire to
% the rat class.

% Ensure that only ANIMAL FOLDERS are used here
AnimalsNames=dir(tankObj.RecDir);
AnimalsNames=AnimalsNames(~ismember({AnimalsNames.name},{'.','..'})); 
AnimalsNames=AnimalsNames([AnimalsNames.isdir]);
tankObj.checkParallelCompatibility();
tankObj.Animals = nigeLab.Animal.Empty([1,numel(AnimalsNames)]);
for idx=1:numel(AnimalsNames)
    animalPath = nigeLab.utils.getUNCPath(...
                  fullfile(AnimalsNames(idx).folder,...
                           AnimalsNames(idx).name));
    tankObj.addAnimal(animalPath,idx);
end

tankObj.save;
flag = true;
end