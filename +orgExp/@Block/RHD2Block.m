function RHS2Block(blockObj,varargin)
%% INTANRHS2BLOCK  Convert Intan RHD or RHS to Matlab BLOCK format
%
%  tankObj.INTANRHS2BLOCK;
%  INTANRHS2BLOCK(tankObj,'NAME',value,...);
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PARSE VARARGIN
for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) ' = varargin{iV+1};']);
end

if exist('GITINFO','var')
    gitInfo = GITINFO; clear GITINFO %#ok<*NASGU>
else
    gitInfo = NaN;
end

[path,file,~] = fileparts(blockObj.PATH);

tic;
fid = fopen(blockObj.PATH, 'r');
s = dir(blockObj.PATH);
filesize = s.bytes;

Animal = blockObj.Corresponding_animal;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read the file header

header = orgExp.libs.RHD_read_header('FID',fid);

% this is lazyness at its best, I should go through the code and change
% each variable that was inserted in the header structure to header.variable
% but I'm to lazy to do that

FIELDS=fields(header);
for ii=1:numel(FIELDS)
    eval([FIELDS{ii} '=header.(FIELDS{ii});']);
end

%% Start data conversion

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Pre-allocate memory for data.
%% Uses matfiles to avoid out of memory conditions
% preallocates matfiles for varible that otherwise would require
% nChannles*nSamples matrices

