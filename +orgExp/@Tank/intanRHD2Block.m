function intanRHD2Block(tankObj,varargin)
%% INTANRHD2BLOCK  Convert Intan RHD or RHS to Matlab BLOCK format
%
%  tankObj.INTANRHD2BLOCK;
%  INTANRHD2BLOCK(tankObj,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%   tankObj    :     Tank Class object.
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Creates filtered streams *.mat files in TANK-BLOCK hierarchy format.
%  
%% DEFAULTS
DEFTANK = 'R:/Rat/Intan';       % Default tank path for file-selection UI
SAVELOC = tankObj.SaveLoc;

RAW_ID      = '_RawData';                             % Raw stream ID
FILT_ID     = '_Filtered';                            % Filtered stream ID
CAR_ID     = '_FilteredCAR';                            % Filtered stream ID
DIG_ID      = '_Digital';                             % Digital stream ID

% Filter params
STATE_FILTER = false; % Flag to emulate hardware high-pass filter (if true)

FS = 20000;       % Sampling Frequency
FSTOP1 = 250;     % First Stopband Frequency
FPASS1 = 300;     % First Passband Frequency
FPASS2 = 3000;    % Second Passband Frequency
FSTOP2 = 3050;    % Second Stopband Frequency
ASTOP1 = 70;      % First Stopband Attenuation (dB)
APASS  = 0.001;   % Passband Ripple (dB)
ASTOP2 = 70;      % Second Stopband Attenuation (dB)

%% PARSE VARARGIN
if nargin==1
    varargin = varargin{1};
end

for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if exist('GITINFO','var')
    gitInfo = GITINFO; clear GITINFO %#ok<*NASGU>
else
    gitInfo = NaN;
end

%% SELECT RECORDING
% If pre-specified in optional arguments, skip this step.
if exist('NAME', 'var') == 0
    
    [file, path] = ...
    uigetfile('*.rhd', 'Select an RHD2000 Data File', ...
              DEFTANK, ...
              'MultiSelect', 'off');
    
    if file == 0 % Must select a file
        error('Must select a valid RHD2000 Data File.');
    end
    
    NAME = [path, file];
    file = file(1:end-4); %remove extension
    
else    % If a pre-specified path exists, must be a valid path.
    
    if NAME == 0 % Must select a directory
        error('Must provide a valid RHD2000 Data File and Path.');
    end
    
    [path,file,~] = fileparts(NAME);
end

tic;
fid = fopen(NAME, 'r');

s = dir(NAME);
filesize = s.bytes;

temp = strsplit(file, '_'); 

Animal = temp{1};
if numel(temp)>5
    Rec = strjoin(temp(2:5),'_'); clear temp
else
    Rec = strjoin(temp(2:end),'_');
end

paths.A = fullfile(SAVELOC,Animal);
paths.R = fullfile(SAVELOC,Animal,[Animal '_' Rec]);
paths.RW= fullfile(paths.R,[Animal '_' Rec RAW_ID]);
paths.FW= fullfile(paths.R,[Animal '_' Rec FILT_ID]);
paths.CARW= fullfile(paths.R,[Animal '_' Rec CAR_ID]);
paths.DW= fullfile(paths.R,[Animal '_' Rec DIG_ID]);

if exist(paths.A,'dir')==0
    mkdir(paths.A);
end

if exist(paths.R,'dir')==0
    mkdir(paths.R);
end

if exist(paths.RW,'dir')==0
    mkdir(paths.RW);
end

if exist(paths.FW,'dir')==0
    mkdir(paths.FW);
end

if exist(paths.CARW,'dir')==0
    mkdir(paths.CARW);
end

if exist(paths.DW,'dir')==0
    mkdir(paths.DW);
end

paths.RW_N = fullfile(paths.RW,[Animal '_' Rec '_Raw_P%s_Ch_%s.mat']);
paths.FW_N = fullfile(paths.FW,[Animal '_' Rec '_Filt_P%s_Ch_%s.mat']);
paths.CARW_N = fullfile(paths.CARW,[Animal '_' Rec '_FiltCAR_P%s_Ch_%s.mat']);
paths.DW_N = fullfile(paths.DW,[Animal '_' Rec '_DIG_%s.mat']);

% Check 'magic number' at beginning of file to make sure this is an Intan
% Technologies RHD2000 data file.
magic_number = fread(fid, 1, 'uint32');
if magic_number ~= hex2dec('c6912702')
    error('Unrecognized file type.');
end

% Read version number.
data_file_main_version_number = fread(fid, 1, 'int16');
data_file_secondary_version_number = fread(fid, 1, 'int16');

fprintf(1, '\n');
fprintf(1, 'Reading Intan Technologies RHD2000 Data File, Version %d.%d\n', ...
    data_file_main_version_number, data_file_secondary_version_number);
fprintf(1, '\n');
fprintf(1, 'File: %s\n', [Animal '_' Rec]);
fprintf(1, '\n');

% Read information of sampling rate and amplifier frequency settings.
sample_rate = fread(fid, 1, 'single');
dsp_enabled = fread(fid, 1, 'int16');
actual_dsp_cutoff_frequency = fread(fid, 1, 'single');
actual_lower_bandwidth = fread(fid, 1, 'single');
actual_upper_bandwidth = fread(fid, 1, 'single');

desired_dsp_cutoff_frequency = fread(fid, 1, 'single');
desired_lower_bandwidth = fread(fid, 1, 'single');
desired_upper_bandwidth = fread(fid, 1, 'single');

% This tells us if a software 50/60 Hz notch filter was enabled during
% the data acquisition.
notch_filter_mode = fread(fid, 1, 'int16');
notch_filter_frequency = 0;
if (notch_filter_mode == 1)
    notch_filter_frequency = 50;
elseif (notch_filter_mode == 2)
    notch_filter_frequency = 60;
end

desired_impedance_test_frequency = fread(fid, 1, 'single');
actual_impedance_test_frequency = fread(fid, 1, 'single');

% Place notes in data strucure
notes = struct( ...
    'note1', fread_QString(fid), ...
    'note2', fread_QString(fid), ...
    'note3', fread_QString(fid) );
    
% If data file is from GUI v1.1 or later, see if temperature sensor data
% was saved.
num_temp_sensor_channels = 0;
if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 1) ...
    || (data_file_main_version_number > 1))
    num_temp_sensor_channels = fread(fid, 1, 'int16');
