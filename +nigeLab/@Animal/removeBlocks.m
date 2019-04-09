function removeBlocks(animalObj,ind)
%% Removes the block specified by index ind form animalObj.
% Removes block from aniamlObj and deletes associated files.
     if nargin<2
        warning('Not enough input args, no blocks removed.');
       return; 
     end
     ind = sort(ind,'descend');
    for ii = ind
       if exist(animalObj.Blocks(ii).Paths.SaveLoc.dir,'dir')
          rmdir(animalObj.Blocks(ii).Paths.SaveLoc.dir,'s');
       end
       if exist([animalObj.Blocks(ii).Paths.SaveLoc.dir '_Block.mat'],'file')
           delete([animalObj.Blocks(ii).Paths.SaveLoc.dir '_Block.mat']);end
        delete(animalObj.Blocks(ii));
        animalObj.Blocks(ii) = [];
    end


