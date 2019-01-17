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
      nBuffers = 13;
      
      switch blockObj.Meta.Header.EvalBoardMode
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
      
   case '.rhs'
      header = ReadRHSHeader('FID',fid);
      nBuffers = 10;
      
      adc_scale = 312.5e-6;
      adc_offset = 32768;
end

blockObj.Meta.Header = fixNamingConvention(header);

if ~blockObj.Meta.Header.DataPresent
   warning('No data found in %s.',recFile);
   return;
end

%% PRE-ALLOCATE MEMORY FOR WRITING RECORDED VARIABLES TO DISK FILES
% preallocates matfiles for varible that otherwise would require
% nChannles*nSamples matrices

fprintf(1, 'Allocating memory for data...\n');
Files = struct;
nCh = struct;
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
         notifyUser(blockObj,myJob,this,'info');
         info = blockObj.Meta.Header.RawChannels;
         infoname = fullfile(paths.(this).info);
         save(fullfile(infoname),'info','-v7.3');
         % One file per probe and channel
         Files.(this) = cell(blockObj.NumChannels,1);
         nCh.(this) = blockObj.NumChannels;
         diskPars.class = 'single';
         for iCh = 1:nCh.(this)
            pNum  = num2str(info(iCh).port_number);
            chNum = info(iCh).custom_channel_name(...
               regexp(info(iCh).custom_channel_name, '\d'));
            fName = sprintf(strrep(paths.(this).file,'\','/'), pNum, chNum);
            diskPars = struct('format',blockObj.FileType{idx},...
               'name',fullfile(fName),...
               'size',[1 blockObj.Meta.Header.NumRawSamples],...
               'access','w',...
               'class','single');
            Files.(this){iCh} = makeDiskFile(diskPars);
            notifyUser(blockObj,myJob,this,'info',iCh,nCh.(this))
         end
      case 'Events'
         % {{{ To be added: Automate event extraction HERE }}}
         
      case 'Meta' % Each "Meta" file should only have one "channel"
         fName = sprintf(strrep(paths.(this).file,'\','/'),[this '.mat']);
         diskPars = struct('format',blockObj.FileType{idx},...
            'name',fullfile(fName),...
            'size',[1 blockObj.Meta.Header.NumRawSamples],...
            'access','w',...
            'class','int32');
         Files.(this) = makeDiskFile(diskPars);
         
      case 'Streams'
         notifyUser(blockObj,myJob,this,'info');
         infofield = [this 'Channels'];
         info = blockObj.Meta.Header.(infofield);
         infoname = fullfile(paths.(this).info);
         save(fullfile(infoname),'info','-v7.3');
         
         % Get unique subtypes of streams
         [U,~,iU] = unique({info.signal_type});
         
         for ii = 1:numel(U)
            % Each "signal group" has its own file struct
            chIdx = find(iU==ii);
            if isempty(chIdx)
               continue;
            else
               chIdx = reshape(chIdx,1,numel(chIdx));
            end
            nCh.(U{ii}) = numel(chIdx);
            Files.(U{ii}) = cell(nCh.(U{ii}),1);
            
            chCount = 0;
            for iCh = chIdx
               chCount = chCount + 1;
               sampleField = ['Num' info(iCh).signal_type 'Samples'];
               nSamples = blockObj.Meta.Header.(sampleField);
               chName = info(iCh).custom_channel_name;
               fName = sprintf(strrep(paths.(this).file,'\','/'), ...
                  info(iCh).signal_type,chName);
               diskPars = struct('format',blockObj.FileType{idx},...
                  'name',fullfile(fName),...
                  'size',[1 nSamples],...
                  'access','w',...
                  'class','single');
               if strncmpi(U{ii},'dig',3) % DIG files are int8
                  diskPars.class = 'int8';
               end
               Files.(U{ii}){chCount} = makeDiskFile(diskPars);
               notifyUser(blockObj,myJob,this,'info',chCount,nCh.(U{ii}))
            end
         end
         
      otherwise
         warning('No extraction handling for FieldType: %s.',...
            blockObj.FieldType{idx});
         continue;
   end
   
end

%% INITIALIZE INDEXING VECTORS FOR READING CHUNKS OF DATA FROM FILE

% We need buffer variables to read data from file and save it into a
% Matlab-friendly format using matfiles. Those varibles needs to be as
% big as possible to speed up the process. In order to do that we will
% allocate 4/5 of the available memory to those variables.
nDataPoints = blockObj.Meta.Header.BytesPerBlock/2;

end_ = 0; % End of indexing vector (within a block)

availableMemory = getMemory(0.8); % Allocate 80% of available memory
nPerBlock = blockObj.Meta.Header.NumSamplesPerDataBlock;

% Need to account for all buffers to get correct # blocks
memDivisor = nDataPoints * (8 + nBuffers);
nBlocks = min(blockObj.Meta.Header.NumDataBlocks,...
   floor(availableMemory/memDivisor));

info = blockObj.Meta.Header;

%% EXTRACT INDEXING VECTORS
buffer = struct;
scaleFactor = struct;
dataOffset = struct;

time_buffer_index = false(1,nDataPoints);
[time_buffer_index,end_] = getDigBuffer(time_buffer_index,end_,...
   2,nPerBlock,nBlocks);


if (info.NumRawChannels > 0)
   buffer.Raw = zeros(1,nDataPoints,'uint16');
   [buffer.Raw,end_] = getBufferIndex(buffer.Raw,end_,...
      info.NumRawChannels,nPerBlock,nBlocks);
   scaleFactor.Raw = 0.195;
   dataOffset.Raw = 32768;
end

if (info.NumDCChannels > 0)
   buffer.DC = zeros(1,nDataPoints,'uint16');
   [buffer.DC,end_] = getBufferIndex(buffer.DC,end_,...
      info.NumRawChannels,nPerBlock,nBlocks);
   scaleFactor.DC = -0.01923;
   dataOffset.DC = 512;
end

if (info.NumStimChannels > 0)
   buffer.Stim = zeros(1,nDataPoints,'uint16');
   [buffer.Stim,end_] = getBufferIndex(buffer.Stim,end_,...
      info.NumRawChannels,nPerBlock,nBlocks);
   
end

if (info.NumAuxChannels > 0)
   buffer.Aux = zeros(1,nDataPoints,'uint16');
   [buffer.Aux,end_] = getBufferIndex(buffer.Aux,end_,...
      info.NumAuxChannels,nPerBlock/4,nBlocks);
   scaleFactor.Aux = 37.4e-6;
   dataOffset.Aux = 0;
end

if (info.NumSupplyChannels > 0)
   buffer.Supply = zeros(1,nDataPoints,'uint16');
   [buffer.Supply,end_] = getBufferIndex(buffer.Supply,end_,...
      info.NumSupplyChannels,1,nBlocks);
   scaleFactor.Supply = 0.195;
   dataOffset.Supply = 32768;
end

if (info.NumSensorChannels > 0)
   buffer.Sensor = zeros(1,nDataPoints,'uint16');
   [buffer.Sensor,end_] = getBufferIndex(buffer.Sensor,end_,...
      info.NumSensorChannels,1,nBlocks);
   scaleFactor.Sensor = 0.01;
   dataOffset.Sensor = 0;
end


if (info.NumAdcChannels > 0)
   buffer.Adc = zeros(1,nDataPoints,'uint16');
   [buffer.Adc,end_] = getBufferIndex(buffer.Adc,end_,...
      info.NumAdcChannels,nPerBlock,nBlocks);
   scaleFactor.Adc = adc_scale;
   dataOffset.Adc = adc_offset;
end

if (info.NumDacChannels > 0)
   buffer.Dac = zeros(1,nDataPoints,'uint16');
   [buffer.Dac,end_] = getBufferIndex(buffer.Dac,end_,...
      info.NumDacChannels,nPerBlock,nBlocks);
   scaleFactor.Dac = 312.5e-6;
   dataOffset.Dac = 32768;
end

% Get TTL streams as well
digBuffer = struct;
if (info.NumDigInChannels > 0)
   digBuffer.DigIn = false(1,nDataPoints);
   [digBuffer.DigIn,end_] = getDigBuffer(digBuffer.DigIn,end_,...
      1,nPerBlock,nBlocks);
end

if (info.NumDigOutChannels > 0)
   digBuffer.DigOut = false(1,nDataPoints);
   [digBuffer.DigOut,~] = getDigBuffer(digBuffer.DigOut,end_,...
      1,nPerBlock,nBlocks);
   
end

%% READ BINARY DATA
progress=0;
num_gaps = 0;
index = 0;

deBounce = false; % This just for the update job Tag part
F = fieldnames(buffer);
D = fieldnames(digBuffer);

for iBlock=1:ceil(info.NumDataBlocks/nBlocks)
   pct = round(iBlock/nBlocks*100);
   if rem(pct,5)==0 && ~deBounce
      if ~isnan(myJob(1))
         set(myJob,'Tag',sprintf('%s: Saving DATA %g%%',blockObj.Name,pct));
      end
      deBounce = true;
   elseif rem(pct+1,5)==0 && deBounce
      deBounce = false;
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Read binary data.
   blocksToread = min(nBlocks,info.NumDataBlocks-nBlocks*(iBlock-1));
   dataPointsToRead = blocksToread*nDataPoints;
   dataBuffer = uint16(fread(fid, dataPointsToRead, 'uint16=>uint16'))';
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Update the files
   index =uint32( index(end) + 1 : index(end)+nPerBlock*blocksToread);
   
   t=typecast(dataBuffer(time_buffer_index(1:dataPointsToRead)),'int32');
   t = reshape(t,1,numel(t)); % ensure correct orientation
   Files.Time.append(t);
   num_gaps = num_gaps + sum(diff(t) ~= 1);
   
   % Write data to file
   for iF = 1:numel(F)
      writeData(dataBuffer,...
         Files,buffer,scaleFactor,dataOffset,F{iF},dataPointsToRead);
   end
   
   for iD = 1:numel(D)
      writeDigData(dataBuffer,...
         Files,digBuffer,info,D{iD},dataPointsToRead);
   end
   
   clc;
   progress=progress+min(nBlocks,info.NumDataBlocks-nBlocks*(iBlock-1));
   pct = 100 * (progress / info.NumDataBlocks);
   if ~floor(mod(pct,5)) % only increment counter by 5%
      fprintf(1,'Writing data to Matfiles...%.3d%%\n',floor(pct));
   end
end
fprintf(1,newline);
% Check for gaps in timestamps.
if (num_gaps == 0)
   fprintf(1, 'No missing timestamps in data.\n');
else
   fprintf(1, 'Warning: %d gaps in timestamp data found.  Time scale will not be uniform!\n', ...
      num_gaps);
end
% Make sure we have read exactly the right amount of data.
bytes_remaining = filesize - ftell(fid);
if (bytes_remaining ~= 0)
   warning('Error: End of file not reached.');
end

T1=toc;
% Close data file.
fclose(fid);



%% Linking data to blockObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DiskData makes it easy to access data stored in matfies.
% Assigning each file to the right channel

for iCh = 1:blockObj.NumChannels
   blockObj.Channels(iCh).Raw = lockData(Files.Raw{iCh});
end
blockObj.linkToData;

% % % % % % % % % % % % % % % % % % % % % %
if ~isnan(myJob(1))
   set(myJob,'Tag',sprintf('%s: Raw Extraction complete.',blockObj.Name));
end

flag = true;
updateStatus(blockObj,'Raw',true(1,blockObj.NumChannels));

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

function notifyUser(blockObj,myJob,curField,stage,curIdx,totIdx)
%% NOTIFYUSER  Update user of job processing status

% Compute overall completion percentage
if nargin < 6
   pctComplete = 0;
else
   pctComplete = floor(100 * (curIdx / totIdx));
end

% If parallel job, update the job status tag so you can track progress
% using the Parallel Job Monitor
if isa(myJob,'parallel.job.CJSCommunicatingJob')
   set(myJob,'Tag',sprintf('%s: Extracting %s %s...%.3d%%',...
      blockObj.Name,curField,stage,pctComplete));
   
else % Otherwise, print to Command Window
   if pctComplete==0
      fprintf(1, '\t->Extracting %s %s...%.3d%%\n',...
         curField,stage,pctComplete);
   else
      fprintf(1,'\b\b\b\b\b%.3d%%\n',pctComplete);
   end
end
end

function availableMemory = getMemory(pctToAllocate)
%% GETMEMORY   Get available memory based on OS

if ~isunix % For Windows machines:
   [~,MEM]=memory;
   availableMemory=MEM.PhysicalMemory.Available*pctToAllocate;
   
else % For Mac machines:
   [status, cmdout]=system('sysctl hw.memsize | awk ''{print $2}''');
   if status == 0
      fprintf(1,'\nMac OSX detected. Available memory: %s\n',cmdout);
      availableMemory=round(str2double(cmdout)*pctToAllocate);
   else
      availableMemory=2147483648; % (2^31)
   end
end
end

function [idx,end_] = getBufferIndex(idx,end_,nChannels,nPerBlock,nBlocks)
%% GETBUFFERINDEX    Get buffer index

index=(end_+1):(end_+ (nChannels * nPerBlock));
end_ = index(end);
idx(index)=uint16(reshape(repmat(1:nChannels,nPerBlock,1),1,[]));
idx=repmat(idx,1,nBlocks);
end

function [idx,end_] = getDigBuffer(idx,end_,nChannels,nPerBlock,nBlocks)
%% GETDIGBUFFER   Get buffer index for digital "streams"

index = (end_+1):(end_ + (nChannels * nPerBlock));
end_ = index(end);
idx(index)=true;
idx=repmat(idx,1,nBlocks);
end

function writeData(dataBuffer,Files,buffer,scaleFactor,offset,field,dataPointsToRead)
%% WRITEDATA   Write data from buffer to DiskData file
fprintf(1, '\t->Saving %s data...%.3d%%\n',field,0);

nChan = numel(Files.(field));
for iCh=1:nChan % units = microvolts
   Files.(field){iCh}.append( ...
      single(scaleFactor.(field)) * ...
         (single(dataBuffer(buffer.(field)(1:dataPointsToRead)==iCh)) - ...
            single(offset.(field))));
   
   pct = 100 * (iCh /nChan);
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct));
end
end

function writeDigData(dataBuffer,Files,buffer,info,field,dataPointsToRead)
fprintf(1, '\t->Saving %s data...%.3d%%\n',field,0);

data = dataBuffer(buffer.(field)(1:dataPointsToRead));
dataIdx = ismember({info.DigIOChannels.signal_type},field);
dataIdx = find(dataIdx);
if isempty(dataIdx)
   return;
else
   dataIdx = reshape(dataIdx,1,numel(dataIdx));
end

dataCount = 0;
for iCh = dataIdx
   dataCount = dataCount + 1;
   mask = uint16(2^(info.DigIOChannels(iCh).native_order) * ones(size(data)));
   Files.(field){dataCount}.append(int8(bitand(data, mask) > 0));
   
   pct = 100 * (dataCount / numel(dataIdx));
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct));
end

end
