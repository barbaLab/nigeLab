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
updateStatus   = true;

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
   'DIG-OUT'; ...
   'EXPERIMENT-NOTES'; ...
   'PROBES'};

warningRef     = false(size(warningString));

%% CHECK AMPLIFIER CHANNELS

fprintf(1,'\nLinking RAW channels...000%%\n');
for iCh = 1:blockObj.NumChannels
   
   %%%%%%%%%%%%% Raw data
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   fname = sprintf(strrep(blockObj.paths.RW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(1) = true;
      updateStatus = false;
      break;
   end
   blockObj.Channels(iCh).Raw = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end
if updateStatus, blockObj.updateStatus('Raw',true);end

%% CHECK STIMULATION DATA
updateStatus = true;
fprintf(1,'\nLinking STIMULATION channels...000%%\n');
for iCh = 1:blockObj.NumChannels
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   
   stim_data_fname = strrep(fullfile(blockObj.paths.DW,'STIM_DATA',[blockObj.Name '_STIM_P%s_Ch_%s.mat']),'\','/');
   fname = sprintf(strrep(stim_data_fname,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if (~exist(fullfile(fname),'file') && ismember(blockObj.FileExt,...
         {'.rhs','tdt'}))
      warningFlag=true;
      warningRef(2) = true;
      updateStatus = false;
      break;
   end
   blockObj.Channels(iCh).stimData = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
   
   if ~isempty(blockObj.DCAmpDataSaved)
      if (blockObj.DCAmpDataSaved ~= 0)
         dc_amp_fname = strrep(fullfile(blockObj.paths.DW,'DC_AMP',[blockObj.Name '_DCAMP_P%s_Ch_%s.mat']),'\','/');
         fname = sprintf(strrep(dc_amp_fname,'\','/'), pnum, chnum);
         fname = fullfile(fname);

         if ~exist(fullfile(fname),'file')
            warningFlag=true;
            warningRef(3) = true;
            updateStatus = false;
            break;
         end
         blockObj.Channels(iCh).dcAmpData = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
      end
   end
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end
if updateStatus, blockObj.updateStatus('Digital',true);end

%% CHECK LFP DATA
updateStatus = true;
fprintf(1,'\nLinking LFP channels...000%%\n');
for iCh = 1:blockObj.NumChannels
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   fname = sprintf(strrep(blockObj.paths.LW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(4) = true;
      updateStatus = false;
      break;
   end
   blockObj.Channels(iCh).LFP=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end
if updateStatus, blockObj.updateStatus('LFP',true);end

%% CHECK FILTERED DATA
updateStatus = true;
fprintf(1,'\nLinking FILTERED channels...000%%\n');
for iCh = 1:blockObj.NumChannels
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   fname = sprintf(strrep(blockObj.paths.FW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(5) = true;
      updateStatus = false;
      break;
   end
   blockObj.Channels(iCh).Filt=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end
if updateStatus, blockObj.updateStatus('Filt',true);end

%% CHECK CAR DATA
updateStatus = true;
fprintf(1,'\nLinking CAR channels...000%%\n');
for iCh = 1:blockObj.NumChannels
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   fname = sprintf(strrep(blockObj.paths.CARW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag = true;
      warningRef(6) = true;
      updateStatus = false;
      break;
   end
   blockObj.Channels(iCh).CAR=orgExp.libs.DiskData(blockObj.SaveFormat,fname);
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end
if updateStatus, blockObj.updateStatus('CAR',true); end

%% CHECK SPIKES DATA
updateStatus = true;
fprintf(1,'\nLinking SPIKES channels...000%%\n');
for iCh = 1:blockObj.NumChannels
   pnum  = num2str(blockObj.Channels(iCh).port_number);
   chnum = blockObj.Channels(iCh).custom_channel_name(regexp(blockObj.Channels(iCh).custom_channel_name, '\d'));
   fname = sprintf(strrep(blockObj.paths.SDW_N,'\','/'), pnum, chnum);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(7) = true;
      updateStatus = false;
      break;
   end
   blockObj.Channels(iCh).Spikes=orgExp.libs.DiskData('MatFile',fname);
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end
if updateStatus, blockObj.updateStatus('Spikes',true);end




%% CHECK SINGLE_CHANNEL ADC DATA
if blockObj.NumADCchannels > 0
   fprintf(1,'\nLinking ADC channels...000%%\n');
end
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
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end

%% CHECK SINGLE-CHANNEL DAC DATA
if blockObj.NumDACChannels > 0
   fprintf(1,'\nLinking DAC channels...000%%\n');
end
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
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end

%% CHECK SINGLE-CHANNEL DIGITAL INPUT DATA
if blockObj.NumDigInChannels > 0
   fprintf(1,'\nLinking DIG-IN channels...000%%\n');
end
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
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end

%% CHECK SINGLE_CHANNEL DIGITAL OUTPUT DATA
if blockObj.NumDigOutChannels > 0
   fprintf(1,'\nLinking DIG-OUT channels...000%%\n');
end
for i = 1:blockObj.NumDigOutChannels
   fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), blockObj.DigOutChannels(i).custom_channel_name);
   fname = fullfile(fname);
   
   if ~exist(fullfile(fname),'file')
      warningFlag=true;
      warningRef(11) = true;
      break;
   end
   blockObj.DigOutChannels(i).data = orgExp.libs.DiskData(blockObj.SaveFormat,fname);
   fraction_done = 100 * (iCh / blockObj.NumChannels);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end

%% PARSE EXPERIMENT METADATA
UpdateStatus = true;
notes = orgExp.defaults.Experiment();
probes = orgExp.defaults.Probes();
blockObj.ExpPars = notes;
blockObj.ProbePars = probes;

fprintf(1,'\nLinking %s...000%%\n',warningString{12});
if exist(blockObj.paths.MW_N.experiment,'file')==0
   copyfile(fullfile(notes.Folder,notes.File),...
      blockObj.paths.MW_N.experiment,'f');
end
h = blockObj.takeNotes;
waitfor(h);
warningRef(12) = true;
fprintf(1,'\b\b\b\b\b%.3d%%\n',100)

%% PARSE PROBE INFORMATION
if isfield(blockObj.ExpPars,'Probes')
   fprintf(1,'\nLinking %s...000%%\n',warningString{13});
   probePorts = fieldnames(blockObj.ExpPars.Probes);
   % Get the correct file associated with this recording in terms of
   % experimental probes. 
   for ii = 1:numel(probePorts)
      probeName = blockObj.ExpPars.Probes.(probePorts{ii}).name;
      probeFile = sprintf(probes.Str,probeName);
      fName = fullfile(blockObj.paths.MW,[blockObj.Name ...
                        probes.Delimiter probeFile]);
      if exist(fName,'file')==0
         % If the electrode file doesn't exist from default location
         eName = fullfile(probes.ElectrodesFolder,probeFile);
         if exist(eName,'file')==0
            % Create one using template
            copyfile(fullfile(probes.Folder,probes.File),fName,'f');
         else
            % Otherwise copy over the existing electrode file
            copyfile(eName,fName,'f');
         end
      end
      blockObj.ExpPars.Probes.(probePorts{ii}).Ch = readtable(fName);
   end
   
   % For each channel, update metadata from probe config file
   for iCh = 1:blockObj.NumChannels

      if ~exist(fullfile(fname),'file')
         warningFlag=true;
         warningRef(13) = true;
         UpdateStatus = false;
         break;
      end
      
      curCh = blockObj.Channels(iCh).chip_channel;
      streamIdx = blockObj.Channels(iCh).board_stream;
      % Go through all ports (or boards, really)
      for ii = 1:numel(probePorts)
         % If this is the correct one
         if blockObj.ExpPars.Probes.(probePorts{ii}).stream==streamIdx
            % Get the metadata for the correct channel
            ch = blockObj.ExpPars.Probes.(probePorts{ii}).Ch;
            v = ch.Properties.VariableNames;
            if strcmp(blockObj.FileExt,'.rhs')
               probeInfo = ch(RHD2RHS(ch.RHD_Channel)==curCh,:);
            else
               probeInfo = ch(ch.RHD_Channel==curCh,:);
            end
            
            % Assign all the included variables (columns) to channel
            % metadata.
            for iV = 1:numel(v)
               blockObj.Channels(iCh).(v{iV})=probeInfo.(v{iV});
            end
            break;
         end
      end
      

      fraction_done = 100 * (iCh / blockObj.NumChannels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
   end
   if UpdateStatus, blockObj.updateStatus('Meta',true);end
end

%% GIVE USER WARNINGS
if warningFlag && ~preExtractedFlag
   warningIdx = find(warningRef);
   warning(sprintf(['Double-check that data files are present. \n' ...
      'Consider re-running doExtraction or qExtraction.\n'])); %#ok<SPWRN>
   for ii = 1:numel(warningIdx)
      fprintf(1,'\t-> Could not find all %s data files.\n',...
         warningString{warningIdx(ii)});
   end
   
end

blockObj.save;
flag = true;
end

