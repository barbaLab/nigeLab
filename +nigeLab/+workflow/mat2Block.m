function flag = mat2Block(blockObj)
%% MAT2BLOCK  Default function for nigeLab.Block.MatFileWorkflow.ExtractFcn
%
%  flag = MAT2BLOCK(blockObj);
%
% Performs 'doRawExtraction' method for data when rectype is 'mat'

%%
flag = false;
paths.SaveLoc.dir = fullfile(fileparts(fileparts(blockObj.RecFile)));
paths = blockObj.getFolderTree(paths);
for iCh = 1:blockObj.NumChannels
   chName = blockObj.Channels(iCh).chStr;
   pName = num2str(blockObj.Channels(iCh).probe);
   diskFile = (sprintf(strrep(paths.Raw.file,'\','/'),pName,chName));
   blockObj.Channels(iCh).Raw = nigeLab.libs.DiskData('Hybrid',diskFile,'name','data');
end
blockObj.linkToData;
flag = true;

end