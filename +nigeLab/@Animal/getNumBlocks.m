function N = getNumBlocks(animalObj)
% GETNUMBLOCKS   Just makes it easier to count all blocks (common to TANK)
%
%  N = animalObj.GETNUMBLOCKS;

%%
if numel(animalObj) > 1
   N = nan(size(animalObj));
   for i = 1:numel(animalObj)
      N(i) = getNumBlocks(animalObj(i));
   end
   return;
end
N = numel(animalObj.Children);


end