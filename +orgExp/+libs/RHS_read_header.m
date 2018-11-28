function [header,FID] = RHS_read_header(varargin)

if nargin >0
    VERBOSE = false;
else
    VERBOSE = true;
end

for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if exist('FID','var')
    
    [NAME,~,~,~] = fopen(FID);
    if isempty(NAME)
       error('Must provide a valid file pointer.');
    end
elseif exist('NAME', 'var')
    
    if NAME == 0 % If a pre-specified path exists, must be a valid path.
        error('Must provide a valid RHD2000 Data File and Path.');
    end
    FID = fopen(NAME, 'r'); 
else    % Must select a directory and a file
     
    
    [file, path] = ...
        uigetfile('*.rhs', 'Select an RHS2000 Data File', ...
        'MultiSelect', 'off');
    
    if file == 0 % Must select a file
        error('Must select a valid RHS2000 Data File.');
    end
    
    NAME = [path, file];
    FID = fopen(NAME, 'r');
   

end

[path,file,~] = fileparts(NAME);
s = dir(NAME);
filesize = s.bytes;


amplifier_channels=channel_struct;
spike_triggers=spike_trigger_struct;
board_adc_channels=channel_struct;
board_dac_channels=channel_struct;
board_dig_in_channels=channel_struct;
board_dig_out_channels=channel_struct;


magic_number = fread(FID, 1, 'uint32');
if magic_number ~= hex2dec('d69127ac')
    error('Unrecognized file type.');
end

% Read version number.
data_file_main_version_number = fread(FID, 1, 'int16');
data_file_secondary_version_number = fread(FID, 1, 'int16');

if VERBOSE
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
    'note1', fread_QString(FID), ...
    'note2', fread_QString(FID), ...
    'note3', fread_QString(FID) );

% See if dc amplifier data was saved
dc_amp_data_saved = fread(FID, 1, 'int16');

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


reference_channel = fread_QString(FID);

amplifier_index = 1;
board_adc_index = 1;
board_dac_index = 1;
board_dig_in_index = 1;
board_dig_out_index = 1;

% Read signal summary from data file header.

number_of_signal_groups = fread(FID, 1, 'int16');

for signal_group = 1:number_of_signal_groups
    signal_group_name = fread_QString(FID);
    signal_group_prefix = fread_QString(FID);
    signal_group_enabled = fread(FID, 1, 'int16');
    signal_group_num_channels = fread(FID, 1, 'int16');
    signal_group_num_amp_channels = fread(FID, 1, 'int16');
    
    if (signal_group_num_channels > 0 && signal_group_enabled > 0)
        new_channel(1).port_name = signal_group_name;
        new_channel(1).port_prefix = signal_group_prefix;
        new_channel(1).port_number = signal_group;
        for signal_channel = 1:signal_group_num_channels
            new_channel(1).native_channel_name = fread_QString(FID);
            new_channel(1).custom_channel_name = fread_QString(FID);
            new_channel(1).native_order = fread(FID, 1, 'int16');
            new_channel(1).custom_order = fread(FID, 1, 'int16');
            signal_type = fread(FID, 1, 'int16');
            channel_enabled = fread(FID, 1, 'int16');
            new_channel(1).chip_channel = fread(FID, 1, 'int16');
            fread(FID, 1, 'int16');  % ignore command_stream
            new_channel(1).board_stream = fread(FID, 1, 'int16');
            new_trigger_channel(1).voltage_trigger_mode = fread(FID, 1, 'int16');
            new_trigger_channel(1).voltage_threshold = fread(FID, 1, 'int16');
            new_trigger_channel(1).digital_trigger_channel = fread(FID, 1, 'int16');
            new_trigger_channel(1).digital_edge_polarity = fread(FID, 1, 'int16');
            new_channel(1).electrode_impedance_magnitude = fread(FID, 1, 'single');
            new_channel(1).electrode_impedance_phase = fread(FID, 1, 'single');
            
            if (channel_enabled)
                switch (signal_type)
                    case 0
                        amplifier_channels(amplifier_index) = new_channel;
                        spike_triggers(amplifier_index) = new_trigger_channel;
                        amplifier_index = amplifier_index + 1;
                    case 1
                        % aux inputs; not used in RHS2000 system
                    case 2
                        % supply voltage; not used in RHS2000 system
                    case 3
                        board_adc_channels(board_adc_index) = new_channel;
                        board_adc_index = board_adc_index + 1;
                    case 4
                        board_dac_channels(board_dac_index) = new_channel;
                        board_dac_index = board_dac_index + 1;
                    case 5
                        board_dig_in_channels(board_dig_in_index) = new_channel;
                        board_dig_in_index = board_dig_in_index + 1;
                    case 6
                        board_dig_out_channels(board_dig_out_index) = new_channel;
                        board_dig_out_index = board_dig_out_index + 1;
                    otherwise
                        error('Unknown channel type');
                end
            end
            
        end
    end
end

