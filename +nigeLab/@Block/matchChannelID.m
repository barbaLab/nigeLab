function masterIdx = matchChannelID(blockObj,masterID)
%% MATCHCHANNELID    Use master identifier to match channel indices by ID
%
%  masterIdx = MATCHCHANNELID(blockObj,masterID);
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object, or array of blockObj.
%
%  masterID    :     Output from nigeLab.Block.ChannelID; master ID
%                       that is used to match the other channels.
%
%  --------
%   OUTPUT
%  --------
%  masterIdx   :     nChannels x nblockObj vector of int where each element
%                       corresponds to the channel element that matches a
%                       row of masterID. For example, if masterID was given
%                       as a matrix where first column is probeID and
%                       second column is channelID as:
%
%                       [1, 1; ...
%                        1, 1; ...
%                        1, 2; ...
%                        2, 1];
%
%                       And the parsed channelID of the blockObj is given
%                       as:
%
%                       [1, 1; ...
%                        2, 1];
%
%                       Then masterIdx will be returned as:
%
%                       [1; ...
%                        1; ...
%                        NaN; ...
%                        2];

%% INITIALIZE
N = size(masterID,1);
M = numel(blockObj);
masterIdx = nan(N,M);
%% ITERATE AND ASSIGN MASTER INDICES
for iBk = 1:M % For each block   
   C = blockObj(iBk).ChannelID; % parse the channel IDs
   for iCh = 1:N % For each channel
      % Match the channel ID to the correct row (if it exists)
      tmp = find(ismember(C,masterID(iCh,:),'rows'),1,'first');
      if ~isempty(tmp)
         masterIdx(iCh,iBk) = tmp;
      end
   end
end

end