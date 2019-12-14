function flag = mat2BlockRC(blockObj)
%% MAT2BLOCKRC  nigeLab.Block.MatFileWorkflow.ExtractFcn for 'RC' project
%
%  flag = MAT2BLOCKRC(blockObj);
%
% Performs 'doRawExtraction' method for data when rectype is 'mat'

%%
flag = false;
paths.SaveLoc.dir = fullfile(blockObj.AnimalLoc,blockObj.Name); % Only difference from DEFAULT
paths = blockObj.getFolderTree(paths);
for iCh = 1:blockObj.NumChannels
   chName = blockObj.Channels(iCh).chStr;
   pName = num2str(blockObj.Channels(iCh).probe);
   diskFile = nigeLab.utils.getUNCPath(...
      (sprintf(strrep(paths.Raw.file,'\','/'),pName,chName)));
   blockObj.Channels(iCh).Raw = nigeLab.libs.DiskData(...
      'Hybrid',diskFile,'name','data');
end
blockObj.linkToData;
flag = true;

end