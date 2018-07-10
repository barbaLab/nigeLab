function      Blocks = listBlocks(animalObj)    
%% WIP Returns a nested table with the protocols associated with the rat and different infos
BlockIDs
Blocks=table();
IDs = {animalObj.Blocks.ID};
Date = {animalObj.Blocks.Date};
