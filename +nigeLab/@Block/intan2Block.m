function flag = intan2Block(blockObj,fields,paths)
%% INTAN2BLOCK  Convert Intan binary to nigeLab.Block file structure
%
%  flag = INTAN2BLOCK(blockObj);
%  flag = INTAN2BLOCK(blockObj,fields);
%  flag = INTAN2BLOCK(blockObj,fields,paths);
%
%  b = nigeLab.Block;      % create block object
%  doRawExtraction(b);     % INTAN2BLOCK is run from DORAWEXTRACTION
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     Block Class object.
%
%   fields     :     (optional) cell array of field names to extract.
%                       Syntax should match cell array of strings in
%                       blockObj.Fields property. If not specified, this
%                       defaults to blockObj.Fields.
%
%   paths      :     (optional) paths struct, which might be modified if
%                       submitted via QRAWEXTRACTION (so that UNC paths can
%                       be used instead of normal paths). This is generated
%                       as blockObj.pars from GENPATHS method. If not
%                       specified, this defaults to a pre-specified list of
%                       fields that also depends on the FileExt property
%                       (e.g. .rhd vs .rhs).
%
%  --------
%   OUTPUT
%  --------
%  Creates file hierarchy of *.mat files in nigeLab-compatible structure.
%
% See also: DORAWEXTRACTION, QRAWEXTRACTION

%% PARSE INPUT
flag = false;
if nargin < 3 % If 2 inputs, need to specify default paths struct
   paths = blockObj.Paths;
   myJob = nan;
else % Otherwise, it was run via a "q" command (hence different paths)
   myJob = getCurrentJob;
end

if nargin < 2 % If 1 input, need to specify default fields
   switch blockObj.FileExt
      case '.rhd'
         fields = {'Time','Raw','DigIO','AnalogIO'};
         
      case '.rhs'
         fields = {'Time','Raw','DigIO','AnalogIO','Stim','DC'};
      otherwise
         warning('Intan extraction not setup for %s files. Canceled.',...
            blockObj.FileExt);
         return;
   end
else % otherwise just make sure it is correct orientation
   fields = reshape(fields,1,numel(fields));
end

%% PARSE HEADER
fid = fopen(blockObj.RecFile, 'r');
s = dir(blockObj.RecFile);
filesize = s.bytes;
switch blockObj.FileExt
   case '.rhd'
      header = ReadRHDHeader('FID',fid);
   case '.rhs'
      header = ReadRHSHeader('FID',fid);
end

blockObj.Meta.Header = fixNamingConvention(header);

if ~blockObj.Meta.DataPresent
   warning('No data found in %s.',recFile);
   return;
end

%% PRE-ALLOCATE MEMORY FOR WRITING RECORDED VARIABLES TO DISK FILES
% preallocates matfiles for varible that otherwise would require
% nChannles*nSamples matrices



