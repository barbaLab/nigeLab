function idx = matchProbeChannel(blockObj,channel,probe)
%% MATCHPROBECHANNEL  Return index for a given probe/channel combo
%
%  idx = blockObj.MATCHPROBECHANNEL(channel,probe);
%
%  Channel : number or array corresponding to
%              blockObj.Channels(idx).native_order
%
%  probe   : probe index (e.g. 1, 2, 3) corresponding to
%              blockObj.Channels(idx).probe

%%
if numel(blockObj) > 1
   error('matchProbeChannel is only configured for SCALAR block input');
end

if ischar(channel)
   error('channel must be a number');
end

if ischar(probe)
   error('probe must be a number');
end

if numel(channel) > 1
   if isscalar(probe)
      probe = repmat(probe,numel(channel),1);
   end
   idx = nan(size(channel));
   for i = 1:numel(channel)
      idx(i) = blockObj.matchProbeChannel(channel(i),probe(i));
   end
   return;
end

%%
bCh = [blockObj.Channels.native_order];
bP = [blockObj.Channels.probe];

idx = find((bCh == channel) & (bP == probe),1,'first');

end