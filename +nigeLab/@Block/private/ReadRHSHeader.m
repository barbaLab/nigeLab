function [header,FID] = ReadRHSHeader(name,verbose,FID)
%READRHSHEADER  Reads header from Intan .rhs format to parse metadata
%
%  header = ReadRHSHeader(name,verbose);
%  header = ReadRHSHeader([],verbose,FID);
%
%  name : Name of recording .rhd file
%  verbose : True - shows messages; False - suppress command window msg
%  FID : File ID from fopen of file to read

acqsys = 'RHS';

if nargin < 1
   verbose = false;
elseif nargin < 2
   verbose = true;
end

if nargin == 3
   [name,~,~,~] = fopen(FID);
   if isempty(name)
      error('Must provide a valid file pointer.');
   end
elseif nargin == 2
   if isempty(name)
      FID = [];
   else
      % If a pre-specified path exists, must be a valid path.
      if exist(name,'file')==0
         error('Must provide a valid RHD2000 Data File and Path.');
      else
         FID = fopen(name, 'r');
      end
   end
else    % Must select a directory and a file
   FID = [];
end

if isempty(FID)   
   [file, path] = ...
      uigetfile('*.rhs', 'Select an RHS2000 Data File', ...
      'MultiSelect', 'off');
   
   if file == 0 % Must select a file
      error('Must select a valid RHS2000 Data File.');
   end
   
   name = [path, file];
   FID = fopen(name, 'r');
end

% [path,file,~] = fileparts(name);
s = dir(name);
filesize = s.bytes;

% Create structure arrays for each type of data channel.
raw_channels = nigeLab.utils.initChannelStruct('Channels',1);
analogIO_channels = nigeLab.utils.initChannelStruct('Streams',0);
digIO_channels = nigeLab.utils.initChannelStruct('Streams',0);

spikes_triggers=nigeLab.utils.initSpikeTriggerStruct('RHS',1);
stim_triggers = nigeLab.utils.initSpikeTriggerStruct('FSM',0);
dig_in_triggers = nigeLab.utils.initSpikeTriggerStruct('RHS',0);
dig_out_triggers = nigeLab.utils.initSpikeTriggerStruct('RHS',0);

magic_number = fread(FID, 1, 'uint32');
if magic_number ~= hex2dec('d69127ac')
   error('Unrecognized file type.');
end

% Read version number.
data_file_main_version_number = fread(FID, 1, 'int16');
data_file_secondary_version_number = fread(FID, 1, 'int16');

if verbose
   fprintf(1, '\n');
   fprintf(1, 'Reading Intan Technologies RHS2000 Data File, Version %d.%d\n', ...
      data_file_main_version_number, data_file_secondary_version_number);
   fprintf(1, '\n');
end

num_samples_per_data_block = 128;

% Read information of sampling rate and amplifier frequency settings.
sample_rate = fread(FID, 1, 'single');
dsp_enabled = fread(FID, 1, 'int16');
actual_dsp_cutoff_frequency = fread(FID, 1, 'single');
actual_lower_bandwidth = fread(FID, 1, 'single');
actual_lower_settle_bandwidth = fread(FID, 1, 'single');
actual_upper_bandwidth = fread(FID, 1, 'single');

desired_dsp_cutoff_frequency = fread(FID, 1, 'single');
desired_lower_bandwidth = fread(FID, 1, 'single');
desired_lower_settle_bandwidth = fread(FID, 1, 'single');
desired_upper_bandwidth = fread(FID, 1, 'single');

% This tells us if a software 50/60 Hz notch filter was enabled during
% the data acquisition.
notch_filter_mode = fread(FID, 1, 'int16');
notch_filter_frequency = 0;
if (notch_filter_mode == 1)
   notch_filter_frequency = 50;
elseif (notch_filter_mode == 2)
   notch_filter_frequency = 60;
end

desired_impedance_test_frequency = fread(FID, 1, 'single');
actual_impedance_test_frequency = fread(FID, 1, 'single');

amp_settle_mode = fread(FID, 1, 'int16');
charge_recovery_mode = fread(FID, 1, 'int16');

stim_step_size = fread(FID, 1, 'single');
charge_recovery_current_limit = fread(FID, 1, 'single');
charge_recovery_target_voltage = fread(FID, 1, 'single');

% Place notes in data strucure
notes = struct( ...
   'note1', nigeLab.utils.fread_QString(FID), ...
   'note2', nigeLab.utils.fread_QString(FID), ...
   'note3', nigeLab.utils.fread_QString(FID) );

% See if dc amplifier data was saved
DC_amp_data_saved = fread(FID, 1, 'int16');

% Load eval board mode.
eval_board_mode = fread(FID, 1, 'int16');