fprintf(1, 'Allocating memory for data...\n');
Files = struct;
for f = fields
   idx = find(strcmpi(blockObj.Fields,f),1,'first');
   if isempty(idx)
      warning('Field: %s is invalid. Skipped its extraction.',f);
      continue;
   else
      this = blockObj.Fields{idx}; % Make sure case syntax is correct
   end
   
   
   switch blockObj.FieldType{idx}
      case 'Channels' % Each "Channels" file has multiple channels
         notifyUser(blockObj,myJob,this);
         infoField = [this 'Channels'];
         info = blockObj.Meta.Header;
         infoname = fullfile(paths.Raw.info);
         save(fullfile(infoname),'info','-v7.3');
         % One file per probe and channel
         Files.Raw = cell(num_amplifier_channels,1);
         diskPars.class = 'single';
         for iCh = 1:num_amplifier_channels
            pNum  = num2str(amplifier_channels(iCh).port_number);
            chNum = amplifier_channels(iCh).custom_channel_name(...
               regexp(amplifier_channels(iCh).custom_channel_name, '\d'));
            fName = sprintf(strrep(paths.RW_N,'\','/'), pNum, chNum);
            diskPars.name = fName;
            Files.Raw{iCh} = makeDiskFile(diskPars);
            notifyUser(blockObj,myJob,this,iCh,N)
            
            
         end
      case 'Events' % {{{ To be added: Automate event extraction HERE }}}
         
         
      case 'Meta' % Each "Meta" file should only have one "channel"
         diskPars = struct('format',blockObj.SaveFormat,...
            'name',fullfile(paths.(this).info),...
            'size',[1 num_amplifier_samples],...
            'access','w',...
            'class','int32');
         Files.(this) = makeDiskFile(diskPars);
         
      case 'Streams'
         
         
      otherwise
         warning('No extraction handling for FieldType: %s.',...
            blockObj.FieldType{idx});
         continue;
   end
   
end





% Save single-channel adc data
if (num_board_adc_channels > 0)
   if exist('myJob','var')~=0
      set(myJob,'Tag',sprintf('%s: Extracting ADC info',blockObj.Name));
   end
   fprintf(1, '\t->Extracting ADC info...%.3d%%\n',0);
   ADC_info = board_adc_channels;
   infoname = fullfile(strrep(paths.DW,'\','/'),[blockObj.Name '_ADC_Info.mat']);
   save(fullfile(infoname),'ADC_info','-v7.3');
   if (data_present)
      board_adc_dataFile = cell(num_board_adc_channels,1);
      for iCh = 1:num_board_adc_channels
         chNum = board_adc_channels(iCh).custom_channel_name;
         fName = sprintf(strrep(paths.DW_N,'\','/'),chNum);
         if exist(fName,'file'),delete(fName);end
         board_adc_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
            'class','single','size',[1 num_board_adc_samples],'access','w');
         fraction_done = 100 * (iCh / num_board_adc_channels);
         fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
      end
   end
end

% Save single-channel supply_voltage data
if (num_supply_voltage_channels > 0)
   if exist('myJob','var')~=0
      set(myJob,'Tag',sprintf('%s: Extracting VOLTAGE info',blockObj.Name));
   end
   fprintf(1, '\t->Extracting VOLTAGE info...%.3d%%\n',0);
   supply_voltage_info = supply_voltage_channels;
   infoname = fullfile(strrep(paths.DW,'\','/'),[blockObj.Name '_supply_voltage_info.mat']);
   save(fullfile(infoname),'supply_voltage_info','-v7.3');
   supply_voltage_dataFile = cell(num_supply_voltage_channels,1);
   for iCh = 1:num_supply_voltage_channels
      chNum = supply_voltage_channels(iCh).custom_channel_name;
      fName = sprintf(strrep(paths.DW_N,'\','/'),chNum);
      if exist(fName,'file'),delete(fName);end
      supply_voltage_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
         'class','single','size',[1 num_supply_voltage_samples],'access','w');
      fraction_done = 100 * (iCh / num_supply_voltage_channels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
   end
end

% Save single-channel temperature data
if (num_temp_sensor_channels > 0)
   if exist('myJob','var')~=0
      set(myJob,'Tag',sprintf('%s: Extracting TEMPERATURE info',blockObj.Name));
   end
   fprintf(1, '\t->Extracting TEMP info...%.3d%%\n',0);
   temp_sensor_info = temp_sensor_channels;
   infoname = fullfile(strrep(paths.DW, '\', '/'),[blockObj.Name '_temp_sensor_info.mat']);
   save(fullfile(infoname),'temp_sensor_info','-v7.3');
   temp_sensor_dataFile = cell(num_temp_sensor_channels,1);
   for iCh = 1:num_temp_sensor_channels
      paths.DW_N = strrep(paths.DW_N, '\', '/');
      chNum = temp_sensor_channels(iCh).custom_channel_name;
      fName = sprintf(strrep(paths.DW_N,'\','/'),chNum);
      if exist(fName,'file'),delete(fName);end
      temp_sensor_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
         'class','single','size',[1 num_temp_sensor_samples],'access','w');
      fraction_done = 100 * (iCh / num_temp_sensor_channels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
   end
end

% Save single-channel aux-in data
if (num_aux_input_channels > 0)
   if exist('myJob','var')~=0
      set(myJob,'Tag',sprintf('%s: Extracting AUX info',blockObj.Name));
   end
   fprintf(1, '\t->Extracting AUX info...%.3d%%\n',0);
   AUX_info = aux_input_channels;
   infoname = fullfile(strrep(paths.DW, '\', '/'),[blockObj.Name '_AUX_Info.mat']);
   save(fullfile(infoname),'AUX_info','-v7.3');
   aux_input_dataFile = cell(num_aux_input_channels,1);
   for iCh = 1:num_aux_input_channels
      chNum = aux_input_channels(iCh).custom_channel_name;
      fName = sprintf(strrep(paths.DW_N,'\','/'), chNum);
      if exist(fName,'file'),delete(fName);end
      aux_input_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
         'class','single','size',[1 num_aux_input_samples],'access','w');
      fraction_done = 100 * (iCh / num_aux_input_channels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
   end
end

% Save single-channel digital input data
if (num_board_dig_in_channels > 0)
   if exist('myJob','var')~=0
      set(myJob,'Tag',sprintf('%s: Extracting DIG-IN info',blockObj.Name));
   end
   fprintf(1, '\t->Extracting DIG-IN info...%.3d%%\n',0);
   DigI_info = board_dig_in_channels;
   infoname = fullfile(strrep(paths.DW, '\', '/'),[blockObj.Name '_Digital_Input_Info.mat']);
   save(fullfile(infoname),'DigI_info','-v7.3');
   if (data_present)
      board_dig_in_dataFile = cell(num_board_dig_in_channels,1);
      for iCh = 1:num_board_dig_in_channels
         paths.DW_N = strrep(paths.DW_N, '\', '/');
         chNum = board_dig_in_channels(iCh).custom_channel_name;
         fName = sprintf(strrep(paths.DW_N,'\','/'), chNum);
         if exist(fName,'file'),delete(fName);end
         board_dig_in_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
            'class','int8','size',[1 num_board_dig_in_samples],'access','w');
         fraction_done = 100 * (iCh / num_board_dig_in_channels);
         fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
      end
   end
end

% Save single-channel digital output data
if (num_board_dig_out_channels > 0)
   if exist('myJob','var')~=0
      set(myJob,'Tag',sprintf('%s: Extracting DIG-O info',blockObj.Name));
   end
   fprintf(1, '\t->Extracting DIG-OUT info...%.3d%%\n',0);
   DigO_info = board_dig_out_channels;
   infoname = fullfile(strrep(paths.DW, '\', '/'),[blockObj.Name '_Digital_Output_Info.mat']);
   save(fullfile(infoname),'DigO_info','-v7.3');
   if (data_present)
      board_dig_out_dataFile = cell(num_board_dig_out_channels,1);
      for iCh = 1:num_board_dig_out_channels
         chNum = board_dig_out_channels(iCh).custom_channel_name;
         fName = sprintf(strrep(paths.DW_N,'\','/'),chNum);
         if exist(fName,'file'),delete(fName);end
         board_dig_out_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
            'class','int8','size',[1 num_board_dig_out_samples],'access','w');
         fraction_done = 100 * (iCh / num_board_dig_out_channels);
         fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
      end
   end
end
fprintf(1,'Matfiles created succesfully.\n');
fprintf(1,'Writing data to Matfiles...%.3d%%\n',0);

% We need buffer viarables to read data from file and save it into a
% matlab friendly format using matfiles. Those varibles needs to be as
% big as possible to speed up the process. in order to do that we will
% alocate 4/5 of the available memory to those variables.
nDataPoints=bytes_per_block/2; % reading uint16
time_buffer_index = false(1,nDataPoints);
amplifier_buffer_index = zeros(1,nDataPoints,'uint16');
supply_voltage_buffer_index = zeros(1,nDataPoints,'uint16');
temp_buffer_index = zeros(1,nDataPoints,'uint16');
aux_in_buffer_index = zeros(1,nDataPoints,'uint16');
adc_buffer_index = zeros(1,nDataPoints,'uint16');
dig_in_buffer_index = false(1,nDataPoints);
dig_out_buffer_index = false(1,nDataPoints);

if ~isunix % For Windows machines:
   [~,MEM]=memory;
   AvailableMemory=MEM.PhysicalMemory.Available*0.8;
else % For Mac machines:
   [status, cmdout]=system('sysctl hw.memsize | awk ''{print $2}''');
   if status == 0
      fprintf(1,'\nMac OSX detected. Available memory: %s\n',cmdout);
      AvailableMemory=round(str2double(cmdout)*0.8);
   else
      AvailableMemory=2147483648; % (2^31)
   end
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
   index=end_+1:end_+num_samples_per_data_block/4 * num_aux_input_channels;
   end_=index(end);
   aux_in_buffer_index(index)=uint16(reshape(repmat(1:num_aux_input_channels,num_samples_per_data_block/4,1),1,[]));
   aux_in_buffer_index=repmat(aux_in_buffer_index,1,nBlocks);
end

if (num_supply_voltage_channels > 0)
   index=end_+1:end_+ 1 * num_supply_voltage_channels;
   end_=index(end);
   supply_voltage_buffer_index(index)=uint16(reshape(repmat(1:num_supply_voltage_channels,1,1),1,[]));
   supply_voltage_buffer_index=repmat(supply_voltage_buffer_index,1,nBlocks);
end

if (num_temp_sensor_channels > 0)
   index=end_+1:end_+ 1 * num_temp_sensor_channels;
   end_=index(end);
   temp_buffer_index(index)=uint16(reshape(repmat(1:num_temp_sensor_channels,1,1),1,[]));
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

switch eval_board_mode
   case 1
      adc_scale = 152.59e-6;
      adc_offset = 32768;
   case 13
      adc_scale = 312.5e-6;
      adc_offset = 32768;
   otherwise
      adc_scale =  50.354e-6;
      adc_offset = 0;
end


progress=0;
num_gaps = 0;
index = 0;

deBounce = false;
for i=1:ceil(num_data_blocks/nBlocks)
   pct = round(i/nBlocks*100);
   if rem(pct,5)==0 && ~deBounce
      if exist('myJob','var')~=0
         set(myJob,'Tag',sprintf('%s: Saving DATA %g%%',blockObj.Name,pct));
      end
      deBounce = true;
   elseif rem(pct+1,5)==0 && deBounce
      deBounce = false;
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Read binary data.
   blocksToread = min(nBlocks,num_data_blocks-nBlocks*(i-1));
   dataToRead = blocksToread*nDataPoints;
   Buffer=uint16(fread(fid, dataToRead, 'uint16=>uint16'))';
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Update the files
   index =uint32( index(end) + 1 : index(end)+num_samples_per_data_block*blocksToread);
   
   t=typecast(Buffer(time_buffer_index(1:dataToRead)),'int32');t = reshape(t,1,numel(t)); % ensure correct orientation
   Files.Time.append(t);
   t = reshape(t,1,numel(t)); % ensure correct orientation
   Files.Time.append(t);
   num_gaps = num_gaps + sum(diff(t) ~= 1);
   
   % Scale time steps (units = seconds)
   clear('t');
   % Write data to file
   fprintf(1, '\t->Saving RAW data...%.3d%%\n',0);
   for jj=1:num_amplifier_channels % units = microvolts
      amplifier_dataFile{jj}.append( 0.195 * (single(Buffer(amplifier_buffer_index(1:dataToRead)==jj)) - 32768));
      fraction_done = 100 * (iCh / num_amplifier_channels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
   end
   
   fprintf(1, '\t->Saving AUX data...%.3d%%\n',0);
   for jj=1:num_aux_input_channels % units = volts
      aux_input_dataFile{jj}.append( 37.4e-6 * single(Buffer(aux_in_buffer_index(1:dataToRead)==jj)));
      fraction_done = 100 * (iCh / num_aux_input_channels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
   end
   
   fprintf(1, '\t->Saving SUPPLY VOLTAGE data...%.3d%%\n',0);
   for jj=1:num_supply_voltage_channels  % units = volts
      supply_voltage_dataFile{jj}.append( 74.8e-6 * single(Buffer(supply_voltage_buffer_index(1:dataToRead)==jj)));
      fraction_done = 100 * (iCh / num_supply_voltage_channels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
   end
   
   fprintf(1, '\t->Saving TEMPERATURE data...%.3d%%\n',0);
   for jj=1:num_temp_sensor_channels % units = deg C
      temp_sensor_dataFile{jj}.append(single(Buffer(temp_buffer_index(1:dataToRead)==jj)) ./100 );
      fraction_done = 100 * (iCh / num_temp_sensor_channels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
   end
   
   fprintf(1, '\t->Saving ADC data...%.3d%%\n',0);
   for jj=1:num_board_adc_channels % units = volts
      board_adc_dataFile{jj}.append( adc_scale * (single(Buffer(adc_buffer_index(1:dataToRead)==jj))  - adc_offset ));
      fraction_done = 100 * (iCh / num_board_adc_channels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
   end
   
   fprintf(1, '\t->Saving DIG-IN data...%.3d%%\n',0);
   if num_board_dig_in_channels
      dig_in_raw=Buffer(dig_in_buffer_index(1:dataToRead));
      for jj=1:num_board_dig_in_channels
         mask = uint16(2^(board_dig_in_channels(jj).native_order) * ones(size(dig_in_raw)));
         board_dig_in_dataFile{jj}.append(int8(bitand(dig_in_raw, mask) > 0));
         fraction_done = 100 * (iCh / num_board_dig_in_channels);
         fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
      end
   end
   
   fprintf(1, '\t->Saving DIG-OUT data...%.3d%%\n',0);
   if num_board_dig_out_channels
      dig_out_raw=Buffer(dig_out_buffer_index(1:dataToRead));
      for jj=1:num_board_dig_out_channels
         mask =uint16( 2^(board_dig_out_channels(jj).native_order) * ones(size(dig_out_raw)));
         board_dig_out_dataFile{jj}.append(int8(bitand(dig_out_raw, mask) > 0));
         fraction_done = 100 * (iCh / num_dig_out_channels);
         fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
      end
   end
   
   clc;
   progress=progress+min(nBlocks,num_data_blocks-nBlocks*(i-1));
   fraction_done = 100 * (progress / num_data_blocks);
   if ~floor(mod(fraction_done,5)) % only increment counter by 5%
      fprintf(1,'Writing data to Matfiles...%.3d%%\n',floor(fraction_done));
   end
end
fprintf(1,newline);

% Make sure we have read exactly the right amount of data.
bytes_remaining = filesize - ftell(fid);
if (bytes_remaining ~= 0)
   warning('Error: End of file not reached.');
end

T1=toc;
% Close data file.
fclose(fid);

if (data_present)
   
   %% Linking data to blockObj
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % DiskData makes it easy to access data stored in matfies.
   % Assigning each file to the right channel
   for iCh=1:num_amplifier_channels
      blockObj.Channels(iCh).Raw = lockData(amplifier_dataFile{iCh});
   end
   blockObj.Time = Files.Time;
end

% % % % % % % % % % % % % % % % % % % % % %
if exist('myJob','var')~=0
   set(myJob,'Tag',sprintf('%s: Raw Extraction complete.',blockObj.Name));
end

flag = true;

updateStatus(blockObj,'Raw',true);

end

function header_out = fixNamingConvention(header_in)
%% FIXNAMINGCONVENTION  Remove '_' and switch to CamelCase

header_out = struct;
f = fieldnames(header_in);
for iF = 1:numel(f)
   str = strsplit(f{iF},'_');
   for iS = 1:numel(str)
      str{iS}(1) = upper(str{iS}(1));
   end
   str = strjoin(str,'');
   header_out.(str) = header_in.(f{iF});
end
end

function diskFile = makeDiskFile(diskPars)
%% MAKEDISKFILE   Short-hand function to create file on disk
% Check if file exists; if it does, remove it
if exist(diskPars.name,'file')
   delete(diskPars.name)
end
% Then create new pre-allocated diskFile
diskFile = nigeLab.libs.DiskData(...
   diskPars.format,...
   diskPars.name,...
   'class',diskPars.class,...
   'size',diskPars.size,...
   'access',diskPars.access);
end

function notifyUser(blockObj,myJob,curField,curIdx,totIdx)
%% NOTIFYUSER  Update user of job processing status
% Compute overall completion percentage
if nargin < 5
   pctComplete = 0;
else
   pctComplete = floor(100 * (curIdx / totIdx));
end

% If parallel job, update the job status tag so you can track progress
% using the Parallel Job Monitor
if isa(myJob,'parallel.job.CJSCommunicatingJob')
   set(myJob,'Tag',sprintf('%s: Extracting %s info...%.3d%%',...
      blockObj.Name,curField,pctComplete));
   
else % Otherwise, print to Command Window
   if pctComplete==0
      fprintf(1, '\t->Extracting %s info...%.3d%%\n',...
         curField,jobPct);
   else
      fprintf(1,'\b\b\b\b\b%.3d%%\n',pctComplete);
   end
end
end

% function progress(varargin)
% if nargin ==0
%    fprintf(1,'Writing data to Matfiles...%.3d%%\n',0);
%    fprintf(1, '\t->Saving RAW data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving AUX data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving SUPPLY VOLTAGE data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving TEMPERATURE data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving ADC data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving DIG-IN data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving DIG-OUT data...%.3d%%\n',0);
% else
%    prog = varargin{1};
%    l(1)= 32;
%    l(2) = 23;
%    l(3) = 23;
%    l(4) = 36;
%    l(5) = 33;
%    l(6) = 23;
%    l(7) = 27;
%    l(8) = 28;
%
%    fprintf(1,'%sWriting data to Matfiles...%.3d%%\n',0);
%    fprintf(1, '\t->Saving RAW data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving AUX data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving SUPPLY VOLTAGE data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving TEMPERATURE data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving ADC data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving DIG-IN data...%.3d%%\n',0);
%    fprintf(1, '\t->Saving DIG-OUT data...%.3d%%\n',0);
% end
% end
