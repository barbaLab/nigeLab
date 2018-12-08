function [header] = ReadTDTHeader(varargin)
%% Reads TDT header file. For now uses TDT own functions.
% TODO reimplement everything since TDT code is... well TDT code.
if nargin >0
   VERBOSE = false;
else
   VERBOSE = true;
end

for iV = 1:2:length(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if exist('FID','var')
   
   [NAME,~,~,~] = fopen(FID); %#ok<NODEF>
   if isempty(NAME)
      error('Must provide a valid file pointer.');
   end
elseif exist('NAME', 'var')
   
   % If a pre-specified path exists, must be a valid path.
   if exist(NAME,'file')==0 %#ok<NODEF>
      error('Must provide a valid RHD2000 Data File and Path.');
   else
      FID = fopen(NAME, 'r');
   end
else    % Must select a directory and a file
   
   
   [path] = ...
      uigetdir('Select a TDT block folder', ...
      'MultiSelect', 'off');
   
   if file == 0 % Must select a file
      error('Must select a TDT block folder.');
   end
   
   NAME = path;
   FID = fopen(NAME, 'r');
   
   
end

s = dir(NAME);
filesize = sum([s.bytes]);

heads = TDTbin2mat(NAME, 'HEADERS', 1,'NODATA',1);
block_fields = fieldnames(heads);

fn = fieldnames(heads.stores);
wav_data = fn(contains(fn,'Wav'));

data_present = any(contains(block_fields, 'stores')) ;
sample_rate =  heads.stores.(wav_data{1}).fs;

s1 = datenum([1970, 1, 1, 0, 0, heads.startTime]);
s2 = datenum([1970, 1, 1, 0, 0, heads.stopTime]);
info.date = datestr(s1,'yyyy-mmm-dd');
if ~isnan(heads.startTime)
   info.Year = year(s1);
   info.Month = month(s1);
   info.Day = day(s1);
   info.RecDate = datestr(s1,'yymmdd');
   info.RecTime = datestr(s1,'hhmmss');
   
   info.utcStartTime = datestr(s1,'HH:MM:SS');
else
    info.utcStartTime = nan;
end
if ~isnan(heads.stopTime)
    info.utcStopTime = datestr(s2,'HH:MM:SS');
else
    info.utcStopTime = nan;
end

if heads.stopTime > 0
    info.duration = datestr(s2-s1,'HH:MM:SS');
end



num_probes = length(wav_data);
probes = char((1:num_probes) -1 + double('A'));
amplifier_channels = channel_struct;
for pb = 1:num_probes
   Chans = unique(heads.stores.(wav_data{pb}).chan);
   for iCh = 1:numel(Chans)
   ind = numel(amplifier_channels)+1;
   amplifier_channels(ind).custom_channel_name = sprintf('%c%.3d',probes(pb),iCh);
   amplifier_channels(ind).native_channel_name = sprintf('%c-%.3d',probes(pb),Chans(iCh));
   amplifier_channels(ind).native_order = iCh;
   amplifier_channels(ind).custom_order = iCh;
   amplifier_channels(ind).board_stream = nan;
   amplifier_channels(ind).chip_channel = nan;
   amplifier_channels(ind).port_name = ['Port ' probes(pb)];
   amplifier_channels(ind).port_prefix = probes(pb);
   amplifier_channels(ind).port_number = pb;
   amplifier_channels(ind).electrode_impedance_magnitude = nan;
   amplifier_channels(ind).electrode_impedance_phase = nan;
   end
end

DFORM_FLOAT		 = 0;
DFORM_LONG		 = 1;
DFORM_SHORT		 = 2;
DFORM_BYTE		 = 3;
DFORM_DOUBLE	 = 4;
DFORM_QWORD		 = 5;
DFORM_TYPE_COUNT = 6;
sz = 4;
switch heads.stores.((wav_data{1})).dform
   case DFORM_FLOAT
      fmt = 'single';
   case DFORM_LONG
      fmt = 'int32';
   case DFORM_SHORT
      fmt = 'int16';
      sz = 2;
   case DFORM_BYTE
      fmt = 'int8';
      sz = 1;
   case DFORM_DOUBLE
      fmt = 'double';
      sz = 8;
   case DFORM_QWORD
      fmt = 'int64';
      sz = 8;
end
num_amplifier_channels = numel(amplifier_channels);
npts = (heads.stores.((wav_data{1})).size-10) * 4/sz;
num_amplifier_samples = double(npts * numel(heads.stores.((wav_data{1})).data)/num_amplifier_channels);

% board_adc_channels = channel_struct;
% board_dig_in_channels = channel_struct;
% board_dig_out_channels = channel_struct;
% 
% num_board_adc_channels
% num_board_dig_in_channels
% num_board_dig_out_channels
% num_data_blocks
% bytes_per_block
% num_samples_per_data_block
% 
% num_board_adc_samples
% num_board_dig_in_samples
% num_board_dig_out_samples

for ii=DesiredOutputs' %  DesiredOutputs defined below
   header.(ii{:})=eval(ii{:});
end
   header.(ii{:})=eval(ii{:});
end

function DesiredOutputs=DesiredOutputs()
DesiredOutputs = {
   'data_present';
   'sample_rate';
   'amplifier_channels';
%    'board_adc_channels';
%    'board_dig_in_channels';
%    'board_dig_out_channels';
   'num_amplifier_channels';
%    'num_board_adc_channels';
%    'num_board_dig_in_channels';
%    'num_board_dig_out_channels';
   'num_probes';
%    'num_data_blocks';
%    'bytes_per_block';
%    'num_samples_per_data_block';
   'num_amplifier_samples';
%    'num_board_adc_samples';
%    'num_board_dig_in_samples';
%    'num_board_dig_out_samples';
   'filesize';
   'info';
   'wav_data';
   };
end

function spike_trigger_struct_=spike_trigger_struct()
spike_trigger_struct_ = struct( ...
   'voltage_trigger_mode', {}, ...
   'voltage_threshold', {}, ...
   'digital_trigger_channel', {}, ...
   'digital_edge_polarity', {} );
return
end

function channel_struct_=channel_struct()
channel_struct_ = struct( ...
   'native_channel_name', {}, ...
   'custom_channel_name', {}, ...
   'native_order', {}, ...
   'custom_order', {}, ...
   'board_stream', {}, ...
   'chip_channel', {}, ...
   'port_name', {}, ...
   'port_prefix', {}, ...
   'port_number', {}, ...
   'electrode_impedance_magnitude', {}, ...
   'electrode_impedance_phase', {} );
return
end