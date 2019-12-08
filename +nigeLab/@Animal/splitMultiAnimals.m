function flag = splitMultiAnimals(animalObj,varargin)
if nargin < 2
    ...
elseif nargin < 3
switch class(varargin{1})
    case  'uiw.widget.Tree'
        Tree = varargin{1};
        ApplyChanges(animalObj,Tree);
        return;
    case 'string'
        if strcmpi(varargin{1},'noGui')
        else
        end
    otherwise
        ...
end
end

if ~(animalObj.MultiAnimals)
    warning('No multi animals recording detected');
    return;
end
addlistener(animalObj.Blocks,'ObjectBeingDestroyed',@(h,e)deleteAnimalWhenEmpty(animalObj));

if isempty(animalObj.MultiAnimalsLinkedAnimals)
    TankPath = fileparts(animalObj.Paths.SaveLoc);
    for ii =1 : numel(animalObj.Blocks)
        animalObj.Blocks(ii).splitMultiAnimals('init');
        Metas = [animalObj.Blocks(ii).MultiAnimalsLinkedBlocks.Meta];
        animalObjPaths{ii} = cellfun(@(x) fullfile(TankPath,x),{Metas.AnimalID},'UniformOutput',false);
    end % ii
    uAnimals = unique([animalObjPaths{:}]);
    splittedAnimals = [];
    for ii= 1:numel(uAnimals)
        an = copy(animalObj);
        an.Blocks = [];
        an.Paths.SaveLoc = uAnimals{ii};
        [~,Name]=fileparts(uAnimals{ii});
        an.Name = Name;
        an.save;
         splittedAnimals = [splittedAnimals, an];
    end
    animalObj.MultiAnimalsLinkedAnimals = splittedAnimals;
    animalObj.save;
end %fi
end %function

function ApplyChanges(animalobj,Tree)
% apllies all the changes in the blocks specified in input Tree argument
% then matches the blocks with the approprate animal

for kk=1:size(Tree,1)
    indx = find(cellfun(@(x) any(x == Tree(kk,1).UserData),{animalobj.Blocks.MultiAnimalsLinkedBlocks},'UniformOutput',true));
    animalobj.Blocks(indx).splitMultiAnimals(Tree); %#ok<FNDSB>
    for ii=1:size(Tree,2)
        bl = Tree(kk,ii).UserData;
        match = find( strcmp({animalobj.MultiAnimalsLinkedAnimals.Name},bl.Meta.AnimalID));
        blocks = animalobj.MultiAnimalsLinkedAnimals(match).Blocks;
        animalobj.MultiAnimalsLinkedAnimals(match).Blocks = [blocks, bl];
    end % ii
end % kk

for ii = 1:numel(animalobj.MultiAnimalsLinkedAnimals)
    animalobj.MultiAnimalsLinkedAnimals(ii).updatePaths();    
end

end

function deleteAnimalWhenEmpty(animalObj)
if  ( isvalid(animalObj)) && (numel(animalObj.Blocks)==1)
    delete(fullfile([animalObj.Paths.SaveLoc '_Animal.mat']));
    delete(animalObj);
end
end