end

% If data file is from GUI v1.3 or later, load eval board mode.
eval_board_mode = 0;
if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 3) ...
    || (data_file_main_version_number > 1))
    eval_board_mode = fread(fid, 1, 'int16');
end

% Make data output struct similar to TDT2MAT
block = struct('epocs',[],'snips',[],'streams',[],'scalars',[],'info',[]);

% Place frequency-related information in data structure.
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



% Define data structure for spike trigger settings.
spike_trigger_struct = struct( ...
    'voltage_trigger_mode', {}, ...
    'voltage_threshold', {}, ...
    'digital_trigger_channel', {}, ...
    'digital_edge_polarity', {} );

new_trigger_channel = struct(spike_trigger_struct);
spike_triggers = struct(spike_trigger_struct);

% Define data structure for data channels.
channel_struct = struct( ...
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

new_channel = struct(channel_struct);

% Create structure arrays for each type of data channel.
amplifier_channels = struct(channel_struct);
aux_input_channels = struct(channel_struct);
supply_voltage_channels = struct(channel_struct);
board_adc_channels = struct(channel_struct);
board_dig_in_channels = struct(channel_struct);
board_dig_out_channels = struct(channel_struct);

amplifier_index = 1;
aux_input_index = 1;
supply_voltage_index = 1;
board_adc_index = 1;
board_dig_in_index = 1;
board_dig_out_index = 1;

% Read signal summary from data file header.

number_of_signal_groups = fread(fid, 1, 'int16');

for signal_group = 1:number_of_signal_groups
    signal_group_name = fread_QString(fid);
    signal_group_prefix = fread_QString(fid);
    signal_group_enabled = fread(fid, 1, 'int16');
    signal_group_num_channels = fread(fid, 1, 'int16');
    signal_group_num_amp_channels = fread(fid, 1, 'int16');

    if (signal_group_num_channels > 0 && signal_group_enabled > 0)
        new_channel(1).port_name = signal_group_name;
        new_channel(1).port_prefix = signal_group_prefix;
        new_channel(1).port_number = signal_group;
        for signal_channel = 1:signal_group_num_channels
            new_channel(1).native_channel_name = fread_QString(fid);
            new_channel(1).custom_channel_name = fread_QString(fid);
            new_channel(1).custom_channel_name = strrep(new_channel(1).custom_channel_name,' ','');
            new_channel(1).custom_channel_name = strrep(new_channel(1).custom_channel_name,'-','');
            new_channel(1).native_order = fread(fid, 1, 'int16');
            new_channel(1).custom_order = fread(fid, 1, 'int16');
            signal_type = fread(fid, 1, 'int16');
            channel_enabled = fread(fid, 1, 'int16');
            new_channel(1).chip_channel = fread(fid, 1, 'int16');
            new_channel(1).board_stream = fread(fid, 1, 'int16');
            new_trigger_channel(1).voltage_trigger_mode = fread(fid, 1, 'int16');
            new_trigger_channel(1).voltage_threshold = fread(fid, 1, 'int16');
            new_trigger_channel(1).digital_trigger_channel = fread(fid, 1, 'int16');
            new_trigger_channel(1).digital_edge_polarity = fread(fid, 1, 'int16');
            new_channel(1).electrode_impedance_magnitude = fread(fid, 1, 'single');
            new_channel(1).electrode_impedance_phase = fread(fid, 1, 'single');
            
            if (channel_enabled)
                switch (signal_type)
                    case 0
                        amplifier_channels(amplifier_index) = new_channel;
                        spike_triggers(amplifier_index) = new_trigger_channel;
                        amplifier_index = amplifier_index + 1;
                    case 1
                        aux_input_channels(aux_input_index) = new_channel;
                        aux_input_index = aux_input_index + 1;
                    case 2
                        supply_voltage_channels(supply_voltage_index) = new_channel;
                        supply_voltage_index = supply_voltage_index + 1;
                    case 3
                        board_adc_channels(board_adc_index) = new_channel;
                        board_adc_index = board_adc_index + 1;
                    case 4
                        board_dig_in_channels(board_dig_in_index) = new_channel;
                        board_dig_in_index = board_dig_in_index + 1;
                    case 5
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
num_aux_input_channels = aux_input_index - 1;
num_supply_voltage_channels = supply_voltage_index - 1;
num_board_adc_channels = board_adc_index - 1;
num_board_dig_in_channels = board_dig_in_index - 1;
num_board_dig_out_channels = board_dig_out_index - 1;

fprintf(1, 'Found %d amplifier channel%s.\n', ...
    num_amplifier_channels, plural(num_amplifier_channels));
fprintf(1, 'Found %d auxiliary input channel%s.\n', ...
    num_aux_input_channels, plural(num_aux_input_channels));
fprintf(1, 'Found %d supply voltage channel%s.\n', ...
    num_supply_voltage_channels, plural(num_supply_voltage_channels));
fprintf(1, 'Found %d board ADC channel%s.\n', ...
    num_board_adc_channels, plural(num_board_adc_channels));
fprintf(1, 'Found %d board digital input channel%s.\n', ...
    num_board_dig_in_channels, plural(num_board_dig_in_channels));
fprintf(1, 'Found %d board digital output channel%s.\n', ...
    num_board_dig_out_channels, plural(num_board_dig_out_channels));
fprintf(1, 'Found %d temperature sensors channel%s.\n', ...
    num_temp_sensor_channels, plural(num_temp_sensor_channels));
fprintf(1, '\n');


% Determine how many probes and channels per probe

nPort   = [amplifier_channels(:).port_number];
nProbes = numel(unique(nPort));

for iN = 1:nProbes
    eval(['numArray' num2str(iN) 'Chans = sum(nPort == iN);']);
end

% Determine how many samples the data file contains.

% Each data block contains 60 amplifier samples.
bytes_per_block = 60 * 4;  % timestamp data
bytes_per_block = bytes_per_block + 60 * 2 * num_amplifier_channels;
% Auxiliary inputs are sampled 4x slower than amplifiers
bytes_per_block = bytes_per_block + 15 * 2 * num_aux_input_channels;
% Supply voltage is sampled 60x slower than amplifiers
bytes_per_block = bytes_per_block + 1 * 2 * num_supply_voltage_channels;
% Board analog inputs are sampled at same rate as amplifiers
bytes_per_block = bytes_per_block + 60 * 2 * num_board_adc_channels;
% Board digital inputs are sampled at same rate as amplifiers
if (num_board_dig_in_channels > 0)
    bytes_per_block = bytes_per_block + 60 * 2;
end
% Board digital outputs are sampled at same rate as amplifiers
if (num_board_dig_out_channels > 0)
    bytes_per_block = bytes_per_block + 60 * 2;
end
% Temp sensor is sampled 60x slower than amplifiers
if (num_temp_sensor_channels > 0)
   bytes_per_block = bytes_per_block + 1 * 2 * num_temp_sensor_channels; 
end

% How many data blocks remain in this file?
data_present = 0;
bytes_remaining = filesize - ftell(fid);
if (bytes_remaining > 0)
    data_present = 1;
end

num_data_blocks = bytes_remaining / bytes_per_block;

num_amplifier_samples = 60 * num_data_blocks;

if num_amplifier_samples < 60
    fprintf(1, 'No stream data: %s\n', [Animal '_' Rec]);
    fprintf(1, 'File not extracted.\n');
    fprintf(1, '\n');
    return;
end

num_aux_input_samples = 15 * num_data_blocks;
num_supply_voltage_samples = 1 * num_data_blocks;
num_board_adc_samples = 60 * num_data_blocks;
num_board_dig_in_samples = 60 * num_data_blocks;
num_board_dig_out_samples = 60 * num_data_blocks;

record_time = num_amplifier_samples / sample_rate;

if (data_present)
    fprintf(1, 'File contains %0.3f seconds of data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
        record_time, sample_rate / 1000);
    fprintf(1, '\n');
else
    fprintf(1, 'Header file contains no data.  Amplifiers were sampled at %0.2f kS/s.\n', ...
        sample_rate / 1000);
    fprintf(1, '\n');
end


if (data_present)
    
    % Pre-allocate memory for data.
    fprintf(1, 'Allocating memory for data...\n');

    t_amplifier = zeros(1, num_amplifier_samples);

    block.streams.Wave.data=zeros(num_amplifier_channels, num_amplifier_samples);
    block.streams.Wave.fs=sample_rate;  

    
    %amplifier_data = zeros(num_amplifier_channels, num_amplifier_samples);
    block.streams.AuxI.data = zeros(num_aux_input_channels, num_aux_input_samples);
    block.streams.AuxI.fs   = frequency_parameters.aux_input_sample_rate;
    block.streams.Volt.data = zeros(num_supply_voltage_channels, num_supply_voltage_samples);
    block.streams.Volt.fs   = sample_rate/60;
    block.streams.Temp.data = zeros(num_temp_sensor_channels, num_supply_voltage_samples);
    block.streams.Temp.fs   = sample_rate;
    block.streams.Badc.data = zeros(num_board_adc_channels, num_board_adc_samples);
    block.streams.Badc.fs   = sample_rate;
    block.streams.DigI.data = zeros(1, num_board_dig_in_samples);
    block.streams.DigI.fs   = sample_rate;
    block.streams.DigO.data = zeros(1, num_board_dig_out_samples);
    block.streams.DigO.fs   = sample_rate;
    
    for i=1:num_board_dig_in_channels
        eval([board_dig_in_channels(i).custom_channel_name '=zeros(1,num_board_dig_in_samples);']);
    end
    for i=1:num_board_dig_out_channels
        eval([board_dig_out_channels(i).custom_channel_name '=zeros(1,num_board_dig_out_samples);']);
    end

    % Read sampled data from file.
    fprintf(1, 'Reading data from file...\n');

    amplifier_index = 1;
    aux_input_index = 1;
    supply_voltage_index = 1;
    board_adc_index = 1;
    board_dig_in_index = 1;
    board_dig_out_index = 1;

    print_increment = 10;
    percent_done = print_increment;
    for i=1:num_data_blocks
        % In version 1.2, we moved from saving timestamps as unsigned
        % integeters to signed integers to accomodate negative (adjusted)
        % timestamps for pretrigger data.
        if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 2) ...
        || (data_file_main_version_number > 1))
            t_amplifier(amplifier_index:(amplifier_index+59)) = fread(fid, 60, 'int32');
        else
            t_amplifier(amplifier_index:(amplifier_index+59)) = fread(fid, 60, 'uint32');
        end
        if (num_amplifier_channels > 0)
            block.streams.Wave.data(:,amplifier_index:(amplifier_index+59)) = ...
                fread(fid, [60, num_amplifier_channels], 'uint16').';
        end
        if (num_aux_input_channels > 0)
            block.streams.AuxI.data(:, aux_input_index:(aux_input_index+14)) = fread(fid, [15, num_aux_input_channels], 'uint16')';
            block.streams.AuxI.fs = frequency_parameters.aux_input_sample_rate;
        end
        if (num_supply_voltage_channels > 0)
            block.streams.Volt.data(:, supply_voltage_index) = fread(fid, [1, num_supply_voltage_channels], 'uint16')';
            block.streams.Volt.fs = frequency_parameters.supply_voltage_sample_rate;
        end
        if (num_temp_sensor_channels > 0)
            block.streams.Temp.data(:, supply_voltage_index) = fread(fid, [1, num_temp_sensor_channels], 'int16')';
            block.streams.Temp.fs = sample_rate;
        end
        if (num_board_adc_channels > 0)
            block.streams.Badc.data(:, board_adc_index:(board_adc_index+59)) = fread(fid, [60, num_board_adc_channels], 'uint16')';
            block.streams.Badc.fs = frequency_parameters.board_adc_sample_rate;
        end
        if (num_board_dig_in_channels > 0)
            block.streams.DigI.data(board_dig_in_index:(board_dig_in_index+59)) = fread(fid, 60, 'uint16');
            block.streams.DigI.fs = sample_rate;
        end
        if (num_board_dig_out_channels > 0)
            block.streams.DigO.data(board_dig_out_index:(board_dig_out_index+59)) = fread(fid, 60, 'uint16');
            block.streams.DigO.fs = sample_rate;
        end

        amplifier_index = amplifier_index + 60;
        aux_input_index = aux_input_index + 15;
        supply_voltage_index = supply_voltage_index + 1;
        board_adc_index = board_adc_index + 60;
        board_dig_in_index = board_dig_in_index + 60;
        board_dig_out_index = board_dig_out_index + 60;

        fraction_done = 100 * (i / num_data_blocks);
        if (fraction_done >= percent_done)
            fprintf(1, '%d%% done...\n', percent_done);
            percent_done = percent_done + print_increment;
        end
    end

    % Make sure we have read exactly the right amount of data.
    bytes_remaining = filesize - ftell(fid);
    if (bytes_remaining ~= 0)
        %error('Error: End of file not reached.');
    end

