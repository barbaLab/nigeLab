function [outputArg1,outputArg2] = linkToData(blockObj)
%% Connects the data saved on the disk to the structure
% Useful when you already have formatted data or when the processing stops
% for some reason
% WIP - adds CAR rereferincing and filtered data

% One file per probe and channel
warningFlag=false;
UpdateStatus = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%       Amp Channels        %%%%%%%%%%%%%%%%%%%%%%

for iCh = 1:blockObj.numChannels
    
    %%%%%%%%%%%%% Raw data (and digital data)
    pnum  = num2str(blockObj.Channels(iCh).port_number);
    chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
    fname = sprintf(strrep(blockObj.paths.RW_N,'\','/'), pnum, chnum);
    if ~exist(fullfile(fname),'file')
        warningFlag=true;
        UpdateStatus = false;     
        break;
    end
    blockObj.Channels(iCh).rawData = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
    
    
    stim_data_fname = strrep(fullfile(blockObj.paths.DW,'STIM_DATA',[blockObj.Name '_STIM_P%s_Ch_%s.mat']),'\','/');
    fname = sprintf(strrep(stim_data_fname,'\','/'), pnum, chnum);
    if ~exist(fullfile(fname),'file')
        warningFlag=true;
        UpdateStatus = false;
        break;
    end
    blockObj.Channels(iCh).stimData = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
    
    if (blockObj.dcAmpDataSaved ~= 0)
        dc_amp_fname = strrep(fullfile(blockObj.paths.DW,'DC_AMP',[blockObj.Name '_DCAMP_P%s_Ch_%s.mat']),'\','/');
        fname = sprintf(strrep(dc_amp_fname,'\','/'), pnum, chnum);
        if ~exist(fullfile(fname),'file')
            warningFlag=true;
            UpdateStatus = false;
            break;       
        end
        blockObj.Channels(iCh).dcAmpData = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
    end
end
if UpdateStatus, blockObj.updateStatus('Raw',true);end
    
    %%%%%%%%%%%% LFP data
for iCh = 1:blockObj.numChannels
    fname = sprintf(strrep(blockObj.paths.LW_N,'\','/'), pnum, chnum);
    if ~exist(fullfile(fname),'file')
        warningFlag=true;
        UpdateStatus = false;
        break;        
    end
    blockObj.Channels(iCh).LFPData=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end
if UpdateStatus, blockObj.updateStatus('LFP',true);end

    %%%%%%%%%%%%%%%% Filt data
for iCh = 1:blockObj.numChannels    
    fname = sprintf(strrep(blockObj.paths.FW_N,'\','/'), pnum, chnum);
    if ~exist(fullfile(fname),'file')
        warningFlag=true;
        UpdateStatus = false;
        break;        
    end
    blockObj.Channels(iCh).Filtered=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end
if UpdateStatus, blockObj.updateStatus('Filt',true);end

    %%%%%%%%%%%%%%%% CAR data
for iCh = 1:blockObj.numChannels    
    fname = sprintf(strrep(blockObj.paths.CARW_N,'\','/'), pnum, chnum);
    if ~exist(fullfile(fname),'file')
        warningFlag = true;
        UpdateStatus = false;
        break;
    end
    blockObj.Channels(iCh).CAR=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end
if UpdateStatus, blockObj.updateStatus('CAR',true); end

    %%%%%%%%%%%%%%%% spikedetection data
for iCh = 1:blockObj.numChannels    
    fname = sprintf(strrep(blockObj.paths.SDW_N,'\','/'), pnum, chnum);
    if ~exist(fullfile(fname),'file')
        warningFlag=true;
        UpdateStatus = false;
        break;
    end
    blockObj.Channels(iCh).Spikes=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end   
if UpdateStatus, blockObj.updateStatus('Spikes',true);end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%       AUX Channels        %%%%%%%%%%%%%%%%%%%%%%

% Save single-channel adc data
for i = 1:blockObj.numADCchannels
    blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
    fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'),blockObj.ADCChannels(i).custom_channel_name);
    if ~exist(fullfile(fname),'file')
        warningFlag=true;
        break;
    end
    blockObj.ADCChannels(i).data=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end

% Save single-channel dac data
for i = 1:blockObj.numDACChannels
    blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
    fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), blockObj.DACChannels(i).custom_channel_name);
    if ~exist(fullfile(fname),'file')
        warningFlag=true;
        break;
    end
    blockObj.DACChannels(i).data=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end

% Save single-channel digital input data
for i = 1:blockObj.numDigInChannels
    blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
    fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), blockObj.DigInChannels(i).custom_channel_name);
    if ~exist(fullfile(fname),'file')
        warningFlag=true;
        break;
    end
    blockObj.DigInChannels(i).data=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end



% Save single-channel digital output data
for i = 1:blockObj.numDigOutChannels
    fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), blockObj.DigOutChannels(i).custom_channel_name);
     if ~exist(fullfile(fname),'file')
        warningFlag=true;
        break;
    end
    blockObj.DigOutChannels(i).data = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end

if warningFlag
    warning('Something went wrong. Consider rerunning the processing stages');
end

blockObj.save;
end

