function channelName = parseChannelName(channelID)
%% PARSECHANNELID    Get unique channel/probe combination for identifier
%
%  channelName = PARSECHANNELNAME(channelID);
%
%  --------
%   INPUTS
%  --------
%  channelID   :     nChannels x 2 matrix, where nChannels is the size of
%                       the Channels struct property of blockObj. The first
%                       column is the Channels.probe and second column is
%                       Channels.native_order.
%
%  --------
%   OUTPUT
%  --------
%  channelName :     Cell array of chars that give the written name of each
%                       channel described in channelID.
%
% By: Max Murphy   v1.0 2019/01/08   Original version (R2017a)

%%
N = size(channelID,1);
channelName = cell(N,1);
for ii = 1:N
   channelName{ii} = sprintf('P%g Ch %03g',...
                             channelID(ii,1),channelID(ii,2));
end


end