end


% Close data file.
fclose(fid);

if (data_present)
    
    fprintf(1, 'Parsing data...\n');

    % Extract digital input channels to separate variables.
    for i=1:num_board_dig_in_channels
       mask = 2^(board_dig_in_channels(i).native_order) * ones(size(block.streams.DigI.data));
       cur_dig_in_data=zeros(size(block.streams.DigI.data));
       cur_dig_in_data(:) = (bitand(block.streams.DigI.data, mask) > 0);
       eval([board_dig_in_channels(i).custom_channel_name '=cur_dig_in_data;']);
    end
    for i=1:num_board_dig_out_channels
       mask = 2^(board_dig_out_channels(i).native_order) * ones(size(block.streams.DigO.data));
       cur_dig_out_data=zeros(size(block.streams.DigO.data));
       cur_dig_out_data(:) = (bitand(block.streams.DigO.data, mask) > 0);
       eval([board_dig_out_channels(i).custom_channel_name '=cur_dig_out_data;']);
    end
    
    % Scale voltage levels appropriately.
    block.streams.Wave.data=0.195 * (block.streams.Wave.data - 32768);

    block.streams.AuxI.data = 37.4e-6 * block.streams.AuxI.data; % units = volts

    % Check for gaps in timestamps.
    num_gaps = sum(diff(t_amplifier) ~= 1);
    if (num_gaps == 0)
        fprintf(1, 'No missing timestamps in data.\n');
    else
        fprintf(1, 'Warning: %d gaps in timestamp data found.  Time scale will not be uniform!\n', ...
            num_gaps);
    end
