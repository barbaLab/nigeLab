function flag = linkToData(blockObj,preExtractedFlag)
%% LINKTODATA  Connect the data saved on the disk to the structure
%
%  b = orgExp.Block;
%  flag = linkToData(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% DEFAULTS
flag = false;

% If not otherwise specified, assume extraction has not been done.
if nargin < 2
   preExtractedFlag = false;
end

% One file per probe and channel
warningFlag    = false;
warningRef     = false(11,1);
UpdateStatus   = true;

% Warning list
warningString = {'RAW'; ...
   'STIMULATION'; ...
   'DC-AMP'; ...
   'LFP'; ...
   'FILTERED'; ...
   'CAR'; ...
   'SPIKES'; ...
   'ADC'; ...
   'DAC'; ...
   'DIG-IN'; ...
   'DIG-OUT'};

%% CHECK AMPLIFIER CHANNELS

for iCh = 1:blockObj.NumChannels
   
   %%%%%%%%%%%%% Raw data
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   fname = sprintf(strrep(blockObj.paths.RW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(1) = true;
      UpdateStatus = false;
      break;
   end
   blockObj.Channels(iCh).Raw = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
   if UpdateStatus, blockObj.updateStatus('Raw',true);end
end

%% CHECK STIMULATION DATA
UpdateStatus = true;
for iCh = 1:blockObj.NumChannels
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   
   stim_data_fname = strrep(fullfile(blockObj.paths.DW,'STIM_DATA',[blockObj.Name '_STIM_P%s_Ch_%s.mat']),'\','/');
   fname = sprintf(strrep(stim_data_fname,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(2) = true;
      UpdateStatus = false;
      break;
   end
   blockObj.Channels(iCh).stimData = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
   
   if (blockObj.DCAmpDataSaved ~= 0)
      dc_amp_fname = strrep(fullfile(blockObj.paths.DW,'DC_AMP',[blockObj.Name '_DCAMP_P%s_Ch_%s.mat']),'\','/');
      fname = sprintf(strrep(dc_amp_fname,'\','/'), pnum, chnum);
      fname = fullfile(fname);
      
      if ~exist(fullfile(fname),'file')
         warningFlag=true;
         warningRef(3) = true;
         UpdateStatus = false;
         break;
      end
      blockObj.Channels(iCh).dcAmpData = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
   end
   if UpdateStatus, blockObj.updateStatus('Digital',true);end
end

%% CHECK LFP DATA
UpdateStatus = true;
for iCh = 1:blockObj.NumChannels
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   fname = sprintf(strrep(blockObj.paths.LW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(4) = true;
      UpdateStatus = false;
      break;
   end
   blockObj.Channels(iCh).LFPData=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end
if UpdateStatus, blockObj.updateStatus('LFP',true);end

%% CHECK FILTERED DATA
UpdateStatus = true;
for iCh = 1:blockObj.NumChannels
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   fname = sprintf(strrep(blockObj.paths.FW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(5) = true;
      UpdateStatus = false;
      break;
   end
   blockObj.Channels(iCh).Filtered=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end
if UpdateStatus, blockObj.updateStatus('Filt',true);end

%% CHECK CAR DATA
UpdateStatus = true;
for iCh = 1:blockObj.NumChannels
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   fname = sprintf(strrep(blockObj.paths.CARW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag = true;
      warningRef(6) = true;
      UpdateStatus = false;
      break;
   end
   blockObj.Channels(iCh).CAR=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end
if UpdateStatus, blockObj.updateStatus('CAR',true); end

%% CHECK SPIKES DATA
UpdateStatus = true;
for iCh = 1:blockObj.NumChannels
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   fname = sprintf(strrep(blockObj.paths.SDW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(7) = true;
      UpdateStatus = false;
      break;
   end
   blockObj.Channels(iCh).Spikes=orgExp.libs.DiskData('MatFile',fname);
end
if UpdateStatus, blockObj.updateStatus('Spikes',true);end

%% CHECK SINGLE_CHANNEL ADC DATA
for i = 1:blockObj.NumADCchannels
   blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
   fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'),blockObj.ADCChannels(i).custom_channel_name);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(8) = true;
      break;
   end
   blockObj.ADCChannels(i).data=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end

%% CHECK SINGLE-CHANNEL DAC DATA
for i = 1:blockObj.NumDACChannels
   blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
   fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), blockObj.DACChannels(i).custom_channel_name);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(9) = true;
      break;
   end
   blockObj.DACChannels(i).data=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end

%% CHECK SINGLE_CHANNEL DIGITAL INPUT DATA
for i = 1:blockObj.NumDigInChannels
   blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
   fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), blockObj.DigInChannels(i).custom_channel_name);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(10) = true;
      break;
   end
   blockObj.DigInChannels(i).data=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end

%% CHECK SINGLE_CHANNEL DIGITAL OUTPUT DATA
for i = 1:blockObj.NumDigOutChannels
   fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), blockObj.DigOutChannels(i).custom_channel_name);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(11) = true;
      break;
   end
   blockObj.DigOutChannels(i).data = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
end

%% GIVE USER WARNINGS
if warningFlag && ~preExtractedFlag
   warningIdx = find(warningRef);
   warning(sprintf(['Double-check that data files are present. \n' ...
      'Consider re-running doExtraction or qExtraction.\n'])); %#ok<SPWRN>
   for ii = 1:numel(warningIdx)
      fprintf(1,'\t-> Could not find all %s data files.\n',...
         warningString{ii});
   end
   
end

blockObj.save;
flag = true;
end