if (data_present)
    fprintf(1, 'Allocating memory for data...\n');
    
    if (num_amplifier_channels > 0)
        RW_info = amplifier_channels;
        infoname = fullfile(strrep(blockObj.paths.RW,'\','/'),[blockObj.Name '_RawWave_Info.mat']);
        save(fullfile(infoname),'RW_info','gitInfo','-v7.3');
        % One file per probe and channel
        for iCh = 1:num_amplifier_channels
            pnum  = num2str(amplifier_channels(iCh).port_number);
            chnum = amplifier_channels(iCh).custom_channel_name(regexp(amplifier_channels(iCh).custom_channel_name, '\d'));
            fname = sprintf(strrep(blockObj.paths.RW_N,'\','/'), pnum, chnum);
            amplifier_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                'class','single','size',[1 num_amplifier_samples]);
        end
    end
    
    % Save single-channel adc data
    if (num_board_adc_channels > 0)
        ADC_info = board_adc_channels;
        infoname = fullfile(strrep(blockObj.paths.DW,'\','/'),[blockObj.Name '_ADC_Info.mat']);
        save(fullfile(infoname),'ADC_info','gitInfo','-v7.3');
        if (data_present)
            for iCh = 1:num_board_adc_channels
                chnum = board_adc_channels(iCh).custom_channel_name;
                fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'),chnum);
                board_adc_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                    'class','single','size',[1 num_board_adc_samples]);
            end
        end
    end
    
    % Save single-channel supply_voltage data
    if (num_supply_voltage_channels > 0)
        supply_voltage_info = supply_voltage_channels;
        infoname = fullfile(strrep(blockObj.paths.DW,'\','/'),[blockObj.Name '_supply_voltage_info.mat']);
        save(fullfile(infoname),'supply_voltage_info','-v7.3');
            for iCh = 1:num_supply_voltage_channels
                chnum = supply_voltage_channels(iCh).custom_channel_name;
                fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'),chnum);
                supply_voltage_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                    'class','single','size',[1 num_supply_voltage_samples]);
            end        
    end
    
        % Save single-channel temperature data
    if (num_temp_sensor_channels > 0)
        temp_sensor_info = temp_sensor_channels;
        infoname = fullfile(strrep(blockObj.paths.DW, '\', '/'),[blockObj.Name '_temp_sensor_info.mat']);
        save(fullfile(infoname),'temp_sensor_info','-v7.3');
            for iCh = 1:num_temp_sensor_channels
                blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
                chnum = temp_sensor_channels(iCh).custom_channel_name;
                fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'),chnum);
                supply_voltage_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                    'class','single','size',[1 num_temp_sensor_samples]);
            end        
    end
    
     % Save single-channel aux-in data
    if (num_aux_input_channels > 0)
        AUX_info = aux_input_channels;
        infoname = fullfile(strrep(blockObj.paths.DW, '\', '/'),[blockObj.Name '_AUX_Info.mat']);
        save(fullfile(infoname),'AUX_info','-v7.3');
            for iCh = 1:num_aux_input_channels
                chnum = aux_input_channels(iCh).custom_channel_name;
                fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), chnum);
                aux_input_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                    'class','single','size',[1 num_aux_input_samples]);
            end        
    end
    
    % Save single-channel digital input data
    if (num_board_dig_in_channels > 0)
        DigI_info = board_dig_in_channels;
        infoname = fullfile(strrep(blockObj.paths.DW, '\', '/'),[blockObj.Name '_Digital_Input_Info.mat']);
        save(fullfile(infoname),'DigI_info','gitInfo','-v7.3');
        if (data_present)
            for iCh = 1:num_board_dig_in_channels
                blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
                chnum = board_dig_in_channels(iCh).custom_channel_name;
                fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), chnum);
                board_dig_in_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                'class','uint8','size',[1 num_board_dig_in_samples]);
            end
        end
    end
    
    
    % Save single-channel digital output data
    if (num_board_dig_out_channels > 0)
        DigO_info = board_dig_out_channels;
        infoname = fullfile(strrep(blockObj.paths.DW, '\', '/'),[blockObj.Name '_Digital_Output_Info.mat']);
        save(fullfile(infoname),'DigO_info','gitInfo','-v7.3');
        if (data_present)
            for iCh = 1:num_board_dig_out_channels
                chnum = board_dig_out_channels(iCh).custom_channel_name;
                fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'),chnum);
                board_dig_out_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                    'class','uint8','size',[1 num_board_dig_out_samples]);
                %                 board_dig_out_dataFile{i}.gitInfo = gitInfo;
            end
        end
    end
    fprintf(1,'Matfiles created succesfully\n');
    fprintf(1,'Exporting files...\n');
    fprintf(1,'%.3d%%',0)
    
    % We need 5 buffer viarables to read data from file and save it into a
    % matlab friendly forma using matfiles. Those varibles needs to be as
    % big as possible to speed up the process. in order to do that we will
    % alocate 4/5 of the available memory to those variables.
    
%     nDataPoints=num_samples_per_data_block*2;   %time
%     if (num_amplifier_channels > 0)
%         nDataPoints=nDataPoints+num_samples_per_data_block * num_amplifier_channels;    %amplifier_data
%         if (dc_amp_data_saved ~= 0)
%             nDataPoints=nDataPoints+num_samples_per_data_block * num_amplifier_channels;    %dc_amplifier_data
%         end
%         nDataPoints=nDataPoints+num_samples_per_data_block * num_amplifier_channels;    %stim_data
%     end
%     
%     if (num_board_adc_channels > 0)
%         nDataPoints=nDataPoints+num_samples_per_data_block * num_board_adc_channels; %board_adc_data
%     end
%     
%     if (num_board_dac_channels > 0)
%         nDataPoints=nDataPoints+num_samples_per_data_block * num_board_dac_channels;    %board_dac_data
%     end
%     
%     if (num_board_dig_in_channels > 0)
%         nDataPoints=nDataPoints+num_samples_per_data_block * num_board_dig_in_channels; %board_dig_in_raw
%     end
%     
%     if (num_board_dig_out_channels > 0)
%         nDataPoints=nDataPoints+num_samples_per_data_block * num_board_dig_out_channels; %board_dig_out_raw
%     end
    
    nDataPoints=bytes_per_block/2; % reading uint16

    
    time_buffer_index = false(1,nDataPoints);
    amplifier_buffer_index = zeros(1,nDataPoints,'uint16');
    supply_voltage_buffer_index = zeros(1,nDataPoints,'uint16');
    temp_buffer_index = zeros(1,nDataPoints,'uint16');
    aux_in_buffer_index = zeros(1,nDataPoints,'uint16');
    adc_buffer_index = zeros(1,nDataPoints,'uint16');
    dig_in_buffer_index = false(1,nDataPoints);
    dig_out_buffer_index = false(1,nDataPoints);
    
    if ~isunix
    [~,MEM]=memory;
     AvailableMemory=MEM.PhysicalMemory.Available*0.8;
    else
        AvailableMemory=2147483648;
    end
    nBlocks=min(num_data_blocks,floor(AvailableMemory/nDataPoints/(8+13))); %13 accounts for all the indexings
    %     t = zeros(1, num_samples_per_data_block);
    
    time_buffer_index(1:num_samples_per_data_block*2)=true;
    end_=num_samples_per_data_block*2;
    time_buffer_index=repmat(time_buffer_index,1,nBlocks);
    
    if (num_amplifier_channels > 0)
        index=end_+1:end_+num_samples_per_data_block * num_amplifier_channels;
        end_=index(end);
        amplifier_buffer_index(index)=uint16(reshape(repmat(1:num_amplifier_channels,num_samples_per_data_block,1),1,[]));
        amplifier_buffer_index=repmat(amplifier_buffer_index,1,nBlocks);
    end
    
    if (num_aux_input_channels > 0)
        index=end_+1:end_+num_samples_per_data_block * num_amplifier_channels;
        end_=index(end);
        aux_in_buffer_index(index)=uint16(reshape(repmat(1:num_amplifier_channels,num_samples_per_data_block,1),1,[]));
        aux_in_buffer_index=repmat(aux_in_buffer_index,1,nBlocks);
    end
    
    if (num_supply_voltage_channels > 0)
        index=end_+1:end_+num_samples_per_data_block * num_amplifier_channels;
        end_=index(end);
        supply_voltage_buffer_index(index)=uint16(reshape(repmat(1:num_amplifier_channels,num_samples_per_data_block,1),1,[]));
        supply_voltage_buffer_index=repmat(supply_voltage_buffer_index,1,nBlocks);
    end
    
    if (num_temp_sensor_channels > 0)
        index=end_+1:end_+num_samples_per_data_block * num_board_dac_channels;
        end_=index(end);
        temp_buffer_index(index)=uint16(reshape(repmat(1:num_board_dac_channels,num_samples_per_data_block,1),1,[]));
        temp_buffer_index=repmat(temp_buffer_index,1,nBlocks);
    end

    
    if (num_board_adc_channels > 0)
        index=end_+1:end_+num_samples_per_data_block * num_board_adc_channels;
        end_=index(end);
        adc_buffer_index(index)=uint16(reshape(repmat(1:num_board_adc_channels,num_samples_per_data_block,1),1,[]));
        adc_buffer_index=repmat(adc_buffer_index,1,nBlocks);
        
    end
        
    if (num_board_dig_in_channels > 0)
        index=end_+1:end_+num_samples_per_data_block * 1;
        end_=index(end);
        dig_in_buffer_index(index)=true;
        dig_in_buffer_index=repmat(dig_in_buffer_index,1,nBlocks);
        
    end
    
    if (num_board_dig_out_channels > 0)
        index=end_+1:end_+num_samples_per_data_block * 1;
        end_=index(end);
        dig_out_buffer_index(index)=true;
        dig_out_buffer_index=repmat(dig_out_buffer_index,1,nBlocks);
        
    end
    
    %     amplifier_data = zeros(num_amplifier_channels, nBlocks * num_samples_per_data_block);
    %     if (dc_amp_data_saved ~= 0)
    %         dc_amplifier_data = zeros(num_amplifier_channels, nBlocks * num_samples_per_data_block);
    %     end
    %     stim_data = zeros(num_amplifier_channels, nBlocks * num_samples_per_data_block);
    %     amp_settle_data = false(num_amplifier_channels, num_amplifier_samples);
    %     charge_recovery_data = false(num_amplifier_channels, num_amplifier_samples);
    %     compliance_limit_data = false(num_amplifier_channels, num_amplifier_samples);
    %
    %     board_adc_data = zeros(num_board_adc_channels, nBlocks * num_samples_per_data_block);
    %     board_dac_data = zeros(num_board_dac_channels, nBlocks * num_samples_per_data_block);
    %     board_dig_in_raw = zeros(1, num_board_dig_out_samples);
    %     board_dig_out_raw = zeros(1, num_board_dig_out_samples);
    
    
    progress=0;
    num_gaps = 0;
    index = 0;
    
    for i=1:ceil(num_data_blocks/nBlocks)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Read binary data.
        blocksToread = min(nBlocks,num_data_blocks-nBlocks*(i-1));
        dataToRead = blocksToread*nDataPoints;
        Buffer=uint16(fread(fid, dataToRead, 'uint16'))';        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Update the files
        index =uint32( index(end) + 1 : index(end)+num_samples_per_data_block*blocksToread);
        
        t=Buffer(time_buffer_index(1:dataToRead));
        tmp=dec2bin(t,16);
        t=bin2dec([tmp(2:2:end,:) tmp(1:2:end,:)]);  % time is sampled as 32bit integer, the file is read as 16 bit integer. This takes care of the conversion
        
        num_gaps = num_gaps + sum(diff(t) ~= 1);
        
        % Scale time steps (units = seconds).
%         blockObj.Time = [ blockObj.Time float(t) ./ sample_rate];
        clear('t');
        % Write data to file
        for jj=1:num_amplifier_channels
            amplifier_dataFile{jj}.append(single(Buffer(amplifier_buffer_index(1:dataToRead)==jj)));
        end
        
        for jj=1:num_aux_input_channels
            aux_input_dataFile{jj}.append(single(Buffer(aux_in_buffer_index(1:dataToRead)==jj)));
        end
        for jj=1:num_supply_voltage_channels
            supply_voltage_dataFile{jj}.append(single(Buffer(supply_voltage_buffer_index(1:dataToRead)==jj)));
        end
        for jj=1:num_temp_sensor_channels
            temp_sensor_dataFile{jj}.append(single(Buffer(temp_buffer_index(1:dataToRead)==jj)));
        end
        
        for jj=1:num_board_adc_channels
            board_adc_dataFile{jj}.append(single(Buffer(adc_buffer_index(1:dataToRead)==jj)));
        end
        
        if num_board_dig_in_channels
            dig_in_raw=Buffer(dig_in_buffer_index(1:dataToRead));
            for jj=1:num_board_dig_in_channels
                mask = uint16(2^(board_dig_in_channels(jj).native_order) * ones(size(dig_in_raw)));
                board_dig_in_dataFile{jj}.append(int8(bitand(dig_in_raw, mask) > 0));
            end
        end

        if num_board_dig_out_channels
            dig_out_raw=Buffer(dig_out_buffer_index(1:dataToRead));
            for jj=1:num_board_dig_out_channels
                mask =uint16( 2^(board_dig_out_channels(jj).native_order) * ones(size(dig_out_raw)));
                board_dig_out_dataFile{jj}.append(int8(bitand(dig_out_raw, mask) > 0));
            end
        end
        
        progress=progress+min(nBlocks,num_data_blocks-nBlocks*(i-1));
        fraction_done = 100 * (progress / num_data_blocks);
%         if ~floor(mod(fraction_done,5)) % only increment counter by 5%
            fprintf(1,'\b\b\b\b%.3d%%',floor(fraction_done))
%         end
    end
    fprintf(1,newline);
    
    % Make sure we have read exactly the right amount of data.
    bytes_remaining = filesize - ftell(fid);
    if (bytes_remaining ~= 0)
        warning('Error: End of file not reached.');
    end
end
T1=toc;
% Close data file.
fclose(fid);

if (data_present)
    
    fprintf(1, 'Parsing data...\n');
    
    % Scaling variables appropriatly.
    for jj=1:num_amplifier_channels
       
        % Scale voltage levels appropriately.
        amplifier_dataFile{jj}(:) = 0.195 * (single(amplifier_dataFile{jj}) - 32768); % units = microvolts

    end
    for jj=1:num_aux_input_channels
        aux_input_dataFile{jj}(:) = 37.4e-6 *  single(aux_input_dataFile{jj}); % units = volts
    end
    
    for jj=1:num_supply_voltage_channels
        supply_voltage_dataFile{jj} = 74.8e-6 * single(supply_voltage_dataFile{jj}); % units = volts
    end
    
    for jj=1:num_board_adc_channels
        if (eval_board_mode == 1)
            board_adc_dataFile{jj}(:) = 152.59e-6 * (single(board_adc_dataFile{jj}) - 32768); % units = volts
        elseif (eval_board_mode == 13) % Intan Recording Controller
            board_adc_dataFile{jj}(:) = 312.5e-6 * (single(board_adc_dataFile{jj}) - 32768); % units = volts
        else
            board_adc_dataFile{jj}(:) = 50.354e-6 * single(board_adc_dataFile{jj}); % units = volts
        end
    end
    
    for jj=1:num_temp_sensor_channels
        temp_sensor_dataFile{jj}(:) =  single(temp_sensor_dataFile{jj}) ./ 100; % units = deg C
    end
    
    % Check for gaps in timestamps.
    if (num_gaps == 0)
        fprintf(1, 'No missing timestamps in data.\n');
    else
        fprintf(1, 'Warning: %d gaps in timestamp data found.  Time scale will not be uniform!\n', ...
            num_gaps);
    end
    %% Linking data to blokObj
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DiskData makes it easy to access data stored in matfies.
    % Assigning each file to the right channel
    for iCh=1:num_amplifier_channels
        blockObj.Channels(iCh).rawData = amplifier_dataFile{iCh};
    end
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


