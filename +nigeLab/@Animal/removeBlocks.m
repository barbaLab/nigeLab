function removeBlocks(animalObj,ind)
%% Removes the block specified by index ind form animalObj.
% Removes block from aniamlObj and deletes associated files.
     if nargin<2
        warning('Not enough input args, no blocks merged.');
       return; 
     end
    for ii = ind
       if exist(animalObj.Blocks(ii).Paths.Block,'dir'),rmdir(animalObj.Blocks(ii).Paths.Block,'s');end
       if exist([animalObj.Blocks(ii).Paths.Block '_Block.mat'],'file')
           delete([animalObj.Blocks(ii).Paths.Block '_Block.mat']);end
        delete(animalObj.Blocks(ii));
        animalObj.Blocks(ii) = [];
    end


