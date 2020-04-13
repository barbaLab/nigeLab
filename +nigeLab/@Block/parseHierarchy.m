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

header = struct;
portNames = blockObj.Pars.Experiment.StandardPortNames;

for iField = 1:numel(blockObj.Fields)
   field = blockObj.Fields{iField};
   fieldType = blockObj.getFieldType(field);
   fileType = blockObj.getFileType(field);
   if ismember(lower(fieldType),{'videos','meta'})
      continue; % Skip Videos and Meta fieldtypes here
   end
   
   switch fieldType
      case 'Channels'
         F = dir(strrep(blockObj.Paths.(field).file,'%s','*'));
         nSamplesFieldName = sprintf('num_%s_samples',lower(field));
         nChannelsFieldName = sprintf('num_%s_channels',lower(field));
         if isempty(F)
            header.(nSamplesFieldName) = 0;
            header.(nChannelsFieldName) = 0;
            c = nigeLab.utils.initChannelStruct('Channels',0);
         else
            if ismember(fileType,'Hybrid')
               m = matfile(fullfile(F(1).folder,F(1).name));
               header.(nSamplesFieldName) = size(m.data,2);
            end
            header.(nChannelsFieldName) = numel(F);
            c = parseChannelsHierarchy(F,portNames);
         end   
      case 'Streams'
         
         c = parseStreamsHierarchy(F);
             
      case 'Events'         
         c = parseEventsHierarchy(F);
         
   end % case fieldType
   
   if strcmpi(field,'raw')
      header.acqsys = blockObj.Pars.Experiment.DefaultAcquisitionSystem;
      header.num_probes = numel(unique([c.probe]));
   end
   
   channelFieldName = sprintf('%s_channels',lower(field));
   header.(channelFieldName) = c;
end % iField

header.sample_rate = nan;
header.samples = nan;


end % function parseHierarchy

function c = parseChannelsHierarchy(F,portNames)
% PARSECHANNELSHIERARCHY  Parse hierarchy for CHANNELS field type

c = nigeLab.utils.initChannelStruct('Channels',numel(F));
for iCh = 1:numel(F)
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

end % function parseChannelsHierarchy

function c = parseStreamsHierarchy(F)
% PARSESTREAMSHIERARCHY  Parse hierarchy for STREAMS field type

c = nigeLab.utils.initChannelStruct('Streams',0);

for iCh = 1:numel(F)
   [~,fname,~] = fileparts(F(iCh).name);
   strInfo = strsplit(fname,'_');
   if ~ismember(strInfo{end},'Stream')
      continue;
   else
      cNew = nigeLab.utils.initChannelStruct('Streams',1);
   end
   cNew.name = strInfo{end-1};
   cNew.native_channel_name = cNew.name;
   cNew.custom_channel_name = cNew.name;
   cNew.port_name = strInfo{end-2};
   switch upper(cNew.port_name)
      case {'DIGIN','DIGITALIN'}
         cNew.port_prefix = 'DIN';
      case {'DIGOUT','DIGITALOUT'}
         cNew.port_prefix = 'DOUT';
      case {'ANAIN','ANALOGIN','ADC'}
         cNew.port_prefix = 'ADC';
      case {'ANAOUT','ANALOGOUT','DAC'}
         cNew.port_prefix = 'DAC';
      otherwise
         cNew.port_prefix = strInfo{end-2};
   end % switch upper(cNew(iCh).port_name)
   m = matfile(fullfile(F(iF).folder,F(iF).name));
   if isfield(m,'data')
      if isvector(m.data)
         cNew.signal = nigeLab.utils.signal(strInfo{end-2},numel(m.data));
      else
         cNew.signal = nigeLab.utils.signal(strInfo{end-2});
      end
   else
      cNew.signal = nigeLab.utils.signal(strInfo{end-2});
   end
   c = [c, cNew]; %#ok<*AGROW>
end

end % function parseStreamsHierarchy

function c = parseEventsHierarchy(F)
% PARSEEVENTSHIERARCHY  Parse hierarchy for EVENTS field type

c = nigeLab.utils.initChannelStruct('Events',0);

for iCh = 1:numel(F)
   [~,fname,~] = fileparts(F(iCh).name);
   strInfo = strsplit(fname,'_');
   if ~ismember(strInfo{end},'Events')
      continue;
   else
      cNew = nigeLab.utils.initChannelStruct('Events',1);
   end
   cNew.name = strInfo{end-2};
   c = [c, cNew];
end

end % function parseEventsHierarchy