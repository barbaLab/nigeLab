function flag = rhs2Block(blockObj,recFile,paths)
%% RHS2BLOCK  Convert Intan RHS binary to Matlab BLOCK format
%
%  b = orgExp.Block;        % create block object
%  doRawExtraction(b);      % RHS2Block is run from DORAWEXTRACTION
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     Block class object.
%
%  recFile     :     (Optional) If different than the value associated with
%                               blockObj property, specify here.
%
%   paths      :     (Optional) If different than the value associated with
%                               blockObj property, specify here.
%
%  --------
%   OUTPUT
%  --------
%  Creates filtered streams *.mat files in TANK-BLOCK hierarchy format.
%
% See also: DORAWEXTRACTION, QRAWEXTRACTION

%% PARSE INPUT
if nargin < 3
   paths = blockObj.paths;
else % Otherwise, it was run via a "q" command
   myJob = getCurrentJob;
end

if nargin < 2
   recFile = blockObj.RecFile;
end

%% READ FILE
tic;
flag = false;
fid = fopen(recFile, 'r');
s = dir(recFile);
filesize = s.bytes;

%% Read the file header

header = ReadRHSHeader('FID',fid);
blockObj.Meta.Header = fixNamingConvention(header);

% this is laziness at its best, I should go through the code and change
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
   
   fName = fullfile(paths.TW_N);
   TimeFile = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
      'class','int32','size',[1 num_amplifier_samples],'access','w');
   
   if (num_amplifier_channels > 0)
      if exist('myJob','var')~=0
         set(myJob,'Tag',sprintf('%s: Extracting RAW info',blockObj.Name));
      end
	  fprintf(1, '\t->Extracting RAW info...%.3d%%\n',0);   
   RW_info = amplifier_channels;
   infoname = fullfile(strrep(paths.RW,'\','/'),[blockObj.Name '_RawWave_Info.mat']);
   save(fullfile(infoname),'RW_info','-v7.3');
   % One file per probe and channel
   amplifier_dataFile = cell(num_amplifier_channels,1);
   stim_dataFile = cell(num_amplifier_channels,1);
   if (dc_amp_data_saved ~= 0)
      dc_amplifier_dataFile = cell(num_amplifier_channels,1);
   end
   for iCh = 1:num_amplifier_channels
      pNum  = num2str(amplifier_channels(iCh).port_number);
      chNum = amplifier_channels(iCh).custom_channel_name(regexp(amplifier_channels(iCh).custom_channel_name, '\d'));
      fName = sprintf(strrep(paths.RW_N,'\','/'), pNum, chNum);
      if exist(fName,'file'),delete(fName);end
      amplifier_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
         'class','single','size',[1 num_amplifier_samples],'access','w');
      
      stim_data_fName = strrep(fullfile(paths.DW,'STIM_DATA',[blockObj.Name '_STIM_P%s_Ch_%s.mat']),'\','/');
      fName = sprintf(strrep(stim_data_fName,'\','/'), pNum, chNum);
      if exist(fName,'file'),delete(fName);end
      stim_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fName),single(0),...
         'class','single','size',[1 num_amplifier_samples],'access','w');
      
      if (dc_amp_data_saved ~= 0)
         dc_amp_fName = strrep(fullfile(paths.DW,'DC_AMP',[blockObj.Name '_DCAMP_P%s_Ch_%s.mat']),'\','/');
         fName = sprintf(strrep(dc_amp_fName,'\','/'), pNum, chNum);
          if exist(fName,'file'),delete(fName);end
         dc_amplifier_dataFile{iCh} =  orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fName),single(0),...
            'class','single','size',[1 num_amplifier_samples],'access','w');
      end
		 fraction_done = 100 * (iCh / num_amplifier_channels);
		 fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));       
   end
   
   % Save single-channel adc data
   if (num_board_adc_channels > 0)
      if exist('myJob','var')~=0
         set(myJob,'Tag',sprintf('%s: Extracting ADC info',blockObj.Name));
      end
	  fprintf(1, '\t->Extracting ADC info...%.3d%%\n',0);
      ADC_info = board_adc_channels;
      paths.DW = strrep(paths.DW, '\', '/');
      infoname = fullfile(paths.DW,[blockObj.Name '_ADC_Info.mat']);
      save(fullfile(infoname),'ADC_info','-v7.3');
      if (data_present)
         board_adc_dataFile = cell(num_board_adc_channels,1);
         for i = 1:num_board_adc_channels
            paths.DW_N = strrep(paths.DW_N, '\', '/');
            fName = sprintf(strrep(paths.DW_N,'\','/'), board_adc_channels(i).custom_channel_name);
           if exist(fName,'file'),delete(fName);end
            board_adc_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fName),single(0),...
               'class','single','size',[1 num_board_adc_samples],'access','w');
		 fraction_done = 100 * (iCh / num_board_adc_channels);
		 fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));            
         end
      end
   end
   
   % Save single-channel dac data
   if (num_board_dac_channels > 0)
      if exist('myJob','var')~=0
         set(myJob,'Tag',sprintf('%s: Extracting VOLTAGE info',blockObj.Name));
      end
	  fprintf(1, '\t->Extracting DAC info...%.3d%%\n',0);
      DAC_info = board_dac_channels;
      paths.DW = strrep(paths.DW, '\', '/');
      infoname = fullfile(paths.DW,[blockObj.Name '_DAC_Info.mat']);
      save(fullfile(infoname),'DAC_info','-v7.3');
      if (data_present)
         board_dac_dataFile = cell(num_aux_input_channels,1);
         for i = 1:num_board_dac_channels
            paths.DW_N = strrep(paths.DW_N, '\', '/');
            fName = sprintf(strrep(paths.DW_N,'\','/'), board_dac_channels(i).custom_channel_name);
           if exist(fName,'file'),delete(fName);end
            board_dac_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fName),single(0),...
               'class','single','size',[1 num_board_dac_samples],'access','w');
		fraction_done = 100 * (iCh / num_board_dac_channels);
		fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));            
         end
      end
   end
   
   % Save single-channel digital input data
   if (num_board_dig_in_channels > 0)
      if exist('myJob','var')~=0
         set(myJob,'Tag',sprintf('%s: Extracting DIG-IN info',blockObj.Name));
      end
	  fprintf(1, '\t->Extracting DIG-IN info...%.3d%%\n',0);
      DigI_info = board_dig_in_channels;
      paths.DW = strrep(paths.DW, '\', '/');
      infoname = fullfile(paths.DW,[blockObj.Name '_Digital_Input_Info.mat']);
      save(fullfile(infoname),'DigI_info','-v7.3');
      if (data_present)
         board_dig_in_dataFile = cell(num_board_dig_in_channels,1);
         for i = 1:num_board_dig_in_channels
            fName = sprintf(strrep(paths.DW_N,'\','/'), board_dig_in_channels(i).custom_channel_name);
            if exist(fName,'file'),delete(fName);end
            board_dig_in_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fName),uint8(0),...
               'class','uint8','size',[1 num_board_dig_in_samples],'access','w');
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
      paths.DW = strrep(paths.DW, '\', '/');
      infoname = fullfile(paths.DW,[blockObj.Name '_Digital_Output_Info.mat']);
      save(fullfile(infoname),'DigO_info','-v7.3');
      if (data_present)
         board_dig_out_dataFile = cell(num_board_dig_out_channels,1);
         for i = 1:num_board_dig_out_channels
            fName = sprintf(strrep(paths.DW_N,'\','/'), board_dig_out_channels(i).custom_channel_name);
            if exist(fName,'file'),delete(fName);end
            board_dig_out_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fName),uint8(0),...
               'class','uint8','size',[1 num_board_dig_out_samples],'access','w');
            fraction_done = 100 * (iCh / num_board_dig_out_channels);
            fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
         end
      end
   end
   fprintf(1,'Matfiles created succesfully\n');
  fprintf(1,'Writing data to Matfiles...%.3d%%\n',0);
   
   % We need 5 buffer viarables to read data from file and save it into a
   % matlab friendly forma using matfiles. Those varibles needs to be as
   % big as possible to speed up the process. in order to do that we will
   % alocate 4/5 of the available memory to those variables.
   
   
   nDataPoints=bytes_per_block/2; % reading uint16
   
   time_buffer_index = false(1,nDataPoints);
   amplifier_buffer_index = zeros(1,nDataPoints,'uint8');
   dc_amplifier_buffer_index = zeros(1,nDataPoints,'uint8');
   stim_buffer_index = zeros(1,nDataPoints,'uint8');
   adc_buffer_index = zeros(1,nDataPoints,'uint8');
   dac_buffer_index = zeros(1,nDataPoints,'uint8');
   dig_in_buffer_index = false(1,nDataPoints);
   dig_out_buffer_index = false(1,nDataPoints);
   
   if ~isunix % For Windows machines:
      [~,MEM]=memory;
      AvailableMemory=MEM.PhysicalMemory.Available*0.8;
   else % For Mac machines: (? -MM 2018-12-06 untested)
      [status, cmdout]=system('sysctl hw.memsize | awk ''{print $2}''');
      if status == 0
         fprintf(1,'\nMac OSX detected. Available memory: %d\n',cmdout);
         AvailableMemory=round(cmdout*0.8);
      else
         AvailableMemory=2147483648;
      end
      
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
      t=int32(bin2dec([tmp(2:2:end,:) tmp(1:2:end,:)]));  % time is sampled as 32bit integer, the file is read as 16 bit integer. This takes care of the conversion
%       t = reshape(t,1,numel(t)); % ensure correct orientation
      num_gaps = num_gaps + sum(diff(t) ~= 1);
      
      % Scale time steps (units = seconds).
      %         blockObj.Time = [ blockObj.Time float(t) ./ sample_rate];
      clear('t');
      % Write data to file
      for jj=1:num_amplifier_channels  % units = microvolts
         amplifier_dataFile{jj}.append(0.195 * ( single(Buffer(amplifier_buffer_index(1:dataToRead)==jj))- 32768 ));
         if (dc_amp_data_saved ~= 0) % units = volts
            dc_amplifier_dataFile{jj}.append(-0.01923 *( single(Buffer(dc_amplifier_buffer_index(1:dataToRead)==jj)) -512));
         end
         
      stim_data = single(Buffer(stim_buffer_index(1:dataToRead)==jj));
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
      stim_dataFile{jj}.append (  stim_step_size * stim_data / 1.0e-6 ); % units = microamps
      
      end
      
      for jj=1:num_board_adc_channels  % units = volts
         board_adc_dataFile{jj}.append ( 312.5e-6 *(single(Buffer(adc_buffer_index(1:dataToRead)==jj)) - 32768));
      end
      
      for jj=1:num_board_dac_channels % units = volts
         board_dac_dataFile{jj}.append( 312.5e-6 *  (single(Buffer(dac_buffer_index(1:dataToRead)==jj)) - 32768));
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
   deBounce = false;
   for iCh=1:num_amplifier_channels
      pct = round(i/nBlocks*100);
      if rem(pct,5)==0 && ~deBounce
         if exist('myJob','var')~=0
            set(myJob,'Tag',sprintf('%s: Saving DATA %g%%',blockObj.Name,pct));
         end
         deBounce = true;
      elseif rem(pct+1,5)==0 && deBounce
         deBounce = false;
      end
      blockObj.Channels(iCh).Raw = lockData(amplifier_dataFile{iCh});
      
      as_data_fName = strrep(fullfile(paths.DW,'STIM_DATA',[blockObj.Name '_ASD_P%s_Ch_%s.mat']),'\','/');
      fName = sprintf(strrep(as_data_fName,'\','/'), pNum, chNum);
      data = single(amp_settle_data(iCh,:));
      save(fullfile(fName),'data','-v7.3');
      blockObj.Channels(iCh).amp_settle_data= orgExp.libs.DiskData(matfile(fName));
      
      cr_data_fName = strrep(fullfile(paths.DW,'STIM_DATA',[blockObj.Name '_CRD_P%s_Ch_%s.mat']),'\','/');
      fName = sprintf(strrep(cr_data_fName,'\','/'), pNum, chNum);
      data = single(charge_recovery_data(iCh,:));
      save(fullfile(fName),'data','-v7.3');
      blockObj.Channels(iCh).charge_recovery_data= orgExp.libs.DiskData(matfile(fName));
      
      cl_data_fName = strrep(fullfile(paths.DW,'STIM_DATA',[blockObj.Name '_CLD_P%s_Ch_%s.mat']),'\','/');
      fName = sprintf(strrep(cl_data_fName,'\','/'), pNum, chNum);
      data = single(compliance_limit_data(iCh,:));
      save(fullfile(fName),'data','-v7.3');
      blockObj.Channels(iCh).compliance_limit_data= orgExp.libs.DiskData(matfile(fName));
   end
end
flag = true;

if exist('myJob','var')~=0
   set(myJob,'Tag',sprintf('%s: Raw Extraction complete.',blockObj.Name));
end

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

