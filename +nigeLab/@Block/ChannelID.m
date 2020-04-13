function C = ChannelID(blockObj)
%CHANNELID    Get unique channel/probe combination for identifier
%
%  C = blockObj.ChannelID;
%
%     Checks to make sure that probes and fixed channel numbers have been
%     correctly parsed (blockObj.parseProbeNumbers) if any element of
%     [blockObj.Channels.probe] is empty.
%
%  C = ChannelID(blockObjArray); 
%
%     Returns the ChannelID matrix with the most rows (unique channels)
%     from the array blockObjArray of nigeLab.Block objects.
%
%  --------
%   OUTPUT
%  --------
%     C   :     blockObj.NumChannels x 2 matrix, with columns as:
%           --> [blockObj.Channels.probe; blockObj.Channels.chNum]

if numel(blockObj) > 1
   C = [];
   for i = 1:numel(blockObj)
      Ctmp = blockObj(i).ChannelID;
      if size(Ctmp,1) > size(C,1)
         C = Ctmp;
      end
   end
   return;
end

% Get Probe index of each recording channel
probeNum = [blockObj.Channels.probe].';
if numel(probeNum) < blockObj.NumChannels
   if ~blockObj.parseProbeNumbers  % Parse and check that parsing worked
      error(['nigeLab:' mfilename ':probeNumberParseError'],...
         'Failed to parse probe numbers.');
   else
      probeNum = [blockObj.Channels.probe].';
   end
end

% Get index of each channel within a probe
channelNum = [blockObj.Channels.chNum].'; % Parsed with .probe

% Combine into output matrix
C = [probeNum, channelNum];

end