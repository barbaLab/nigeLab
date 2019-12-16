function [trgtStuff] = getUpdatedStreams(trgtBlck,Stff,Tree,ii)

trgtStuff = struct();
StreamsTypes = {Stff.Name};
for jj=1:numel(StreamsTypes)
    tmp = [Stff(jj).Children.Children];
    if isempty([Stff(jj).Children.Children]),continue;end
    index = cat(1,tmp.UserData);
    % init target data with the stuff to keep
    trgtStuff.(StreamsTypes{jj}) = trgtBlck.Streams.(StreamsTypes{jj})(index(index(:,1) == ii,2));
    
    % make sure not to double assign
    allSrcBlck = unique(index(:,1));
    allSrcBlck(allSrcBlck==ii) = [];
    
    % cycle through all the sources and assign all the needed data
    for kk = allSrcBlck
        srcBlck = Tree(kk).UserData;
        srcStuffs = srcBlck.Streams.(StreamsTypes{jj})(index(index(:,1)==kk,2));
        trgtStuff.(StreamsTypes{jj}) = [trgtStuff.(StreamsTypes{jj});srcStuffs];
    end
end


end