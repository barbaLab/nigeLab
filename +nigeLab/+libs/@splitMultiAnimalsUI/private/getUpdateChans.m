function [trgtStuff,trgtMask]=getUpdateChans(trgtBlck,Stff,Tree,ii)

        index = cat(1,Stff.UserData);
        
        % init target data with the stuff to keep
        trgtStuff = trgtBlck.Channels(index(index(:,1) == ii,2));
        if isprop(trgtBlck,'Mask')
            trgtMask = trgtBlck.Mask(index(index(:,1)==ii,2));
        end
        
        % make sure not to double assign
        allSrcBlck = unique(index(:,1));
        allSrcBlck(allSrcBlck==ii) = [];
        
        % cycle through all the sources and assign all the needed data
        for kk = allSrcBlck
            srcBlck = Tree(kk).UserData;
            srcStuffs = srcBlck.Channels(index(index(:,1)==kk,2));
            trgtStuff = [trgtStuff;srcStuffs];
            if isprop(srcBlck,'Mask')
                srcMask = srcBlck.Mask(index(index(:,1)==kk,2));
                trgtMask = [trgtMask srcMask];
            end
        end


end
