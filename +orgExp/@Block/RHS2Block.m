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

% if exist('NAME', 'var') == 0
%
%     [file, path, ~] = ...
%         uigetfile('*.rhs', 'Select an RHS2000 Data File', ...
%             DEFTANK, ...
%             'MultiSelect', 'off');
%
%     if (file == 0)
%         error('Must select a valid RHS2000 Data File.');
%     end
%
%     NAME = [path, file];
%     file = file(1:end-4); %remove extension
% else    % If a pre-specified path exists, must be a valid path.
%
%     if NAME == 0 %#ok<*NODEF> % Must select a directory
%         error('Must provide a valid RHS2000 Data File and Path.');
%         return %#ok<UNRCH>
%     end
%
[path,file,~] = fileparts(blockObj.PATH);

% end

tic;
fid = fopen(blockObj.PATH, 'r');
s = dir(blockObj.PATH);
filesize = s.bytes;

Animal = blockObj.Corresponding_animal;
% if numel(temp)>5
%     Rec = strjoin(temp(2:5),'_'); clear temp
% else
%     Rec = strjoin(temp(2:end),'_');
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read the file header

header = orgExp.libs.RHS_read_header('FID',fid);

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
    RW_info = amplifier_channels;
    blockObj.paths.RW=strrep(blockObj.paths.RW,'\','/');
    infoname = fullfile(blockObj.paths.RW,[blockObj.Name '_RawWave_Info.mat']);
    save(fullfile(infoname),'RW_info','gitInfo','-v7.3');
    
    
    % One file per probe and channel
    for iCh = 1:num_amplifier_channels
        pnum  = num2str(amplifier_channels(iCh).port_number);
        chnum = amplifier_channels(iCh).custom_channel_name(regexp(amplifier_channels(iCh).custom_channel_name, '\d'));
        fname = sprintf(strrep(blockObj.paths.RW_N,'\','/'), pnum, chnum);
        amplifier_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                'class','single','size',[1 num_amplifier_samples]);
        
        stim_data_fname = strrep(fullfile(blockObj.paths.DW,'STIM_DATA',[blockObj.Name '_STIM_P%s_Ch_%s.mat']),'\','/');
        fname = sprintf(strrep(stim_data_fname,'\','/'), pnum, chnum);
        stim_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                'class','single','size',[1 num_amplifier_samples]);
        
        if (dc_amp_data_saved ~= 0)            
            dc_amp_fname = strrep(fullfile(blockObj.paths.DW,'DC_AMP',[blockObj.Name '_DCAMP_P%s_Ch_%s.mat']),'\','/');
            fname = sprintf(strrep(dc_amp_fname,'\','/'), pnum, chnum);
            dc_amplifier_dataFile{iCh} =  orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                'class','single','size',[1 num_amplifier_samples]);
        end
    end
    
    % Save single-channel adc data
    if (num_board_adc_channels > 0)
        ADC_info = board_adc_channels;
        blockObj.paths.DW = strrep(blockObj.paths.DW, '\', '/');
        infoname = fullfile(blockObj.paths.DW,[blockObj.Name '_ADC_Info.mat']);
        save(fullfile(infoname),'ADC_info','gitInfo','-v7.3');
        if (data_present)
            for i = 1:num_board_adc_channels
                blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
                fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), board_adc_channels(i).custom_channel_name);
                board_adc_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                'class','single','size',[1 num_board_adc_samples]);
            end
        end
    end
    
    % Save single-channel dac data
    if (num_board_dac_channels > 0)
        DAC_info = board_dac_channels;
        blockObj.paths.DW = strrep(blockObj.paths.DW, '\', '/');
        infoname = fullfile(blockObj.paths.DW,[blockObj.Name '_DAC_Info.mat']);
        save(fullfile(infoname),'DAC_info','gitInfo','-v7.3');
        if (data_present)
            for i = 1:num_board_dac_channels
                blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
                fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), board_dac_channels(i).custom_channel_name);
                board_dac_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                'class','single','size',[1 num_board_dac_samples]);
            end
        end
    end
    
    % Save single-channel digital input data
    if (num_board_dig_in_channels > 0)
        DigI_info = board_dig_in_channels;
        blockObj.paths.DW = strrep(blockObj.paths.DW, '\', '/');
        infoname = fullfile(blockObj.paths.DW,[blockObj.Name '_Digital_Input_Info.mat']);
        save(fullfile(infoname),'DigI_info','gitInfo','-v7.3');
        if (data_present)
            for i = 1:num_board_dig_in_channels
                fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), board_dig_in_channels(i).custom_channel_name);
                board_dig_in_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                'class','uint8','size',[1 num_board_dig_in_samples]);
            end
        end
    end
    
    
    % Save single-channel digital output data
    if (num_board_dig_out_channels > 0)
        DigO_info = board_dig_out_channels;
        blockObj.paths.DW = strrep(blockObj.paths.DW, '\', '/');
        infoname = fullfile(blockObj.paths.DW,[blockObj.Name '_Digital_Output_Info.mat']);
        save(fullfile(infoname),'DigO_info','gitInfo','-v7.3');
        if (data_present)
            for i = 1:num_board_dig_out_channels
                fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), board_dig_out_channels(i).custom_channel_name);
                board_dig_out_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),...
                'class','uint8','size',[1 num_board_dig_out_samples]);
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
    amplifier_buffer_index = zeros(1,nDataPoints,'uint8');
    dc_amplifier_buffer_index = zeros(1,nDataPoints,'uint8');
    stim_buffer_index = zeros(1,nDataPoints,'uint8');
    adc_buffer_index = zeros(1,nDataPoints,'uint8');
    dac_buffer_index = zeros(1,nDataPoints,'uint8');
    dig_in_buffer_index = false(1,nDataPoints);
    dig_out_buffer_index = false(1,nDataPoints);
    
    if ~isunix
    [~,MEM]=memory;
     AvailableMemory=MEM.PhysicalMemory.Available*0.8;
    else
        AvailableMemory=2147483648;
    end
    % Each block counts like 10 : 8 indexes uint8 and the readings uint16
    nBlocks=min(num_data_blocks,floor(AvailableMemory/bytes_per_block/(9))); 
    %     t = zeros(1, num_samples_per_data_block);
    
    time_buffer_index(1:num_samples_per_data_block*2)=true;
    end_=num_samples_per_data_block*2;
    time_buffer_index=repmat(time_buffer_index,1,nBlocks);
    
    if (num_amplifier_channels > 0)
        index=end_+1:end_+num_samples_per_data_block * num_amplifier_channels;
        end_=index(end);
        amplifier_buffer_index(index)=uint16(reshape(repmat(1:num_amplifier_channels,num_samples_per_data_block,1),1,[]));
        amplifier_buffer_index=repmat(amplifier_buffer_index,1,nBlocks);
        
        if (dc_amp_data_saved ~= 0)
            index=end_+1:end_+num_samples_per_data_block * num_amplifier_channels;
            end_=index(end);
            dc_amplifier_buffer_index(index)=uint16(reshape(repmat(1:num_amplifier_channels,num_samples_per_data_block,1),1,[]));
            dc_amplifier_buffer_index=repmat(dc_amplifier_buffer_index,1,nBlocks);
        end
        index=end_+1:end_+num_samples_per_data_block * num_amplifier_channels;
        end_=index(end);
        stim_buffer_index(index)=uint16(reshape(repmat(1:num_amplifier_channels,num_samples_per_data_block,1),1,[]));
        stim_buffer_index=repmat(stim_buffer_index,1,nBlocks);
        
    end
    
    if (num_board_adc_channels > 0)
        index=end_+1:end_+num_samples_per_data_block * num_board_adc_channels;
        end_=index(end);
        adc_buffer_index(index)=uint16(reshape(repmat(1:num_board_adc_channels,num_samples_per_data_block,1),1,[]));
        adc_buffer_index=repmat(adc_buffer_index,1,nBlocks);
        
    end
    
    if (num_board_dac_channels > 0)
        index=end_+1:end_+num_samples_per_data_block * num_board_dac_channels;
        end_=index(end);
        dac_buffer_index(index)=uint16(reshape(repmat(1:num_board_dac_channels,num_samples_per_data_block,1),1,[]));
        dac_buffer_index=repmat(dac_buffer_index,1,nBlocks);
        
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
        Buffer=uint16(fread(fid, dataToRead, 'uint16=>uint16'))';        
        
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
            amplifier_dataFile{jj}.append( single(Buffer(amplifier_buffer_index(1:dataToRead)==jj)));
            if (dc_amp_data_saved ~= 0)
                dc_amplifier_dataFile{jj}.append( single(Buffer(dc_amplifier_buffer_index(1:dataToRead)==jj)) );
            end
            stim_dataFile{jj}.append ( single(Buffer(stim_buffer_index(1:dataToRead)==jj)) );
        end
        
        for jj=1:num_board_adc_channels
            board_adc_dataFile{jj}.append ( single(Buffer(adc_buffer_index(1:dataToRead)==jj)) );
        end
        
        for jj=1:num_board_dac_channels
            board_dac_dataFile{jj}.append( single(Buffer(dac_buffer_index(1:dataToRead)==jj)) );
        end
        
        if num_board_dig_in_channels
            dig_in_raw=Buffer(dig_in_buffer_index(1:dataToRead));
            for jj=1:num_board_dig_in_channels
                mask = uint16(2^(board_dig_in_channels(jj).native_order) * ones(size(dig_in_raw)));
                board_dig_in_dataFile{jj}.append( uint8(bitand(dig_in_raw, mask) > 0));
            end
        end

        if num_board_dig_out_channels
            dig_out_raw=Buffer(dig_out_buffer_index(1:dataToRead));
            for jj=1:num_board_dig_out_channels
                mask =uint16( 2^(board_dig_out_channels(jj).native_order) * ones(size(dig_out_raw)));
                board_dig_out_dataFile{jj}.append( uint8(bitand(dig_out_raw, mask) > 0));
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
    
    compliance_limit_data = false(num_amplifier_channels,num_amplifier_samples);
    charge_recovery_data = compliance_limit_data;
    amp_settle_data = charge_recovery_data;
    % Scaling variables appropriatly.
    for jj=1:num_amplifier_channels
        stim_data = stim_dataFile{jj}.data;
        % Scale voltage levels appropriately.
        amplifier_dataFile{jj}.data = 0.195 * (single(amplifier_dataFile{jj}.data) - 32768); % units = microvolts
        if (dc_amp_data_saved ~= 0)
            dc_amplifier_dataFile{jj}.data = -0.01923 * (single(dc_amplifier_dataFile{jj}.data) - 512); % units = volts
        end
        compliance_limit_data(jj,:) = stim_data >= 2^15;
        stim_data = stim_data - (compliance_limit_data(jj,:) * 2^15);
        charge_recovery_data(jj,:) = stim_data >= 2^14;
        stim_data = stim_data - (charge_recovery_data(jj,:) * 2^14);
        amp_settle_data(jj,:) = stim_data >= 2^13;
        stim_data = stim_data - (amp_settle_data(jj,:) * 2^13);
        stim_polarity = stim_data >= 2^8;
        stim_data = stim_data - (stim_polarity * 2^8);
        stim_polarity = 1 - 2 * stim_polarity; % convert (0 = pos, 1 = neg) to +/-1
        stim_data = stim_data .* stim_polarity;
        stim_dataFile{jj}.data = stim_step_size * stim_data / 1.0e-6; % units = microamps
    end
    for jj=1:num_board_adc_channels
           board_adc_dataFile{jj}.data = 312.5e-6 * (single(board_adc_dataFile{jj}.data) - 32768); % units = volts
    end
    for jj=1:num_board_dac_channels
        board_dac_dataFile{jj}.data = 312.5e-6 * (single(board_dac_dataFile{jj}.data) - 32768); % units = volts
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
        blockObj.Channels(iCh).rawData = orgExp.libs.DiskData(amplifier_dataFile{iCh});
    
        as_data_fname = strrep(fullfile(blockObj.paths.DW,'STIM_DATA',[blockObj.Name '_ASD_P%s_Ch_%s.mat']),'\','/');
        fname = sprintf(strrep(as_data_fname,'\','/'), pnum, chnum);
        data = single(amp_settle_data(iCh,:));
        save(fullfile(fname),'data','-v7.3');
        blockObj.Channels(iCh).amp_settle_data= orgExp.libs.DiskData(matfile(fname));
        
        cr_data_fname = strrep(fullfile(blockObj.paths.DW,'STIM_DATA',[blockObj.Name '_CRD_P%s_Ch_%s.mat']),'\','/');
        fname = sprintf(strrep(cr_data_fname,'\','/'), pnum, chnum);
        data = single(charge_recovery_data(iCh,:));
        save(fullfile(fname),'data','-v7.3');
        blockObj.Channels(iCh).charge_recovery_data= orgExp.libs.DiskData(matfile(fname));
        
        cl_data_fname = strrep(fullfile(blockObj.paths.DW,'STIM_DATA',[blockObj.Name '_CLD_P%s_Ch_%s.mat']),'\','/');
        fname = sprintf(strrep(cl_data_fname,'\','/'), pnum, chnum);
        data = single(compliance_limit_data(iCh,:));
        save(fullfile(fname),'data','-v7.3');
        blockObj.Channels(iCh).compliance_limit_data= orgExp.libs.DiskData(matfile(fname));
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