end


% Get general experiment information

if ismember('/', path)
    temppath = strsplit(path, '/');
else
    temppath = strsplit(path, '\');
end

tankpath = strjoin(temppath(1:end-2), '/');
blockname = temppath{end-1};

block.info.tankpath = tankpath;
block.info.blockname = blockname;
block.info.notes = notes;
block.info.frequency_pars = frequency_parameters;


% Save single-channel raw data

if (num_amplifier_channels > 0)
    RW_info = amplifier_channels;
    
    paths.RW = strrep(paths.RW, '\', '/');
    
    infoname = fullfile(paths.RW,[Animal '_' Rec '_RawWave_Info.mat']);
    save(infoname,'RW_info','gitInfo','-v7.3');
    
    % Rely on user to exclude "bad" channels during the recording?
    
    paths.FW = strrep(paths.FW, '\', '/');
    paths.FW_N = strrep(paths.FW_N, '\', '/');
    paths.CARW_N = strrep(paths.CARW_N, '\', '/');
    
    paths.RW_N = strrep(paths.RW_N, '\', '/');
    if (data_present)
        fprintf(1,'->\tSaving and filtering streams for %s: %s', Animal, Rec);
        for iCh = 1:num_amplifier_channels
            fprintf(1,'. ');
            pnum  = num2str(amplifier_channels(iCh).board_stream+1);
            chnum = amplifier_channels(iCh).custom_channel_name(2:4);
            fname = sprintf(paths.RW_N, pnum, chnum); 
            data = single(block.streams.Wave.data(iCh,:));
            if isfield(block.streams.Wave,'fs')
               fs = block.streams.Wave.fs;
            else
               fs = FS;
            end
            save(fname,'data','fs','gitInfo','-v7.3');
            if STATE_FILTER
               block.streams.Wave.data(iCh,:) = HPF(double(data),FPASS1,fs);
            else
               [~, bpFilt] = extractionBandPassFilt('FS',fs,...
                                                    'FSTOP1',FSTOP1,...
                                                    'FPASS1',FPASS1,...
                                                    'FPASS2',FPASS2,...
                                                    'FSTOP2',FSTOP2,...
                                                    'ASTOP1',ASTOP1,...
                                                    'APASS',APASS,...
                                                    'ASTOP2',ASTOP2); %#ok<UNRCH>
               block.streams.Wave.data(iCh,:) = filtfilt(bpFilt,double(data));
            end
            fname = sprintf(paths.FW_N, pnum, chnum);
            data = single(block.streams.Wave.data(iCh,:));  % DTB: removed CAR until after checking for clean data
            save(fname,'data','fs','gitInfo','-v7.3');
        end
        fprintf(1,'complete.\n');
        clear data
        board_stream = [amplifier_channels.board_stream];
        nProbes = numel(unique(board_stream));
        
        for iN = 1:nProbes
            fprintf(1,'\t->Automatically re-referencing (Probe %d of %d)',...
                iN,nProbes);
            vec = find(board_stream==(iN-1));
            vec = reshape(vec,1,numel(vec));
            ref = mean(block.streams.Wave.data(vec,:));
            for iCh = vec
                fprintf(1,'. ');
                pnum  = num2str(iN);
                chnum = amplifier_channels(iCh).custom_channel_name(2:4);
                
                fname = sprintf(paths.CARW_N, pnum, chnum);
                data = single(block.streams.Wave.data(iCh,:) - ref);
                save(fname,'data','fs','gitInfo','-v7.3');
            end
            fprintf(1,'complete.\n');
        end            

    end
end

% Save single-channel aux data

if (num_aux_input_channels > 0)
    Aux_info = aux_input_channels;
    
    paths.DW = strrep(paths.DW, '\', '/');
    
    infoname = fullfile(paths.DW,[Animal '_' Rec '_Aux_Info.mat']);
    save(infoname,'Aux_info','gitInfo','-v7.3');
    
    
    paths.DW_N = strrep(paths.DW_N, '\', '/');
    
    if (data_present)
        for i=1:num_aux_input_channels
            fname = sprintf(paths.DW_N, aux_input_channels(i).custom_channel_name); 
            
            data = single(block.streams.AuxI.data(i,:));
            fs = block.streams.AuxI.fs;
            
            save(fname,'data','fs','gitInfo','-v7.3');
        end

    end
end

% Save single-channel digital input data

if (num_board_dig_in_channels > 0)
    DigI_info = board_dig_in_channels;
    
    
    
    infoname = fullfile(paths.DW,[Animal '_' Rec '_Digital_Input_Info.mat']);
    save(infoname,'DigI_info','gitInfo','-v7.3');

    
    
    if (data_present)
        for i=1:num_board_dig_in_channels
            fname = sprintf(paths.DW_N, board_dig_in_channels(i).custom_channel_name); 
            
            eval(['data = single(' board_dig_in_channels(i).custom_channel_name ');']);
            fs = sample_rate;
            
            save(fname,'data','fs','gitInfo','-v7.3');
        end

    end
end

% Save single-channel digital output data

if (num_board_dig_out_channels > 0)

    DigO_info = board_dig_out_channels;
    infoname = fullfile(paths.DW,[Animal '_' Rec '_Digital_Output_Info.mat']);
    save(infoname,'DigO_info','gitInfo','-v7.3');
    
    if (data_present)
        for i=1:num_board_dig_out_channels
            fname = sprintf(paths.DW_N, board_dig_out_channels(i).custom_channel_name); 
            
            eval(['data = single(' board_dig_out_channels(i).custom_channel_name ');']);
            fs = sample_rate;
            
            save(fname,'data','fs','gitInfo','-v7.3');
            
        end
    end
    
    
end

% FOR NOW, LEAVE THESE UNSAVED (TYPICALLY UNUSED)

% if (num_supply_voltage_channels > 0)
%     block.info.supply_voltage_chans = supply_voltage_channels;
% end

% if (num_board_adc_channels > 0)
%     block.info.adc = board_adc_channels;
% end

% if (num_temp_sensor_channels > 0)
%     if (data_present)
%         move_to_base_workspace(block.streams.Temp.data);
%         move_to_base_workspace(t_temp_sensor);
%     end
% end

% Save general experiment information

info = block.info;
save(fullfile(paths.R,[Animal '_' Rec '_GenInfo.mat']),'info','gitInfo','-v7.3');

fprintf(1, 'Done!  Elapsed time: %0.1f seconds\n', toc);
fprintf(1, 'Single-channel extraction and filtering complete.\n');
fprintf(1, '\n');
beep;
pause(0.5)
beep;
pause(0.5);
beep;

return


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

return


function s = plural(n)

% s = plural(n)
% 
% Utility function to optionally plurailze words based on the value
% of n.

if (n == 1)
    s = '';
else
    s = 's';
end

return