% Summarize contents of data file.
num_amplifier_channels = amplifier_index - 1;
num_board_adc_channels = board_adc_index - 1;
num_board_dac_channels = board_dac_index - 1;
num_board_dig_in_channels = board_dig_in_index - 1;
num_board_dig_out_channels = board_dig_out_index - 1;

if VERBOSE
    fprintf(1, 'Found %d amplifier channel%s.\n', ...
        num_amplifier_channels, num_amplifier_channels);
    if (dc_amp_data_saved ~= 0)
        fprintf(1, 'Found %d DC amplifier channel%s.\n', ...
            num_amplifier_channels, (num_amplifier_channels));
    end
    fprintf(1, 'Found %d board ADC channel%s.\n', ...
        num_board_adc_channels, (num_board_adc_channels));
    fprintf(1, 'Found %d board DAC channel%s.\n', ...
        num_board_dac_channels, (num_board_dac_channels));
    fprintf(1, 'Found %d board digital input channel%s.\n', ...
        num_board_dig_in_channels, (num_board_dig_in_channels));
    fprintf(1, 'Found %d board digital output channel%s.\n', ...
        num_board_dig_out_channels, (num_board_dig_out_channels));
    fprintf(1, '\n');
end
% Determine how many samples the data file contains.

% Each data block contains num_samples_per_data_block amplifier samples.
bytes_per_block = num_samples_per_data_block * 4;  % timestamp data
if (dc_amp_data_saved ~= 0)
    bytes_per_block = bytes_per_block + num_samples_per_data_block * (2 + 2 + 2) * num_amplifier_channels;
else
    bytes_per_block = bytes_per_block + num_samples_per_data_block * (2 + 2) * num_amplifier_channels;
end
% Board analog inputs are sampled at same rate as amplifiers
bytes_per_block = bytes_per_block + num_samples_per_data_block * 2 * num_board_adc_channels;
% Board analog outputs are sampled at same rate as amplifiers
bytes_per_block = bytes_per_block + num_samples_per_data_block * 2 * num_board_dac_channels;
% Board digital inputs are sampled at same rate as amplifiers
if (num_board_dig_in_channels > 0)
    bytes_per_block = bytes_per_block + num_samples_per_data_block * 2;
end
% Board digital outputs are sampled at same rate as amplifiers
if (num_board_dig_out_channels > 0)
    bytes_per_block = bytes_per_block + num_samples_per_data_block * 2;
end

% How many data blocks remain in this file?
data_present = 0;
bytes_remaining = filesize - ftell(FID);
if (bytes_remaining > 0)
    data_present = 1;
end

num_data_blocks = floor(bytes_remaining / bytes_per_block);

num_amplifier_samples = num_samples_per_data_block * num_data_blocks;
num_board_adc_samples = num_samples_per_data_block * num_data_blocks;
num_board_dac_samples = num_samples_per_data_block * num_data_blocks;
num_board_dig_in_samples = num_samples_per_data_block * num_data_blocks;
num_board_dig_out_samples = num_samples_per_data_block * num_data_blocks;

record_time = num_amplifier_samples / sample_rate;

if VERBOSE
    if (data_present)
        fprintf(1, 'File contains %0.3f seconds of data.  Amplifiers were sampled at %0.2f kS/s, for a total of %d samples.\n', ...
            record_time, sample_rate / 1000, num_amplifier_samples);
        fprintf(1, '\n');
    else
        fprintf(1, 'Header file contains no data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
            sample_rate / 1000);
        fprintf(1, '\n');
    end
end

header_size=ftell(FID);
probes = unique([amplifier_channels.port_number]);
num_probes = numel(probes);

for ii=DesiredOutputs' %  DesiredOutputs defined below
    header.(ii{:})=eval(ii{:});
end

end

function a = fread_QString(fid)

% a = read_QString(fid)
%
% Read Qt style QString.  The first 32-bit unsigned number indicates
% the length of the string (in bytes).  If this number equals 0xFFFFFFFF,
% the string is null.

a = '';
length = fread(fid, 1, 'uint32');
if length == hex2num('ffffffff')
    return;
end
% convert length from bytes to 16-bit Unicode words
length = length / 2;

for i=1:length
    a(i) = fread(fid, 1, 'uint16');
end

end

function DesiredOutputs=DesiredOutputs()
DesiredOutputs = {
    
    'data_present';
    'dc_amp_data_saved';
    'sample_rate';
    'frequency_parameters';
    'stim_parameters'
    'amplifier_channels';
    'board_adc_channels';
    'board_dac_channels';
    'board_dig_in_channels';
    'board_dig_out_channels';
    'spike_triggers';
    'stim_step_size';
    'num_amplifier_channels';
    'num_board_adc_channels';
    'num_board_dac_channels';
    'num_board_dig_in_channels';
    'num_board_dig_out_channels';
    'probes';
    'num_probes';
    'num_data_blocks';
    'num_samples_per_data_block';
    'num_amplifier_samples';
    'num_board_adc_samples';
    'num_board_dac_samples';
    'num_board_dig_in_samples';
    'num_board_dig_out_samples';
    'header_size';
    'filesize';   
    'bytes_per_block';
    
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