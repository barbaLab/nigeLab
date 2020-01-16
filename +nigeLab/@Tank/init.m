function flag = init(tankObj)
% INIT Initialize TANK object
%
%  flag = tankObj.init;
 
%% PARSE NAME AND SAVE LOCATION
flag = false;
% Put the .nigelTank file to begin with...(forgot this -MM)
tankObj.saveIDFile();

% Ensure that only ANIMAL FOLDERS are used here
AnimalsNames=dir(tankObj.RecDir);
AnimalsNames=AnimalsNames(~ismember({AnimalsNames.name},{'.','..'})); 
AnimalsNames=AnimalsNames([AnimalsNames.isdir]);
tankObj.checkParallelCompatibility(true);
for idx=1:numel(AnimalsNames)
    animalPath = nigeLab.utils.getUNCPath(AnimalsNames(idx).folder,...
                                          AnimalsNames(idx).name);
    tankObj.addChild(animalPath);
end
flag = true;
flag = flag && tankObj.save;
end