frequency_parameters = struct( ...
   'amplifier_sample_rate', sample_rate, ...
   'aux_input_sample_rate', sample_rate / 4, ...
   'supply_voltage_sample_rate', sample_rate / 60, ...
   'board_adc_sample_rate', sample_rate, ...
   'board_dig_in_sample_rate', sample_rate, ...
   'desired_dsp_cutoff_frequency', desired_dsp_cutoff_frequency, ...
   'actual_dsp_cutoff_frequency', actual_dsp_cutoff_frequency, ...
   'dsp_enabled', dsp_enabled, ...
   'desired_lower_bandwidth', desired_lower_bandwidth, ...
   'actual_lower_bandwidth', actual_lower_bandwidth, ...
   'desired_upper_bandwidth', desired_upper_bandwidth, ...
   'actual_upper_bandwidth', actual_upper_bandwidth, ...
   'notch_filter_frequency', notch_filter_frequency, ...
   'desired_impedance_test_frequency', desired_impedance_test_frequency, ...
   'actual_impedance_test_frequency', actual_impedance_test_frequency );

stim_parameters = struct( ...
   'stim_step_size', stim_step_size, ...
   'charge_recovery_current_limit', charge_recovery_current_limit, ...
   'charge_recovery_target_voltage', charge_recovery_target_voltage, ...
   'amp_settle_mode', amp_settle_mode, ...
   'charge_recovery_mode', charge_recovery_mode );


reference_channel = nigeLab.utils.fread_QString(FID);

raw_index = 1;
analogIO_index = 1;
digIO_index = 1;

adc_index = [];
dac_index = [];
dig_in_index = [];
dig_out_index = [];

% Read signal summary from data file header.

