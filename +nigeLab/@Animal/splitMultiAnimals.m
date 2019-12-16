function flag = splitMultiAnimals(animalObj,varargin)
% SPLITMULTIANIMALS  Split blocks with multiple animals recorded in the
%                    same session so that their "parent" animals are
%                    separated, while maintaining the session metadata
%                    associations shared by the two animals (for example,
%                    which may have been run together as a control).
%
%  flag = animalObj.splitMultiAnimals();
%  --> flag is true if the splitting terminated successfully
%
%  flag = animalObj.splitMultiAnimals(Tree);
%  --> Applies changes to the Tree and returns (see APPLYCHANGES)
%
%  flag = animalObj.splitMultiAnimals('noGui');
%  --> For running from Command Window interface (probably)

%% Check inputs
if numel(animalObj) > 1
   flag = true;
   for i = 1:numel(animalObj)
      flag = flag && animalObj(i).splitMultiAnimals(varargin{:});
   end
   return;
else
   flag = false;
end

switch nargin
   case 0
      error(['nigeLab:' mfilename ':tooFewInputs'],...
         'Not enough input arguments (0 provided, minimum 1 required)');
      
   case 1
      % Nothing here
      ...
         
   case 2
      % Depends on varargin{1}
      switch class(varargin{1})
         case 'uiw.widget.Tree'
            % If extra input is a Tree, then assign Tree and apply changes
            Tree = varargin{1};
            ApplyChanges(animalObj,Tree);
            return;
            
         case 'string'
            switch lower(varargin{1})
               case 'init'
                  % This is invoked from nigeLab.libs.splitMultiAnimalsUI
                  
               case {'nogui','cmd'}
                  % This is invoked from command window (probably)
                  
               otherwise
                  error(['nigeLab:' mfilename ':unexpectedCase'],...
                     'Unexpected splitMultiAnimals case: %s',varargin{1});
            end
         otherwise
            % Nothing here
            ...
      end
end

% If this is not a "multi-animals" animal then return
if ~(animalObj.MultiAnimals)
   warning('No multi animals recording detected');
   return;
end

animalDestructor_lh = addlistener(animalObj.Blocks,...
   'ObjectBeingDestroyed',...
   @(h,e)deleteAnimalWhenEmpty(animalObj));

% Figure out where the "new" split animals should be saved
TankPath = fileparts(animalObj.Paths.SaveLoc);

% animalObjPaths is a cell array of cell arrays of paths to one or more
% "parent" animals:
animalObjPaths = cell(numel(animalObj.Blocks),1);
for ii = 1:numel(animalObj.Blocks)
   animalObj.Blocks(ii).splitMultiAnimals('init');
   Metas = [animalObj.Blocks(ii).MultiAnimalsLinkedBlocks.Meta];
   animalObjPaths{ii} = cellfun(@(x) fullfile(TankPath,x),...
      {Metas.AnimalID},'UniformOutput',false);
end % ii

uAnimals = unique(animalObjPaths);
splittedAnimals = [];
for ii = 1:numel(uAnimals)
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

delete(animalDestructor_lh);

flag = true;
end %function

function ApplyChanges(animalObj,Tree)
% APPLYCHANGES  Apply all the changes in the blocks specified in input Tree
%                 argument (e.g. move all of Port A and B to Block 1, move
%                 all of Port C and D to Block 2, then split them). After
%                 this, it assigns the Blocks to the corresponding animal.
%
%  ApplyChanges(animalObj,Tree)

B = animalObj.Blocks;
for kk=1:size(Tree,1)
   indx = find(cellfun(@(x) any(x == Tree(kk,1).UserData),...
      {B.MultiAnimalsLinkedBlocks},'UniformOutput',true));
   B(indx).splitMultiAnimals(Tree); %#ok<FNDSB>
   for ii=1:size(Tree,2)
      bl = Tree(kk,ii).UserData;
      match = find( strcmp({animalObj.MultiAnimalsLinkedAnimals.Name},bl.Meta.AnimalID));
      blocks = animalObj.MultiAnimalsLinkedAnimals(match).Blocks;
      animalObj.MultiAnimalsLinkedAnimals(match).Blocks = [blocks, bl];
   end % ii
end % kk

for ii = 1:numel(animalObj.MultiAnimalsLinkedAnimals)
   animalObj.MultiAnimalsLinkedAnimals(ii).updatePaths();
end

end

function deleteAnimalWhenEmpty(animalObj)
% DELETEANIMALWHENEMPTY  Listener callback to delete animal when all Blocks
%                        are removed from it (during multi-animal split).
%
%  

if  ( isvalid(animalObj)) && (numel(animalObj.Blocks)==1)
   delete(fullfile([animalObj.Paths.SaveLoc '_Animal.mat']));
   delete(animalObj);
end
end