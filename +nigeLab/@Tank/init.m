function flag = init(tankObj)
% INIT Initialize TANK object
%
%  flag = tankObj.init;
 
%% PARSE NAME AND SAVE LOCATION
flag = false;
% Ensure that only ANIMAL FOLDERS are used here
AnimalsNames=dir(tankObj.RecDir);
AnimalsNames=AnimalsNames(~ismember({AnimalsNames.name},{'.','..'})); 
AnimalsNames=AnimalsNames([AnimalsNames.isdir]);
tankObj.checkParallelCompatibility(true);
tankObj.Children = nigeLab.Animal.Empty([1,numel(AnimalsNames)]);
for idx=1:numel(AnimalsNames)
    animalPath = nigeLab.utils.getUNCPath(AnimalsNames(idx).folder,...
                                          AnimalsNames(idx).name);
    tankObj.addChild(animalPath,idx);
end
flag = true;
flag = flag && tankObj.save;
end