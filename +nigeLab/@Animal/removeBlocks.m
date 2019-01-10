function removeBlocks(animalObj,ind)
     if nargin<2
        warning('Not enough input args, no blocks merged.');
       return; 
     end
    for ii = ind
        rmdir(animalObj.Blocks(ii).SaveLoc,'s');
        delete([animalObj.Blocks(ii).SaveLoc '.mat']);
        delete(animalObj.Blocks(ii));
        animalObj.Blocks(ii) = [];
    end


