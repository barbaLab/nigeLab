function channelID = parseChannelID(blockObj)
% PARSECHANNELID    Get unique channel/probe combination for identifier
%
%  channelID = PARSECHANNELID(blockObj);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object
%
%  --------
%   OUTPUT
%  --------
%  channelID   :     nChannels x 2 matrix, where nChannels is the size of
%                       the Channels struct property of blockObj. The first
%                       column is the Channels.probe and second column is
%                       Channels.native_order.

%%
channelID = nan(blockObj.NumChannels,2);
for ii = 1:blockObj.NumChannels
   % First column is probe number
   if isfield(blockObj.Channels(ii),'probe')
      channelID(ii,1) = blockObj.Channels(ii).probe;
   else % If probe number not yet parsed
      if ~blockObj.parseProbeNumbers  % Parse and check that parsing worked
         error('Failed to parse probe numbers.');
      else
         channelID(ii,1) = blockObj.Channels(ii).probe;
      end      
   end
   
   % Second column is channel number
   if isfield(blockObj.Channels(ii),'RHD_Channel')
      channelID(ii,2) = blockObj.Channels(ii).RHD_Channel;
   else
      channelID(ii,2) = blockObj.Channels(ii).native_order;
   end
end
blockObj.ChannelID = channelID;

end