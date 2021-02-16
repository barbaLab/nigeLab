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
            
         case 'char'
            switch lower(varargin{1})
               case 'init'
                  % This is invoked from nigeLab.libs.splitMultiAnimalsUI
                  
                  % If this is not a "multi-animals" animal then return
                  if ~(animalObj.MultiAnimals)
                      warning('No multi animals recording detected');
                      return;
                  end
                  
                  createChildrenAnimals(animalObj)
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
flag = true;
end %function

function createChildrenAnimals(animalObj)
% CREATECHILDRENANIMALS creates the two children animals from the parent
% animals. It also calls splitmultianimals(init) on all the blocks of the
% current animal and assigns the splitted block to the correct splitted
% animal


% split meta that contains MultiAnimalsChar
ff = fieldnames(animalObj.Meta)';
ff = setdiff(ff,{'Header','FileExt','OrigName','OrigPath'});
types =  structfun(@(x) class(x),animalObj.Meta,'UniformOutput',false);
for ii = ff
   if ~strcmp(types.(ii{:}),'char'),continue;end
   if contains(animalObj.Meta.(ii{:}),animalObj.Pars.Block.MultiAnimalsChar)
      str = strsplit(animalObj.Meta.(ii{:}),animalObj.Pars.Block.MultiAnimalsChar);
      if exist('SplittedMeta','var')
         [SplittedMeta.(ii{:})]=deal(str{:});
      else
         SplittedMeta = cell2struct(str,ii{:});
      end
   end
end


% Figure out where the "new" split animals should be saved

arrayfun(@(x) x.splitMultiAnimals('init'), animalObj.Children);
AllSplittedBlocks = [animalObj.Children.MultiAnimalsLinkedBlocks];
animalNames = arrayfun(@(x) x.AnimalID, [AllSplittedBlocks.Meta],'UniformOutput',false);

splittedAnimals = [];
% Main cycle, create all MultiAnimalsLinkedObjects
Sieblings = animalObj.Parent.Children;
for ii = 1:numel(SplittedMeta)
    ff=fields(SplittedMeta);
    if ismember(ff,'AnimalID') && any(strcmp({Sieblings.Name},SplittedMeta(ii).AnimalID))
        an = copy(Sieblings(strcmp({Sieblings.Name},SplittedMeta(ii).AnimalID)));
        an.Children = [];
        [AllSplittedBlocks(strcmp(animalNames,an.Name)).Parent] = deal(an);
    else
        an = copy(animalObj);
        
        % assign correct meta
        for jj=1:numel(ff)
            an.Meta.(ff{jj}) = SplittedMeta(ii).(ff{jj});
        end %jj
        
        % create name from meta
        str = [];
        nameCon = an.Pars.Animal.NamingConvention;
        for kk = 1:numel(nameCon)
            if isfield(an.Meta,nameCon{kk})
                str = [str, ...
                    an.Meta.(nameCon{kk}),...
                    an.Pars.Block.Delimiter]; %#ok<AGROW>
            end
        end %kk
        an.Name =  str(1:(end-1));
        an.Children = [];
        an.MultiAnimals = 2;
        an.MultiAnimalsLinkedAnimals(:) = [];
        an.Output = fullfile(an.Paths.SaveLoc,an.Name);
        [AllSplittedBlocks(strcmp(animalNames,an.Name)).Parent] = deal(an);
        
        an.Key = an.InitKey();
        an.PropListener = an.PropListener([]);
        an.ParentListener = an.ParentListener([]);
    end
    splittedAnimals = [splittedAnimals, an];
end
animalObj.MultiAnimalsLinkedAnimals = splittedAnimals;
% animalObj.Parent.addChild(splittedAnimals);

end



function ApplyChanges(animalObj,Tree)
% APPLYCHANGES  Apply all the changes in the blocks specified in input Tree
%                 argument (e.g. move all of Port A and B to Block 1, move
%                 all of Port C and D to Block 2, then split them). After
%                 this, it assigns the Blocks to the corresponding animal.
%
%  ApplyChanges(animalObj,Tree)
% 
% animalDestructor_lh = addlistener(animalObj,'Children',...
%     'PostSet',...
%     @(h,e)deleteAnimalWhenEmpty(animalObj));

B = animalObj.Children;
BToRemove = nigeLab.Block.Empty([1,size(Tree,1)]);
for kk=1:size(Tree,1)
    blocksInCells = arrayfun(@(x) x.MultiAnimalsLinkedBlocks,B,'UniformOutput',false);
    key = Tree(kk,1).UserData.Key.Public;
   indx = cellfun(@(x) ~isempty(findByKey(x,key)),...
      blocksInCells);
   B(indx).splitMultiAnimals(Tree);
   BToRemove(kk) = B(indx);
%    for ii=1:size(Tree,2)
%       bl = Tree(kk,ii).UserData;
%       bl.splitMultiAnimals(Tree);
%       match = find( strcmp({animalObj.MultiAnimalsLinkedAnimals.Name},bl.Meta.AnimalID));
%       blocks = animalObj.MultiAnimalsLinkedAnimals(match).Children;
%       animalObj.MultiAnimalsLinkedAnimals(match).Children = [blocks, bl];
%    end % ii
end % kk

for ii = 1:numel(animalObj.MultiAnimalsLinkedAnimals)
   animalObj.MultiAnimalsLinkedAnimals(ii).updatePaths();
end

end

