function [trgtStuff,trgtMask]=getUpdatedEvnts(trgtBlck,Stff,Tree)

 index = cat(1,Stff.UserData);
        
        % init target data with the stuff to keep
        trgtStuff = trgtBlck.Events(index(index(:,1) == ii,2));
        if isprop(trgtBlck,'Mask')&&strcmp(field,'Channels' )
            trgtMask = trgtBlck.Mask(index(index(:,1)==ii,2));
        end
        
        % make sure not to double assign
        allSrcBlck = unique(index(:,1));
        allSrcBlck(allSrcBlck==ii) = [];
        
        % cycle through all the sources and assign all the needed data
        for kk = allSrcBlck
            srcBlck = Tree(kk).UserData;
            srcStuffs = srcBlck.Events(index(index(:,1)==kk,2));
            trgtStuff = [trgtStuff;srcStuffs];
            if isprop(srcBlck,'Mask')&&strcmp(field,'Channels' )
                srcMask = srcBlck.Mask(index(index(:,1)==kk,2));
                trgtMask = [trgtMask srcMask];
            end
        end



end
