function addChildBlock(animalObj,blockPath,idx)
% ADDBLOCK  Add Block "Children" to Blocks property
%
%  animalObj.addChildBlock('blockPath');
%  --> Adds block located at 'BlockPath'
%
%  animalObj.addChildBlock(blockObj);
%  --> Adds the block directly to 'Blocks'
%
%  animalObj.addChildBlock(blockObj,idx);
%  --> Adds the block to the array element indexed by idx

if nargin < 2
   blockPath = [];
end

if ~isscalar(animalObj)
   error(['nigeLab:' mfilename ':badInputType2'],...
      'animalObj must be scalar.');
end

switch class(blockPath)
   case 'char'
      % Create the Children Block objects
      blockObj = nigeLab.Block(blockPath,animalObj.Paths.SaveLoc);
      
   case 'nigeLab.Block'
      % Load them directly as Children
      if numel(blockPath) > 1
         blockObj = reshape(blockPath,1,numel(blockPath));
      else
         blockObj = blockPath;
      end
      
   case 'double'
      if isempty(blockPath)
         blockObj = nigeLab.Block([],animalObj.Paths.SaveLoc);
      end
      
   otherwise
      error(['nigeLab:' mfilename ':badInputType1'],...
         'Bad blockPath input type: %s',class(blockPath));
end

if nargin < 3
   animalObj.Blocks = [animalObj.Blocks blockObj];
else
   if numel(size(idx)) == 1
      S = substruct('()',{1,idx});
   else
      S = substruct('()',{idx});
   end
   animalObj.Blocks = builtin('subsasgn',animalObj.Blocks,...
      S,blockObj);
end

% Initialize mask to true if we are adding NEW blocks. If they have already
% been added and this is invoked by loadobj, the mask will be bigger than
% animalObj.Blocks
maskDiff = sum(~isempty(animalObj.Blocks)) - numel(animalObj.BlockMask);
if maskDiff > 0
   animalObj.BlockMask = [animalObj.BlockMask, true(1,maskDiff)];
end
for i = 1:numel(blockObj)
   blockObj(i).Listener = [blockObj(i).Listener,...
      addlistener(blockObj(i),'ObjectBeingDestroyed',...
         @(~,~)animalObj.AssignNULL), ...
      addlistener(animalObj,'BlockMask','PostSet',...
         @(~,propEvt)blockObj.updateMaskFlag(propEvt.AffectedObject))];
   animalObj.BlockListener = [animalObj.BlockListener, ...
      addlistener(blockObj(i),'StatusChanged',...
         @(~,evt)notify(animalObj,'StatusChanged',evt)), ...
      addlistener(blockObj(i),'IsMasked','PostSet',...
         @(~,propEvt)animalObj.updateBlockMask(propEvt.AffectedObject))];
end
if maskDiff >= 0
   animalObj.parseProbes();
end
end