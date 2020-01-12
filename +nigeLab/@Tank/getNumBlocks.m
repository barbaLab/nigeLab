function N = getNumBlocks(tankObj)
%% GETNUMBLOCKS   Get total number of blocks in the TANK object
%
%  N = tankObj.getNumBlocks;

%%
N = 0;
for ii = 1:numel(tankObj.Children)
   N = N + tankObj.Children(ii).getNumBlocks;
end

end