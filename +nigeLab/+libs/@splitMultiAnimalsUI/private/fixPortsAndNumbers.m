function fixPortsAndNumbers(blockObj)
%FIXPORTSANDNUMBERS  Fix ports and numbers props after splitting Blocks
%
%  blockObj.fixPortsAndNumbers(); 
%
%  Fixes following properties of nigeLab.Block object after splitting a
%  recording with multiple animals run simultaneously:
%  --> .Mask

%% port_number
%  PN = [blockObj.Channels.port_number];
%  OldPN = unique(PN);
% NewPn = 1:numel(OldPN);
% PN = num2cell((PN'==OldPN)*NewPn');
% [bl.Channels.port_number]=deal(PN{:});
% blockObj.NumProbes = numel(OldPN);
if isempty(blockObj.Mask)
   blockObj.Mask=1:blockObj.NumChannels;
else
blockObj.Mask = blockObj.Mask - min(blockObj.Mask) + 1;
end
end