function flag = parseBlocks(sortObj,blockObj)
%% PARSEBLOCKS  Add blocks to Sort object
%
%  flag = PARSEBLOCKS(sortObj,blockObj);
%
%  --------
%   INPUTS
%  --------
%   sortObj    :     nigeLab.Sort class object that is under construction.
%
%   blockObj   :     nigeLab.Block class object
%
%
% By: Max Murphy  v1.0    2019/01/08  Original version (R2017a)

%% INITIALIZE CHANNELS PROPERTY
flag = false;

sortObj.Channels.ID = ChannelID(blockObj(1));
sortObj.Channels.Mask = blockObj(1).Mask;
sortObj.Channels.Name = parseChannelName(sortObj);
sortObj.Channels.N = size(sortObj.Channels.ID,1);
sortObj.Channels.Idx = matchChannelID(blockObj,sortObj.Channels.ID);
sortObj.Channels.Sorted = false(sortObj.Channels.N,1);

%% FIND CORRESPONDING CHANNELS FOR REST OF BLOCK ELEMENTS
for ii = 1:numel(blockObj)
   if ~blockObj(ii).updateParams('Sort')
      warning('Parameters unset for %s. Skipping...',blockObj(ii).Name);
      continue;
   end
   
   % Check the format of files
   fprintf(1,'\nChecking SORTED for %s...000%%\n',blockObj(ii).Name);
   curCh = 0; nCh = numel(blockObj(ii).Mask);
   for iCh = blockObj(ii).Mask
      blockObj(ii).checkSpikeFile(blockObj(ii).Mask);
      curCh = curCh+1;
      pct = 100 * (curCh / nCh);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct));
   end
   
end
sortObj.Blocks = blockObj;
flag = true;

end