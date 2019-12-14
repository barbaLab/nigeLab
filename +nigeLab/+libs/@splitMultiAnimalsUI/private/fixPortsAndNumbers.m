function fixPortsAndNumbers(bl)
%% port_number
 PN = [bl.Channels.port_number];
 OldPN = unique(PN);
% NewPn = 1:numel(OldPN);
% PN = num2cell((PN'==OldPN)*NewPn');
% [bl.Channels.port_number]=deal(PN{:});
bl.NumProbes = numel(OldPN);
bl.NumChannels = numel(bl.Channels);
if isempty(bl.Mask),bl.Mask=1:bl.NumChannels;else
bl.Mask = bl.Mask - min(bl.Mask) + 1;
end
end