function N = getNumBlocks(tankObj)
%% GETNUMBLOCKS   Get total number of blocks in the TANK object
%
%  N = tankObj.getNumBlocks;
%
% By: Max Murphy v1.0   2019-07-09  Original version (R2017a)

%%
N = 0;
for ii = 1:numel(tankObj.Animals)
   N = N + tankObj.Animals(ii).getNumBlocks;
end

end