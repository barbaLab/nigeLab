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

sortObj.Channels.ID = parseChannelID(blockObj(1));
sortObj.Channels.Name = parseChannelName(sortObj.Channels.ID);
sortObj.Channels.Idx = cell(numel(blockObj),1);
sortObj.Channels.Idx{1} = 1:size(sortObj.Channels.ID,1);
sortObj.Channels.N = numel(blockObj);

%% FIND CORRESPONDING CHANNELS FOR REST OF BLOCK ELEMENTS
for ii = 2:sortObj.Channels.N
   channelID = parseChannelID(blockObj(ii));   
   idx = [];
   for iCh = 1:size(channelID,1)
      tmp = find(ismember(sortObj.Channels.ID,channelID(iCh,:),'rows'),...
                 1,'first');
      idx = [idx, tmp]; %#ok<AGROW>
   end
   sortObj.Channels.Idx{ii} = idx;
end
flag = true;

end