number_of_signal_groups = fread(FID, 1, 'int16');
for signal_group = 1:number_of_signal_groups
   signal_group_name = nigeLab.utils.fread_QString(FID);
   signal_group_prefix = nigeLab.utils.fread_QString(FID);
   signal_group_enabled = fread(FID, 1, 'int16');
   signal_group_num_channels = fread(FID, 1, 'int16');
   signal_group_num_amp_channels = fread(FID, 1, 'int16');
   
   if (signal_group_num_channels > 0 && signal_group_enabled > 0)
      
      for signal_channel = 1:signal_group_num_channels
         % channel_struct is defined in nigeLab.utils
         new_channel = nigeLab.utils.initChannelStruct('Channels',1);
         new_trigger_channel = nigeLab.utils.initSpikeTriggerStruct('RHS',1);
         
         % fill out fields of channel_struct
         new_channel(1).port_name = signal_group_name;
         new_channel(1).port_prefix = signal_group_prefix;
         new_channel(1).port_number = signal_group;
         new_channel(1).native_channel_name = nigeLab.utils.fread_QString(FID);
         new_channel(1).custom_channel_name = nigeLab.utils.fread_QString(FID);
         new_channel(1).name = new_channel(1).custom_channel_name;
         new_channel(1).native_order = fread(FID, 1, 'int16');
         new_channel(1).custom_order = fread(FID, 1, 'int16');
         signal_type = fread(FID, 1, 'int16');
         channel_enabled = fread(FID, 1, 'int16');
         new_channel(1).chip_channel = fread(FID, 1, 'int16');
         fread(FID, 1, 'int16');  % ignore command_stream
         new_channel(1).board_stream = fread(FID, 1, 'int16');
         if signal_type == 4 % DAC (MM: 2020-01-29 // ONLY VALID FOR FSM VERSION OF RHS @ CPL)
            new_dac_channel = nigeLab.utils.initSpikeTriggerStruct('FSM',1);
            new_dac_channel(1).fsm_enable = fread(FID, 1, 'int16');
            new_dac_channel(1).voltage_threshold = fread(FID, 1, 'int16');
            new_dac_channel(1).amp_trigger_channel = fread(FID, 1, 'int16');
            new_dac_channel(1).trigger_window_type = fread(FID, 1, 'int16'); % 0 include 1 exclude (from memory; not 100% sure)
            new_dac_channel(1).window_start_sample = fread(FID, 1, 'single');
            new_dac_channel(1).window_stop_sample = fread(FID, 1, 'single');
         else
            new_trigger_channel(1).voltage_trigger_mode = fread(FID, 1, 'int16');
            new_trigger_channel(1).voltage_threshold = fread(FID, 1, 'int16');
            new_trigger_channel(1).digital_trigger_channel = fread(FID, 1, 'int16');
            new_trigger_channel(1).digital_edge_polarity = fread(FID, 1, 'int16');
            new_channel(1).electrode_impedance_magnitude = fread(FID, 1, 'single');
            new_channel(1).electrode_impedance_phase = fread(FID, 1, 'single');
         end
         [new_channel(1).chNum,new_channel(1).chStr] = ...
            nigeLab.utils.getChannelNum(new_channel(1).custom_channel_name);
         
         if (channel_enabled)
            switch (signal_type)
               case 0
                  new_channel(1).fs = sample_rate;
                  new_channel(1).signal = nigeLab.utils.signal(...
                     'Data',[],'Raw','Channels','RHS',...
                     new_channel.custom_channel_name,'Channels');
                  raw_channels(raw_index) = new_channel;
                  new_trigger_channel(1).signal = nigeLab.utils.signal(...
                     'Data',[],'Spikes','Events','RHS',...
                     new_channel.custom_channel_name,'Channels');
                  spikes_triggers(raw_index) = new_trigger_channel;
                  raw_index = raw_index + 1;
               case 1
                  % aux inputs; not used in RHS2000 system
               case 2
                  % supply voltage; not used in RHS2000 system
               case 3
                  new_channel(1).fs = sample_rate;
                  new_channel(1).signal = nigeLab.utils.signal(...
                     'Adc',[],'AnalogIO','Streams','RHD',...
                     new_channel.custom_channel_name,'Standard');
                  new_channel = nigeLab.utils.initChannelStruct('Streams',new_channel);
                  analogIO_channels(analogIO_index) = new_channel;
                  adc_index = [adc_index, analogIO_index]; %#ok<AGROW>
                  analogIO_index = analogIO_index + 1;
               case 4
                  new_channel(1).fs = sample_rate;
                  new_channel(1).signal = nigeLab.utils.signal(...
                     'Adc',[],'AnalogIO','Streams','RHS',...
                     new_channel.custom_channel_name,'Standard');
                  new_channel = nigeLab.utils.initChannelStruct('Streams',new_channel);
                  analogIO_channels(analogIO_index) = new_channel;
                  if new_dac_channel(1).trigger_window_type == 0
                     new_dac_channel(1).signal = nigeLab.utils.signal(...
                        'FSM',[],'Stim','Events','RHS',...
                        new_channel.custom_channel_name,'Include');
                  else
                     new_dac_channel(1).signal = nigeLab.utils.signal(...
                        'FSM',[],'Stim','Events','RHS',...
                        new_channel.custom_channel_name,'Exclude');
                  end
                  stim_triggers = [stim_triggers, new_dac_channel];  %#ok<AGROW>
                  dac_index = [dac_index, analogIO_index]; %#ok<AGROW>
                  analogIO_index = analogIO_index + 1;
               case 5
                  new_channel(1).fs = sample_rate;
                  new_channel(1).signal = nigeLab.utils.signal(...
                     'DigIn',[],'DigIO','Streams','RHS',...
                     new_channel.custom_channel_name,'Standard');
                  new_channel = nigeLab.utils.initChannelStruct('Streams',new_channel);                  
                  digIO_channels(digIO_index) = new_channel;
                  if new_channel.native_order >= 12 && new_channel.native_order <= 14
                     new_trigger_channel(1).signal = nigeLab.utils.signal(...
                        'DigIn',[],'DigIO','Events','RHS',...
                        new_channel.custom_channel_name,'FSM');
                  else
                     new_trigger_channel(1).signal = nigeLab.utils.signal(...
                        'DigIn',[],'DigIO','Events','RHS',...
                        new_channel.custom_channel_name,'IO');
                  end
                  dig_in_index = [dig_in_index, digIO_index]; %#ok<AGROW>
                  digIO_index = digIO_index + 1;
               case 6
                  new_channel(1).fs = sample_rate;
                  new_channel(1).signal = nigeLab.utils.signal(...
                     'DigOut',[],'DigIO','Streams','RHS',...
                     new_channel.custom_channel_name,'Standard');
                  new_channel = nigeLab.utils.initChannelStruct('Streams',new_channel);
                  if new_channel.native_order >= 12 && new_channel.native_order <= 14
                     new_trigger_channel(1).signal = nigeLab.utils.signal(...
                        'DigOut',[],'DigIO','Events','RHS',...
                        new_channel.custom_channel_name,'FSM');
                  else
                     new_trigger_channel(1).signal = nigeLab.utils.signal(...
                        'DigOut',[],'DigIO','Events','RHS',...
                        new_channel.custom_channel_name,'IO');
                  end
                  digIO_channels(digIO_index) = new_channel;
                  dig_out_index = [dig_out_index, digIO_index]; %#ok<AGROW>
                  dig_out_triggers = [dig_out_triggers, new_trigger_channel];  %#ok<AGROW>
                  digIO_index = digIO_index + 1;
               otherwise
                  error('Unknown channel type');
            end
         end
         
      end
   end
end

% Summarize contents of data file.
num_raw_channels = raw_index - 1;
num_analogIO_channels = analogIO_index - 1;
num_digIO_channels = digIO_index - 1;

num_dac_channels = numel(dac_index);
num_adc_channels = numel(adc_index);
num_dig_in_channels = numel(dig_in_index);
num_dig_out_channels = numel(dig_out_index);

if verbose
   fprintf(1, 'Found %d amplifier <strong>(raw)</strong> channel%s.\n', ...
      num_raw_channels, num_raw_channels);
   if (DC_amp_data_saved ~= 0)
      fprintf(1, 'Found %d DC amplifier channel%s.\n', ...
         num_raw_channels, (num_raw_channels));
   end
   fprintf(1, 'Found %d board ADC channel%s.\n', ...
      num_adc_channels, (num_adc_channels));
   fprintf(1, 'Found %d board DAC channel%s.\n', ...
      num_dac_channels, (num_dac_channels));
   fprintf(1, 'Found %d board digital input channel%s.\n', ...
      num_dig_in_channels, (num_dig_in_channels));
   fprintf(1, 'Found %d board digital output channel%s.\n', ...
      num_dig_out_channels, (num_dig_out_channels));
   fprintf(1, '\n');
end
% Determine how many samples the data file contains.

% Each data block contains num_samples_per_data_block amplifier samples.
bytes_per_block = num_samples_per_data_block * 4;  % timestamp data
if (DC_amp_data_saved ~= 0)
   bytes_per_block = bytes_per_block + num_samples_per_data_block * (2 + 2 + 2) * num_raw_channels;
else
   bytes_per_block = bytes_per_block + num_samples_per_data_block * (2 + 2) * num_raw_channels;
end
% Board analog inputs are sampled at same rate as amplifiers
bytes_per_block = bytes_per_block + num_samples_per_data_block * 2 * num_adc_channels;
% Board analog outputs are sampled at same rate as amplifiers
bytes_per_block = bytes_per_block + num_samples_per_data_block * 2 * num_dac_channels;
% Board digital inputs are sampled at same rate as amplifiers
if (num_dig_in_channels > 0)
   bytes_per_block = bytes_per_block + num_samples_per_data_block * 2;
end
% Board digital outputs are sampled at same rate as amplifiers
if (num_dig_out_channels > 0)
   bytes_per_block = bytes_per_block + num_samples_per_data_block * 2;
end

% How many data blocks remain in this file?
data_present = 0;
bytes_remaining = filesize - ftell(FID);
if (bytes_remaining > 0)
   data_present = 1;
end

num_data_blocks = floor(bytes_remaining / bytes_per_block);

num_raw_samples = num_samples_per_data_block * num_data_blocks;
num_adc_samples = num_samples_per_data_block * num_data_blocks;
num_dac_samples = num_samples_per_data_block * num_data_blocks;
num_dig_in_samples = num_samples_per_data_block * num_data_blocks;
num_dig_out_samples = num_samples_per_data_block * num_data_blocks;

num_aux_samples = 0;
num_supply_samples = 0;
num_sensor_samples = 0;
num_aux_channels = 0;
num_supply_channels = 0;
num_sensor_channels = 0;

if (DC_amp_data_saved ~= 0)
   num_DC_channels = num_raw_channels;
   num_DC_samples = num_raw_samples;
else
   num_DC_channels = 0;
   num_DC_samples = 0;
end

num_stim_channels = num_raw_channels;
num_stim_samples = num_raw_samples;

record_time = num_raw_samples / sample_rate;

for i = 1:num_raw_channels
   raw_channels(i).signal.Samples = num_raw_samples;
end

for i = 1:num_dac_channels
   analogIO_channels(dac_index(i)).signal.Samples = num_dac_samples;
end

for i = 1:num_adc_channels
   analogIO_channels(adc_index(i)).signal.Samples = num_adc_samples;
end

for i = 1:num_dig_in_channels
   digIO_channels(dig_in_index(i)).signal.Samples = num_dig_in_samples;
end

for i = 1:num_dig_out_channels
   digIO_channels(dig_out_index(i)).signal.Samples = num_dig_out_samples;
end

if verbose
   if (data_present)
      fprintf(1, 'File contains %0.3f seconds of data.  Amplifiers were sampled at %0.2f kS/s, for a total of %d samples.\n', ...
         record_time, sample_rate / 1000, num_raw_samples);
      fprintf(1, '\n');
   else
      fprintf(1, 'Header file contains no data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
         sample_rate / 1000);
      fprintf(1, '\n');
   end
end

header_size=ftell(FID);
% Determine how many probes and channels per probe
probes = unique([raw_channels.port_number]);
num_probes = numel(probes);

DesiredOutputs = nigeLab.utils.initDesiredHeaderFields('RHS').';
for field = DesiredOutputs %  DesiredOutputs defined in nigeLab.utils
   fieldOut = field{:};
   fieldOutVal = eval(fieldOut); % This is for backwards compatibility
   % Should eventually be changed to remove the eval
   header.(fieldOut) = fieldOutVal;
end

return;

end