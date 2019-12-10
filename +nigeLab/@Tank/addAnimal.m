function addAnimal(tankObj,animalPath,idx)
% ADDANIMAL  Method to add animal to nigeLab.Tank Animals property
%
%  tankObj.addAnimal();
%     --> Allows selection of animals from UI
%  tankObj.addAnimal('AnimalFolder');
%     --> Adds animal corresponding to 'AnimalFolder'
%  tankObj.addAnimal({'aFolder1','aFolder2',...});
%     --> Adds multiple animals from cell array of folder chars
%  tankObj.addAnimal(animalObj);
%     --> Adds animalObj directly, which could be a scalar
%         animalObj or an array.
%  tankObj.addAnimal(animalObj,idx);
%     --> Specifies the array index to add the animal to

% Check inputs
if nargin<2
   animalPath = '';
end

if iscell(animalPath)
   for i = 1:numel(animalPath)
      tankObj.addAnimal(animalPath{i});
   end
   return;
end

if isa(animalPath,'nigeLab.Animal')
   if numel(animalPath) > 1
      animalObj = reshape(animalPath,1,numel(animalPath));
   else
      animalObj = animalPath;
   end
else
   % Parse AnimalFolder from UI
   if isempty(animalPath)
      animalPath = uigetdir(tankObj.RecDir,...
         'Select animal folder');
      if animalPath == 0
         error(['nigeLab:' mfilename ':NoAnimalSelection'],...
            'No ANIMAL selected. Object not created.');
      end
   else
      if exist(animalPath,'dir')==0
         error(['nigeLab:', mfilename ':invalidAnimalPath'],...
            '%s is not a valid ANIMAL directory.',animalPath);
      end
   end
   animalObj = nigeLab.Animal(animalPath,tankObj.Paths.SaveLoc);
end

% If no indexing is provided, just concatenate animalObj to end of array
if nargin < 3
   tankObj.Animals = [tankObj.Animals animalObj];
   
% If indexing is provided, assign using indexing
else
   tankObj.Animals(idx) = animalObj;
end

% For each element added to tankObj.Animals (animalObj), initialize the
% .Listener property as a listener handle that assigns [] to the
% corresponding Animals index of Tank if the Animal object is deleted.
for i = 1:numel(animalObj)
   animalObj(i).Listener = addlistener(animalObj(i),...
      'ObjectBeingDestroyed',...
      @tankObj.AssignNULL);
end

end
