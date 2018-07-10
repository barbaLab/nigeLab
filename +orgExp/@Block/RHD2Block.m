function RHD2Block(tankObj,varargin)
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

FID = fopen(NAME, 'r');
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

header=RHD_read_header('FID',FID);


% Close data file.
fclose(FID);

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
