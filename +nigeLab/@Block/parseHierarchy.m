function header = parseHierarchy(blockObj)
% PARSEHIERARCHY  Parse header structure from pre-extracted file hierarchy
%
%  header = blockObj.parseHierarchy();
%
%  Private method of nigeLab.Block that is used when the BLOCK has
%  previously been initialized, but the block was either not saved, or it
%  was re-initialized and pointed at the pre-extracted block structure.

% Handle array input
if numel(blockObj) > 1
   header = cell(size(blockObj));
   for i = 1:numel(blockObj)
      header{i} = blockObj(i).parseHierarchy();
   end
   return;
end

iChannels = find(blockObj.getFieldTypeIndex('Channels'),1,'first');
if isempty(iChannels)
   error(['nigeLab:' mfilename ':noChannelsFieldType'],...
      'No Channels FieldType Fields; unable to parse hierarchy.');
else
   field = blockObj.Fields{iChannels};
end

F = dir(strrep(blockObj.Paths.(field).file,'%s','*'));
header = struct;
header.num_raw_channels = numel(F);
c = nigeLab.utils.initChannelStruct('Channels',blockObj.NumChannels);
portNames = blockObj.Pars.Experiment.StandardPortNames;
for iCh = 1:blockObj.NumChannels
   name = F(iCh).name;
   iNum = regexp(name,'\d');
   p = str2double(name(iNum(1)));
   abcd = portNames{p};
   ch = name(iNum(2:end));
   c(iCh).name = sprintf('%s-%s',abcd,ch);
   c(iCh).native_channel_name = c(iCh).name;
   c(iCh).custom_channel_name = c(iCh).name;
   c(iCh).custom_order =  iCh;
   c(iCh).native_order = iCh;
   c(iCh).board_stream = p;
   c(iCh).chip_channel = str2double(ch);
   c(iCh).port_name = sprintf('Port %s',abcd);
   c(iCh).port_prefix = abcd;
   c(iCh).port_number = p;
   c(iCh).probe = p;
   c(iCh).electrode_impedance_magnitude = nan;
   c(iCh).electrode_impedance_phase = nan;
end
header.acqsys = nigeLab.Pars.Experiment.DefaultAcquisitionSystem;
header.num_probes = numel(unique([c.probe]));

header.sample_rate = nan;
header.samples = nan;
header.raw_chanels = c;

end