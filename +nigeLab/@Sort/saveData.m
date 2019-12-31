function saveData(sortObj)
%% SAVEDATA    Save data on the disk
%
%  sortObj.saveData;
%
%  --------
%   INPUTS
%  --------
%  sortObj     :     nigeLab Sort class object
%
%  --------
%   OUTPUT
%  --------
%  Writes the sorting for all channels to the disk.

%%
fprintf(1,'Saving...%03g%%\n',0);
iTotal = numel(sortObj.Blocks) * numel(sortObj.Channels.Mask);
iCount = 0;
for iBlock = 1:numel(sortObj.Blocks)
   blockObj = sortObj.Blocks(iBlock);
   for iCh = sortObj.Channels.Mask
      idx = sortObj.spk.block{iCh} == iBlock;
      blockObj.Channels(iCh).Sorted.unlockData;
      blockObj.Channels(iCh).Sorted.value = sortObj.spk.class{iCh}(idx);
      iCount = iCount + 1;
      fprintf(1,'\b\b\b\b\b%03g%%\n',round((iCount/iTotal)*100));      
   end
   save(blockObj);
end

end