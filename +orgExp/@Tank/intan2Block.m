function intan2Block(tankObj,varargin)
%% INTAN2BLOCK  Convert Intan RHD or RHS to Matlab BLOCK format
%
%  tankObj.INTAN2BLOCK;
%  INTAN2BLOCK(tankObj,'NAME',value,...);
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
SAVELOC = 'P:/Extracted_Data_To_Move/Rat/Intan';

RAW_ID      = '_RawData';                 % Raw stream ID
FILT_ID     = '_Filtered';                % Filtered stream ID
CAR_ID     = '_FilteredCAR';              % Spatial re-reference stream ID
DIG_ID      = '_Digital';                 % Digital stream ID
STIM_SUPPRESS = false;
STIM_P_CH = [nan, nan];
STIM_BLANK = [1 3];
FILE_TYPE = 'rhd';

% Filter command
STATE_FILTER = true; % Flag to emulate hardware high-pass filter (if true)
FSTOP1 = 250;        % First Stopband Frequency
FPASS1 = 300;        % First Passband Frequency
FPASS2 = 3000;       % Second Passband Frequency
FSTOP2 = 3050;       % Second Stopband Frequency
ASTOP1 = 70;         % First Stopband Attenuation (dB)
APASS  = 0.001;      % Passband Ripple (dB)
ASTOP2 = 70;         % Second Stopband Attenuation (dB)
MATCH  = 'both';     % Band to match exactly

%% PARSE VARARGIN
for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) ' = varargin{iV+1};']);
end

if STIM_SUPPRESS
   if isnan(STIM_P_CH(1)) %#ok<UNRCH>
      error('STIM Probe Number not specified (''STIM_P_CH(1)'')');
   elseif isnan(STIM_P_CH(2))
      error('STIM Channel Number not specified (''STIM_P_CH(2)'')');
   end
end

if (~isnan(STIM_P_CH(1)) && ~isnan(STIM_P_CH(2)))
   STIM_SUPPRESS = true;
end
   
if exist('GITINFO','var')
    gitInfo = GITINFO; clear GITINFO %#ok<*NASGU>
else
    gitInfo = NaN;
end

if exist('NAME', 'var') == 0

    [file, path, ~] = ...
        uigetfile('*.rhs', 'Select an RHS2000 Data File', ...
            DEFTANK, ...
            'MultiSelect', 'off');

    if (file == 0)
        error('Must select a valid RHS2000 Data File.');
    end
    
    NAME = [path, file];
    file = file(1:end-4); %remove extension
else    % If a pre-specified path exists, must be a valid path.
    
    if NAME == 0 %#ok<*NODEF> % Must select a directory
        error('Must provide a valid RHS2000 Data File and Path.');
        return %#ok<UNRCH>
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
% Technologies RHS2000 data file.
magic_number = fread(fid, 1, 'uint32');
if magic_number ~= hex2dec('d69127ac')
    error('Unrecognized file type.');
end

% Read version number.
data_file_main_version_number = fread(fid, 1, 'int16');
data_file_secondary_version_number = fread(fid, 1, 'int16');

fprintf(1, '\n');
fprintf(1, 'Reading Intan Technologies RHS2000 Data File, Version %d.%d\n', ...
    data_file_main_version_number, data_file_secondary_version_number);
fprintf(1, '\n');

num_samples_per_data_block = 128;

% Read information of sampling rate and amplifier frequency settings.
sample_rate = fread(fid, 1, 'single');
dsp_enabled = fread(fid, 1, 'int16');
actual_dsp_cutoff_frequency = fread(fid, 1, 'single');
actual_lower_bandwidth = fread(fid, 1, 'single');
actual_lower_settle_bandwidth = fread(fid, 1, 'single');
actual_upper_bandwidth = fread(fid, 1, 'single');

desired_dsp_cutoff_frequency = fread(fid, 1, 'single');
desired_lower_bandwidth = fread(fid, 1, 'single');
desired_lower_settle_bandwidth = fread(fid, 1, 'single');
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

amp_settle_mode = fread(fid, 1, 'int16');
charge_recovery_mode = fread(fid, 1, 'int16');

stim_step_size = fread(fid, 1, 'single');
charge_recovery_current_limit = fread(fid, 1, 'single');
charge_recovery_target_voltage = fread(fid, 1, 'single');

% Place notes in data strucure
notes = struct( ...
    'note1', fread_QString(fid), ...
    'note2', fread_QString(fid), ...
    'note3', fread_QString(fid) );
    
