function removeAnimal(tankObj,ind)
%% REMOVEANIMAL Removes the animal specified by index ind form tankObj.
% Removes snimsl from tankObj and deletes associated files.

     if nargin<2
        warning('Not enough input args, no blocks removed.');
       return; 
     end
     ind = sort(ind,'descend');
    for ii = ind
       if exist(tankObj.Animals(ii).Paths.SaveLoc.dir,'dir')
          rmdir(tankObj.Animals(ii).Paths.SaveLoc.dir,'s');
       end
       if exist([tankObj.Animals(ii).Paths.SaveLoc.dir '_Animal.mat'],'file')
           delete([tankObj.Animals(ii).Paths.SaveLoc.dir '_Animal.mat']);
       end
        delete(tankObj.Animals(ii));
    end


