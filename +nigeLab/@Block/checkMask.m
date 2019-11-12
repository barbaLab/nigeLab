function checkMask(blockObj)
%% CHECKMASK   Check to ensure that the channel mask matches extracted data
%
%  blockObj.CHECKMASK;
%
% By: Max Murphy  v1.0  2019-07-11  Original version (R2017a)

%%
channelMask = blockObj.Mask;
channelFlag = false(size(channelMask));

ii = 0;
for ch = channelMask
   ii = ii + 1;
   channelFlag(ii) = isempty(blockObj.Channels(ch).Raw);
end
channelMask(channelFlag) = [];
blockObj.setChannelMask(channelMask);

end