% See if dc amplifier data was saved
dc_amp_data_saved = fread(fid, 1, 'int16');

% Load eval board mode.
eval_board_mode = fread(fid, 1, 'int16');

reference_channel = fread_QString(fid);

% Place frequency-related information in data structure.
frequency_parameters = struct( ...
    'amplifier_sample_rate', sample_rate, ...
    'board_adc_sample_rate', sample_rate, ...
    'board_dig_in_sample_rate', sample_rate, ...
    'desired_dsp_cutoff_frequency', desired_dsp_cutoff_frequency, ...
    'actual_dsp_cutoff_frequency', actual_dsp_cutoff_frequency, ...
    'dsp_enabled', dsp_enabled, ...
    'desired_lower_bandwidth', desired_lower_bandwidth, ...
    'desired_lower_settle_bandwidth', desired_lower_settle_bandwidth, ...
    'actual_lower_bandwidth', actual_lower_bandwidth, ...
    'actual_lower_settle_bandwidth', actual_lower_settle_bandwidth, ...
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
board_adc_channels = struct(channel_struct);
board_dac_channels = struct(channel_struct);
board_dig_in_channels = struct(channel_struct);
board_dig_out_channels = struct(channel_struct);

amplifier_index = 1;
board_adc_index = 1;
board_dac_index = 1;
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
            new_channel(1).native_order = fread(fid, 1, 'int16');
            new_channel(1).custom_order = fread(fid, 1, 'int16');
            signal_type = fread(fid, 1, 'int16');
            channel_enabled = fread(fid, 1, 'int16');
            new_channel(1).chip_channel = fread(fid, 1, 'int16');
            fread(fid, 1, 'int16');  % ignore command_stream
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

fprintf(1, 'Found %d amplifier channel%s.\n', ...
    num_amplifier_channels, plural(num_amplifier_channels));
if (dc_amp_data_saved ~= 0)
    fprintf(1, 'Found %d DC amplifier channel%s.\n', ...
        num_amplifier_channels, plural(num_amplifier_channels));
end
fprintf(1, 'Found %d board ADC channel%s.\n', ...
    num_board_adc_channels, plural(num_board_adc_channels));
fprintf(1, 'Found %d board DAC channel%s.\n', ...
    num_board_dac_channels, plural(num_board_dac_channels));
fprintf(1, 'Found %d board digital input channel%s.\n', ...
    num_board_dig_in_channels, plural(num_board_dig_in_channels));
fprintf(1, 'Found %d board digital output channel%s.\n', ...
    num_board_dig_out_channels, plural(num_board_dig_out_channels));
fprintf(1, '\n');

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
bytes_remaining = filesize - ftell(fid);
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

    t = zeros(1, num_amplifier_samples);

    amplifier_data = zeros(num_amplifier_channels, num_amplifier_samples);
    if (dc_amp_data_saved ~= 0)
        dc_amplifier_data = zeros(num_amplifier_channels, num_amplifier_samples);
    end
    stim_data = zeros(num_amplifier_channels, num_amplifier_samples);
    amp_settle_data = zeros(num_amplifier_channels, num_amplifier_samples);
    charge_recovery_data = zeros(num_amplifier_channels, num_amplifier_samples);
    compliance_limit_data = zeros(num_amplifier_channels, num_amplifier_samples);
    board_adc_data = zeros(num_board_adc_channels, num_board_adc_samples);
    board_dac_data = zeros(num_board_dac_channels, num_board_dac_samples);
    board_dig_in_data = zeros(num_board_dig_in_channels, num_board_dig_in_samples);
    board_dig_in_raw = zeros(1, num_board_dig_in_samples);
    board_dig_out_data = zeros(num_board_dig_out_channels, num_board_dig_out_samples);
    board_dig_out_raw = zeros(1, num_board_dig_out_samples);

    % Read sampled data from file.
    fprintf(1, 'Reading data from file...\n');

    amplifier_index = 1;
    board_adc_index = 1;
    board_dac_index = 1;
    board_dig_in_index = 1;
    board_dig_out_index = 1;

    print_increment = 10;
    percent_done = print_increment;
    for i=1:num_data_blocks
        t(amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'int32');
        if (num_amplifier_channels > 0)
            amplifier_data(:, amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_amplifier_channels], 'uint16')';
            if (dc_amp_data_saved ~= 0)
                dc_amplifier_data(:, amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_amplifier_channels], 'uint16')';
            end
            stim_data(:, amplifier_index:(amplifier_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_amplifier_channels], 'uint16')';
        end
        if (num_board_adc_channels > 0)
            board_adc_data(:, board_adc_index:(board_adc_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_board_adc_channels], 'uint16')';
        end
        if (num_board_dac_channels > 0)
            board_dac_data(:, board_dac_index:(board_dac_index + num_samples_per_data_block - 1)) = fread(fid, [num_samples_per_data_block, num_board_dac_channels], 'uint16')';
        end
        if (num_board_dig_in_channels > 0)
            board_dig_in_raw(board_dig_in_index:(board_dig_in_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'uint16');
        end
        if (num_board_dig_out_channels > 0)
            board_dig_out_raw(board_dig_out_index:(board_dig_out_index + num_samples_per_data_block - 1)) = fread(fid, num_samples_per_data_block, 'uint16');
        end

        amplifier_index = amplifier_index + num_samples_per_data_block;
        board_adc_index = board_adc_index + num_samples_per_data_block;
        board_dac_index = board_dac_index + num_samples_per_data_block;
        board_dig_in_index = board_dig_in_index + num_samples_per_data_block;
        board_dig_out_index = board_dig_out_index + num_samples_per_data_block;

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
       mask = 2^(board_dig_in_channels(i).native_order) * ones(size(board_dig_in_raw));
       board_dig_in_data(i, :) = (bitand(board_dig_in_raw, mask) > 0);
    end
    for i=1:num_board_dig_out_channels
       mask = 2^(board_dig_out_channels(i).native_order) * ones(size(board_dig_out_raw));
       board_dig_out_data(i, :) = (bitand(board_dig_out_raw, mask) > 0);
    end

    % Scale voltage levels appropriately.
    amplifier_data = 0.195 * (amplifier_data - 32768); % units = microvolts
    if (dc_amp_data_saved ~= 0)
        dc_amplifier_data = -0.01923 * (dc_amplifier_data - 512); % units = volts
    end
    compliance_limit_data = stim_data >= 2^15;
    stim_data = stim_data - (compliance_limit_data * 2^15);
    charge_recovery_data = stim_data >= 2^14;
    stim_data = stim_data - (charge_recovery_data * 2^14);
    amp_settle_data = stim_data >= 2^13;
    stim_data = stim_data - (amp_settle_data * 2^13);
    stim_polarity = stim_data >= 2^8;
    stim_data = stim_data - (stim_polarity * 2^8);
    stim_polarity = 1 - 2 * stim_polarity; % convert (0 = pos, 1 = neg) to +/-1
    stim_data = stim_data .* stim_polarity;
    stim_data = stim_parameters.stim_step_size * stim_data / 1.0e-6; % units = microamps
    board_adc_data = 312.5e-6 * (board_adc_data - 32768); % units = volts
    board_dac_data = 312.5e-6 * (board_dac_data - 32768); % units = volts

    % Check for gaps in timestamps.
    num_gaps = sum(diff(t) ~= 1);
    if (num_gaps == 0)
        fprintf(1, 'No missing timestamps in data.\n');
    else
        fprintf(1, 'Warning: %d gaps in timestamp data found.  Time scale will not be uniform!\n', ...
            num_gaps);
    end

    % Scale time steps (units = seconds).
    t = t / sample_rate;

end

% Save Data.
temppath = strsplit(path, filesep);
tankpath = strjoin(temppath(1:end-2), '/');
blockname = temppath{end-1};

info_head = {'tankpath','blockname','notes','frequency_pars','stim_parameters','spike_triggers'};
info_data = {tankpath,blockname,notes,frequency_parameters,stim_parameters,spike_triggers};

if (data_file_main_version_number > 1)
    info_head(end + 1) = {'reference_channel'};
    info_data(end + 1) = {reference_channel};
end

info = cell2struct(info_data,info_head,2);
save(fullfile(paths.R,[Animal '_' Rec '_GenInfo.mat']),'info','gitInfo','-v7.3');

if (num_amplifier_channels > 0)
    RW_info = amplifier_channels;
    paths.RW = strrep(paths.RW, '\', '/');
    infoname = fullfile(paths.RW,[Animal '_' Rec '_RawWave_Info.mat']);
    save(infoname,'RW_info','gitInfo','-v7.3');
    if (data_present)

        % Determine CAR ref for each probe
        probes = unique([amplifier_channels.port_number]);
        probe_ref = zeros(numel(probes),size(amplifier_data,2));
        hold_filt = zeros(size(amplifier_data));
        
        % Get filter specs
        FS = sample_rate;  % Sampling Frequency
        
        if STATE_FILTER
           filtspecs = struct('FS',FS,...
                              'FPASS1',FPASS1,...
                              'FTYPE','HARDWARE_STATE_HIGHPASS');
        else
           filtspecs = struct( ...
               'FS', FS, ...
               'FSTOP1', FSTOP1, ...
               'FPASS1', FPASS1, ...
               'FPASS2', FPASS2, ...
               'FSTOP2', FSTOP2, ...
               'ASTOP1', ASTOP1, ...
               'APASS', APASS, ...
               'ASTOP2', ASTOP2, ...
               'MATCH', MATCH,...
               'FTYPE', 'CUSTOM_FIR_BANDPASS');
            [~, bpFilt] = BandPassFilt('FS', FS, ...
                                       'FSTOP1', FSTOP1, ...
                                       'FPASS1', FPASS1, ...
                                       'FPASS2', FPASS2, ...
                                       'FSTOP2', FSTOP2, ...
                                       'ASTOP1', ASTOP1, ...
                                       'APASS',  APASS, ...
                                       'ASTOP2', ASTOP2, ...
                                       'MATCH', MATCH);
        end
        
        % Save amplifier_data by probe/channel
        paths.RW_N = strrep(paths.RW_N, '\', '/');
        for iCh = 1:num_amplifier_channels
            pnum  = num2str(amplifier_channels(iCh).port_number);
            chnum = amplifier_channels(iCh).custom_channel_name(regexp(amplifier_channels(iCh).custom_channel_name, '\d'));
            fname = sprintf(paths.RW_N, pnum, chnum); 
            data = single(amplifier_data(iCh,:));
            fs = sample_rate;
            save(fname,'data','fs','gitInfo','-v7.3');
            
            if ~STIM_SUPPRESS
               % Filter and and save amplifier_data by probe/channel
               paths.FW = strrep(paths.FW, '\', '/');
               paths.FW_N = strrep(paths.FW_N, '\', '/');
               paths.CARW_N = strrep(paths.CARW_N, '\', '/');

               if iCh == 1
                   filt_infoname = fullfile(paths.FW,[Animal '_' Rec '_Filtspecs.mat']);
                   save(filt_infoname,'filtspecs','gitInfo','-v7.3');
               end

               % Filter and and save amplifier_data by probe/channel
               if STATE_FILTER
                  data = single(HPF(double(amplifier_data(iCh,:)),FPASS1,fs));
               else
                  data = single(filtfilt(bpFilt,double(amplifier_data(iCh,:))));    %#ok<UNRCH>
               end
               hold_filt(iCh,:) = data;
               fname = sprintf(paths.FW_N, pnum, chnum);
               save(fname,'data','fs','gitInfo','-v7.3');
            end
            clear data
                        
            if (dc_amp_data_saved ~= 0)
                if ~exist(fullfile(paths.DW,'DC_AMP'),'dir')
                    mkdir(fullfile(paths.DW,'DC_AMP'))
                end
                dc_amp_fname = strrep(fullfile(paths.DW,'DC_AMP',[Animal '_' Rec '_DCAMP_P%s_Ch_%s.mat']),'\','/');
                fname = sprintf(dc_amp_fname, pnum, chnum); 
                data = single(dc_amplifier_data(iCh,:));
                save(fname,'data','fs','gitInfo','-v7.3');
            end

            if ~exist(fullfile(paths.DW,'STIM_DATA'),'dir')
                mkdir(fullfile(paths.DW,'STIM_DATA'))
            end
            stim_data_fname = strrep(fullfile(paths.DW,'STIM_DATA',[Animal '_' Rec '_STIM_P%s_Ch_%s.mat']),'\','/');
            fname = sprintf(stim_data_fname, pnum, chnum); 
            data = single(stim_data(iCh,:));
            save(fname,'data','fs','gitInfo','-v7.3');

            as_data_fname = strrep(fullfile(paths.DW,'STIM_DATA',[Animal '_' Rec '_ASD_P%s_Ch_%s.mat']),'\','/');
            fname = sprintf(as_data_fname, pnum, chnum); 
            data = single(amp_settle_data(iCh,:));
            save(fname,'data','fs','gitInfo','-v7.3');

            cr_data_fname = strrep(fullfile(paths.DW,'STIM_DATA',[Animal '_' Rec '_CRD_P%s_Ch_%s.mat']),'\','/');
            fname = sprintf(cr_data_fname, pnum, chnum); 
            data = single(charge_recovery_data(iCh,:));
            save(fname,'data','fs','gitInfo','-v7.3');

            cl_data_fname = strrep(fullfile(paths.DW,'STIM_DATA',[Animal '_' Rec '_CLD_P%s_Ch_%s.mat']),'\','/');
            fname = sprintf(cl_data_fname, pnum, chnum); 
            data = single(compliance_limit_data(iCh,:));
            save(fname,'data','fs','gitInfo','-v7.3');
        end
        
        % Save amplifier_data CAR by probe/channel
        if ~STIM_SUPPRESS
           for iPb = 1:numel(probes)
               probe_ref(iPb,:) = mean(hold_filt([amplifier_channels.port_number] == probes(iPb),:),1);
           end

           for iCh = 1:num_amplifier_channels
               pnum  = num2str(amplifier_channels(iCh).port_number);
               chnum = amplifier_channels(iCh).custom_channel_name(regexp(amplifier_channels(iCh).custom_channel_name, '\d'));

               if iCh == 1
                   car_infoname = fullfile(paths.CARW,[Animal '_' Rec '_CAR_Ref.mat']);
                   save(car_infoname,'probe_ref','gitInfo','-v7.3');
               end

               fname = sprintf(paths.CARW_N, pnum, chnum);
               data = single(hold_filt(iCh,:) - probe_ref(amplifier_channels(iCh).port_number,:));
               save(fname,'data','fs','gitInfo','-v7.3');
           end
        end
    end
end

% Save single-channel adc data
if (num_board_adc_channels > 0)
   if exist('fs','var')==0
      fs = 30000;
   end
    ADC_info = board_adc_channels;
    paths.DW = strrep(paths.DW, '\', '/');
    infoname = fullfile(paths.DW,[Animal '_' Rec '_ADC_Info.mat']);
    save(infoname,'ADC_info','gitInfo','-v7.3');
    if (data_present)
        for i = 1:num_board_adc_channels
            paths.DW_N = strrep(paths.DW_N, '\', '/');
            fname = sprintf(paths.DW_N, board_adc_channels(i).custom_channel_name); 
            data = single(board_adc_data(i,:));           
            save(fname,'data','fs','gitInfo','-v7.3');            
        end
    end
end

% Save single-channel dac data
if (num_board_dac_channels > 0)
    DAC_info = board_dac_channels;
    paths.DW = strrep(paths.DW, '\', '/');
    infoname = fullfile(paths.DW,[Animal '_' Rec '_DAC_Info.mat']);
    save(infoname,'DAC_info','gitInfo','-v7.3');
    if (data_present)
        for i = 1:num_board_dac_channels
            paths.DW_N = strrep(paths.DW_N, '\', '/');
            fname = sprintf(paths.DW_N, board_dac_channels(i).custom_channel_name); 
            data = single(board_dac_data(i,:));           
            save(fname,'data','fs','gitInfo','-v7.3');            
        end
    end
end

% Save single-channel digital input data
if (num_board_dig_in_channels > 0)
    DigI_info = board_dig_in_channels;
    paths.DW = strrep(paths.DW, '\', '/');
    infoname = fullfile(paths.DW,[Animal '_' Rec '_Digital_Input_Info.mat']);
    save(infoname,'DigI_info','gitInfo','-v7.3');
    if (data_present)
        for i = 1:num_board_dig_in_channels
            paths.DW_N = strrep(paths.DW_N, '\', '/');
            fname = sprintf(paths.DW_N, board_dig_in_channels(i).custom_channel_name); 
            data = single(board_dig_in_data(i,:));           
            save(fname,'data','fs','gitInfo','-v7.3');            
        end
    end
end

% Save single-channel digital output data
if (num_board_dig_out_channels > 0)
    DigO_info = board_dig_out_channels;
    paths.DW = strrep(paths.DW, '\', '/');
    infoname = fullfile(paths.DW,[Animal '_' Rec '_Digital_Output_Info.mat']);
    save(infoname,'DigO_info','gitInfo','-v7.3');
    if (data_present)
        for i = 1:num_board_dig_out_channels
            fname = sprintf(paths.DW_N, board_dig_out_channels(i).custom_channel_name); 
            data = single(board_dig_out_data(i,:));           
            save(fname,'data','fs','gitInfo','-v7.3');            
        end
    end
end

if STIM_SUPPRESS
   reFilter_Stims(STIM_P_CH,(1),STIM_P_CH(2),...
      'DIR',strrep(paths.A,UNC_PATH,filesep),...
      'USE_CLUSTER',true,...
      'STIM_BLANK',STIM_BLANK);
end

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


