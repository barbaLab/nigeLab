function [outputArg1,outputArg2] = linkToData(blockObj)
%% Connects the data saved on the disk to the structure
% Useful when you already have formatted data or when the processing stops
% for some reason
% WIP - adds CAR rereferincing and filtered data

% One file per probe and channel
for iCh = 1:blockObj.numChannels
    pnum  = num2str(blockObj.Channels(iCh).port_number);
    chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
    fname = sprintf(strrep(blockObj.paths.RW_N,'\','/'), pnum, chnum);
    amplifier_dataFile{iCh} = matfile(fullfile(fname),'Writable',true);
    if ~exist(fullfile(fname),'file')
        amplifier_dataFile{iCh}.data = (zeros(1,blockObj.numChannels,'single'));
    end
    blockObj.Channels(iCh).rawData = orgExp.libs.DiskData(amplifier_dataFile{iCh});
    
    
    stim_data_fname = strrep(fullfile(blockObj.paths.DW,'STIM_DATA',[blockObj.Name '_STIM_P%s_Ch_%s.mat']),'\','/');
    fname = sprintf(strrep(stim_data_fname,'\','/'), pnum, chnum);
    stim_dataFile{iCh} = matfile(fullfile(fname),'Writable',true);
    if ~exist(fullfile(fname),'file')
        stim_dataFile{iCh}.data = (zeros(1,blockObj.numChannels,'single'));
    end
    blockObj.Channels(iCh).stimData = orgExp.libs.DiskData(stim_dataFile{iCh});
    
    if (blockObj.dcAmpDataSaved ~= 0)
        dc_amp_fname = strrep(fullfile(blockObj.paths.DW,'DC_AMP',[blockObj.Name '_DCAMP_P%s_Ch_%s.mat']),'\','/');
        fname = sprintf(strrep(dc_amp_fname,'\','/'), pnum, chnum);
        dc_amplifier_dataFile{iCh} =  matfile(fullfile(fname),'Writable',true);
        if ~exist(fullfile(fname),'file')
            dc_amplifier_dataFile{iCh}.data = (zeros(1,blockObj.numChannels,'single'));
        end
        blockObj.Channels(iCh).dcAmpData = orgExp.libs.DiskData(dc_amplifier_dataFile{iCh});
    end
    
    if 1 % check folder is not empty
        fname = sprintf(strrep(blockObj.paths.LW_N,'\','/'), pnum, chnum);
        blockObj.Channels(iCh).LFPData=orgExp.libs.DiskData(matfile(fullfile(fname)));
    end
    
end

% Save single-channel adc data
for i = 1:blockObj.numADCchannels
    blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
    fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'),blockObj.ADCChannels(i).custom_channel_name);
    board_adc_dataFile{i} = matfile(fullfile(fname),'Writable',true);
    if ~exist(fullfile(fname),'file')
        board_adc_dataFile{i}.data = (zeros(1,blockObj.numChannels,'single'));
    end
    blockObj.ADCChannels(i).data=orgExp.libs.DiskData(board_adc_dataFile{i});
end

% Save single-channel dac data
for i = 1:blockObj.numDACChannels
    blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
    fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), blockObj.DACChannels(i).custom_channel_name);
    board_dac_dataFile{i} = matfile(fullfile(fname),'Writable',true);
    if ~exist(fullfile(fname),'file')
        board_dac_dataFile{i}.data = (zeros(1,blockObj.numChannels,'single'));
    end
    blockObj.DACChannels(i).data=orgExp.libs.DiskData(board_dac_dataFile{i});
end

% Save single-channel digital input data
for i = 1:blockObj.numDigInChannels
    blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
    fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), blockObj.DigInChannels(i).custom_channel_name);
    board_dig_in_dataFile{i} = matfile(fullfile(fname),'Writable',true);
    if ~exist(fullfile(fname),'file')
        board_dig_in_dataFile{i}.data = (zeros(1,blockObj.numChannels,'single'));
    end
    blockObj.DigInChannels(i).data=orgExp.libs.DiskData(board_dig_in_dataFile{i});
end



% Save single-channel digital output data
for i = 1:blockObj.numDigOutChannels
    fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), blockObj.DigOutChannels(i).custom_channel_name);
    board_dig_out_dataFile{i} = matfile(fullfile(fname),'Writable',true);
    if ~exist(fullfile(fname),'file')
        board_dig_out_dataFile{i}.data = (zeros(1,blockObj.numChannels,'single'));
    end
    blockObj.DigOutChannels(i).data=orgExp.libs.DiskData(board_dig_out_dataFile{i});
end

blockObj.Status(1)=true;
blockObj.save;
end

