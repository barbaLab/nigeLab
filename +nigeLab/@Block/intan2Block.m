function flag = intan2Block(blockObj,fields_to_extract,paths)
%INTAN2BLOCK  Convert Intan binary to nigeLab.Block file structure
%
%  flag = INTAN2BLOCK(blockObj);
%  flag = INTAN2BLOCK(blockObj,fields_to_extract);
%  flag = INTAN2BLOCK(blockObj,fields_to_extract,paths);
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
%  Related `private` functions: ReadRHDHeader, ReadRHSHeader
%
% See also: NIGELAB.BLOCK/DORAWEXTRACTION, NIGELAB.BLOCK/GENPATHS,
% NIGELAB.BLOCK/PARSEHEADER

%PARSE INPUT
flag = false;
UseParallel = blockObj.UseParallel;
if nargin < 3 % If 2 inputs, need to specify default paths struct
   paths = blockObj.Paths;
end

if nargin < 2 % If 1 input, need to specify default fields
   fields_to_extract = blockObj.RecSystem.Fields;
else % otherwise just make sure it is correct orientation
   fields_to_extract = reshape(fields_to_extract,1,numel(fields_to_extract));
end

%PARSE HEADER
fid = fopen(blockObj.Input, 'r');
s = dir(blockObj.Input);
if isempty(s)
   blockObj.reportProgress(...
      '<strong>No files found!</strong> Extraction canceled ::',...
      100,'toWindow','Canceled');
   blockObj.reportProgress('',100,'toEvent');
   return;
end
filesize = s.bytes;
header = blockObj.parseHeader(fid);
switch blockObj.FileExt
   case '.rhd'
      nBuffers = 13;
      
      switch header.EvalBoardMode
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
      nBuffers = 10;
      
      adc_scale = 312.5e-6;
      adc_offset = 32768;
      dac_scale = 312.5e-6;
      dac_offset = 32768;
end

if ~header.DataPresent
   warning('No data found in %s.',recFile);
   return;
end

% Header --> 10%
blockObj.reportProgress('Header parsed.',10,'toEvent');
blockObj.reportProgress('Header parsed.',10,'toWindow','Parsed');

%PRE-ALLOCATE MEMORY FOR WRITING RECORDED VARIABLES TO DISK FILES
% preallocates matfiles for varible that otherwise would require
% nChannles*nSamples matrices

% Files are either "Standard" or "Digital" (due to difference in native
% stream order for digital IO vs all other data streams)
Files = struct('Standard',struct,'Time',[],'Dig',struct);
nCh = struct('Standard',struct,'Time',1,'Dig',struct);
nCh.Standard = struct('Raw',struct('Data',header.NumRawChannels),...
   'AnalogIO',struct('Adc',header.NumAdcChannels,...
                     'Dac',header.NumDacChannels,...
                     'Aux',header.NumAuxChannels,...
                     'Supply',header.NumSupplyChannels,...
                     'Sensor',header.NumSensorChannels),...
   'Stim',header.NumStimChannels,...
   'DC',struct('Data',header.NumDCChannels));
nCh.Dig = struct('DigIO',struct('DigIn',header.NumDigInChannels,'DigOut',header.NumDigOutChannels));
native_order = struct; % For `Streams` fieldType
stimCurr = 0; % Initialize to 0 amps
for f = fields_to_extract
   idx = find(strcmpi(blockObj.Fields,f),1,'first');
   if isempty(idx) % Check if field is present (+defaults/Block config)
      [fmt,idt] = blockObj.getDescriptiveFormatting();
      nigeLab.utils.cprintf('Errors*','%s[INTAN2BLOCK]: ',idt);
      nigeLab.utils.cprintf(fmt,'Field: ''%s'' is invalid\n',f{:});...
         nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
         '\t%s(skipped its extraction)\n',idt);
      continue;
   else  % Make sure case syntax is correct
      curDataField = blockObj.Fields{idx};
   end
   
   switch blockObj.FieldType{idx}
      case 'Channels' % Each "Channels" file has multiple channels
         blockObj.parseProbeNumbers;
         info = header.RawChannels;
         infoname = fullfile(paths.(curDataField).info);
         save(fullfile(infoname),'info','-v7.3');
         % One file per probe and channel
         group = info(1).signal.Group;
         Files.Standard.(curDataField).(group) = cell(blockObj.NumChannels,1);
         nCh.Standard.(curDataField).(group) = header.(['Num' curDataField 'Channels']);
         if header.DCAmpDataSaved
             nCh.Standard.DC.Data = blockObj.NumChannels;
         end
         % Assume data has same # samples per channel
         data = zeros(1,info(1).signal.Samples,'single');
         reportProgress(blockObj,'Header parsed.','clc');
         for iCh = 1:nCh.Standard.(curDataField).(group)
            pNum  = num2str(blockObj.Channels(iCh).probe);
            chNum = blockObj.Channels(iCh).chStr;
            fName = sprintf(paths.(curDataField).file, pNum, chNum);
            nSamples = info(iCh).signal.Samples;
            diskPars = struct(...
               'format','MatFile',... % Should never expand
               'name',fName,...
               'size',[1 nSamples],...
               'access','w',...
               'class','single',...
               'verbose',blockObj.Verbose && ~blockObj.OnRemote);
            Files.Standard.(curDataField).(group){iCh} = ...
               nigeLab.utils.makeDiskFile(diskPars,data);
            pct = 10 + round(iCh/nCh.Standard.(curDataField).(group) * 20);
            reportProgress(blockObj,'Allocating.',pct,'toWindow','Allocating');
            reportProgress(blockObj,'Allocating.',pct,'toEvent');
         end
         reportProgress(blockObj,'Allocating.','clc');
         
      case 'Events' % 'Event' metadata should be ad hoc format, in 'info'       
         % Anything that goes here is just '<EventName>Triggers'
         
         if strcmp(curDataField,'Stim')
            nCh.Standard.Stim = 1; % 'Event' field acts as flag
            stimCurr = header.StimParameters.stim_step_size;
            info = struct('StimParameters',header.StimParameters,...
               'StimTriggers',header.StimTriggers);
            if ~isempty(info.StimTriggers)
               trigCh = unique([info.StimTriggers.amp_trigger_channel]);
               if ~any([info.StimTriggers.voltage_threshold]) % then it's not FSM version
                  trigCh = nan;
               end
            else
               trigCh = nan;
            end
         else
            infofield = [curDataField 'Triggers'];
            info = header.(infofield);
            group = info(1).signal.Group;
            nCh.Standard.(curDataField).(group) = numel(info);
         end
         save(paths.(curDataField).info,'info','-v7.3'); % Small file
         
      case 'Meta' % Each "Meta" file should only have one "channel"
         fName = sprintf(paths.(curDataField).file,[curDataField '.mat']);
         diskPars = struct(...
            'format',blockObj.getFileType(curDataField),...
            'name',fName,...
            'size',[1 header.NumRawSamples],...
            'access','w',...
            'class','int32',...
            'verbose',blockObj.Verbose && ~blockObj.OnRemote);
         % Do not need the substruct here because of the fact it is just
         % 'Time' and is handled differently
         data = zeros(diskPars.size,diskPars.class);
         Files.Time = nigeLab.utils.makeDiskFile(diskPars,data);
         
      case 'Streams'
         infofield = [curDataField 'Channels'];
         info = header.(infofield);
         infoname = fullfile(paths.(curDataField).info);
         save(infoname,'info','-v7.3');

         sig = [info.signal];
         % If there are no streams, then skip this part
         if isempty(sig)
            continue;
         end
         
         %  We know that 'DigIO' should get its own "special" category
         %  due to how the native_order works for indexing the Streams
         %  specifically.
         if strcmp(curDataField,'DigIO')
            bufGroup = 'Dig';
            class_ = 'int8';
         else
            bufGroup = 'Standard';
            class_ = 'single';
         end

         % Know that we only have signals corresponding to a SINGLE field;
         % now we need to get them according to "group" within field 
         %  For example: 
         %  * DigIO: 'DigIn','DigOut' 
         %  * AnalogIO: 'Adc','Dac','Aux','Supply'
         [group,~,iGroup] = unique({sig.Group});

         for gg = 1:numel(group)
            % Get info for this "grouping" within field
            streamIdx = find(iGroup==gg);
            gInfo = info(streamIdx); 
            if isempty(gInfo)
               continue;
            end
            group_ = group{gg};
            native_order.(group_) = [gInfo.native_order];
            % Each "signal group" has its own file struct
            nCh.(bufGroup).(curDataField).(group_) = numel(gInfo);
            Files.(bufGroup).(curDataField).(group_) = cell(...
               nCh.(bufGroup).(curDataField).(group_),1);
            % Assume the same number of samples for any "group" member
            data = zeros(1,gInfo(1).signal.Samples,'single');
            % Iterate on each group member to create diskFile
            for iStream = 1:numel(gInfo)
               bIdx = streamIdx(iStream);
               nSamples = gInfo(iStream).signal.Samples;
               dataFileName = sprintf(paths.(curDataField).file,...
                  blockObj.Streams.(curDataField)(bIdx).signal.Group,...
                  blockObj.Streams.(curDataField)(bIdx).name);
               diskPars = struct(...
                  'format','MatFile',...
                  'name',dataFileName,...
                  'size',[1 nSamples],...
                  'access','w',...
                  'class',class_,...
                  'verbose',blockObj.Verbose && ~blockObj.OnRemote);
               Files.(bufGroup).(curDataField).(group_){iStream} = ...
                  nigeLab.utils.makeDiskFile(diskPars,data);
            end
         end

      otherwise
         warning('No extraction handling for FieldType: %s.',...
            blockObj.FieldType{idx});
         continue;
   end
   
end

% Memory --> 30%
reportProgress(blockObj,'Memory Allocated.',35,'toEvent');
reportProgress(blockObj,'Memory Allocated.',35,'toWindow','Allocated');

%INITIALIZE INDEXING VECTORS FOR READING CHUNKS OF DATA FROM FILE
% We need buffer variables to read data from file and save it into a
% Matlab-friendly format using matfiles. Those varibles needs to be as
% big as possible to speed up the process. In order to do that we will
% allocate 4/5 of the available memory to those variables.
nDataPoints = header.BytesPerBlock/2;

end_ = 0; % End of indexing vector (within a block)

availableMemory = getMemory(0.8); % Allocate 80% of available memory
nPerBlock = header.NumSamplesPerDataBlock;

% Need to account for all buffers to get correct # blocks
memDivisor = nDataPoints * (8 + nBuffers);
nChunks = min(header.NumDataBlocks,...
   floor(availableMemory/memDivisor));

%EXTRACT INDEXING VECTORS
buffer = struct;
formatDataFun = struct;
% dataOffset = struct;

time_buffer_index = false(1,nDataPoints);
[time_buffer_index,end_] = getDigBuffer(time_buffer_index,end_,...
   2,nPerBlock,nChunks);

 
if (nCh.Standard.Raw.Data > 0)
   buffer.Standard.Raw.Data = zeros(1,nDataPoints,'uint16');
   [buffer.Standard.Raw.Data,end_] = getBufferIndex(buffer.Standard.Raw.Data,end_,...
      nCh.Standard.Raw.Data,nPerBlock,nChunks);
   formatDataFun.Raw.Data = @(x,iCh)  (x-32768)*0.195;
   %    dataOffset.Raw = 32768;
end

if (nCh.Standard.DC.Data > 0)
   buffer.Standard.DC.Data = zeros(1,nDataPoints,'uint16');
   [buffer.Standard.DC.Data,end_] = getBufferIndex(buffer.Standard.DC.Data,end_,...
      header.NumRawChannels,nPerBlock,nChunks);
   formatDataFun.DC.Data =  @(x,iCh)  (x - 512)* -0.01923;
   %    dataOffset.DC = 512;
end

if nCh.Standard.Stim > 0 % Then there is 'Stim' data on all channels
   nCh.Standard.Stim = nCh.Standard.Raw.Data; % Stims happen on channels
   buffer.Standard.Stim = zeros(1,nDataPoints,'uint16');
   [buffer.Standard.Stim,end_] = getBufferIndex(buffer.Standard.Stim,end_,...
      nCh.Standard.Stim,nPerBlock,nChunks);
   fName = sprintf(paths.Stim.file,'Stim');  
   nColStimEventFile = 10 + numel(trigCh); 
   data = zeros(1,nColStimEventFile,'single');
   diskPars = struct(...
      'format','Event',...
      'name',fName,...
      'size',[inf, 10 + numel(trigCh)],...
      'access','w',...
      'class','single',...
      'verbose',blockObj.Verbose && ~blockObj.OnRemote);
   Files.Standard.Stim = nigeLab.utils.makeDiskFile(diskPars,data); 

end

if (nCh.Standard.AnalogIO.Aux > 0)
   buffer.Standard.AnalogIO.Aux = zeros(1,nDataPoints,'uint16');
   [buffer.Standard.AnalogIO.Aux,end_] = getBufferIndex(buffer.Standard.AnalogIO.Aux,end_,...
      nCh.Standard.AnalogIO.Aux,nPerBlock/4,nChunks);
   formatDataFun.AnalogIO.Aux = @(x,iCh)  x * 37.4e-6;
   %    dataOffset.Aux = 0;
end

if (nCh.Standard.AnalogIO.Supply > 0)
   buffer.Standard.AnalogIO.Supply = zeros(1,nDataPoints,'uint16');
   [buffer.Standard.AnalogIO.Supply,end_] = getBufferIndex(buffer.Standard.AnalogIO.Supply,end_,...
      nCh.Standard.AnalogIO.Supply,1,nChunks);
   formatDataFun.AnalogIO.Supply = @(x,iCh)  (x - 32768) * 0.195;
   %    dataOffset.Supply = 32768;
end

if (nCh.Standard.AnalogIO.Sensor > 0)
   buffer.Standard.AnalogIO.Sensor = zeros(1,nDataPoints,'uint16');
   [buffer.Standard.AnalogIO.Sensor,end_] = getBufferIndex(buffer.Standard.AnalogIO.Sensor,end_,...
      nCh.Standard.AnalogIO.Sensor,1,nChunks);
   formatDataFun.AnalogIO.Sensor = @(x,iCh)  x * 0.01;
   %    dataOffset.Sensor = 0;
end


if (nCh.Standard.AnalogIO.Adc > 0)
   buffer.Standard.AnalogIO.Adc = zeros(1,nDataPoints,'uint16');
   [buffer.Standard.AnalogIO.Adc,end_] = getBufferIndex(buffer.Standard.AnalogIO.Adc,end_,...
      nCh.Standard.AnalogIO.Adc,nPerBlock,nChunks);
   formatDataFun.AnalogIO.Adc = @(x,iCh)  (x - adc_offset) * adc_scale;
   %    dataOffset.Adc = adc_offset;
end

if (nCh.Standard.AnalogIO.Dac > 0)
   buffer.Standard.AnalogIO.Dac = zeros(1,nDataPoints,'uint16');
   [buffer.Standard.AnalogIO.Dac,end_] = getBufferIndex(buffer.Standard.AnalogIO.Dac,end_,...
      nCh.Standard.AnalogIO.Dac,nPerBlock,nChunks);
   formatDataFun.AnalogIO.Dac = @(x,iCh)  (x - 32768)* 312.5e-6;
   %    dataOffset.Dac = 32768;
end

buffer.Dig.DigIO = struct;
% Get TTL streams as well
if (nCh.Dig.DigIO.DigIn > 0)
   buffer.Dig.DigIO.DigIn = false(1,nDataPoints);
   [buffer.Dig.DigIO.DigIn,end_] = getDigBuffer(buffer.Dig.DigIO.DigIn,end_,...
      1,nPerBlock,nChunks);
end

if (nCh.Dig.DigIO.DigOut > 0)
   buffer.Dig.DigIO.DigOut = false(1,nDataPoints);
   [buffer.Dig.DigIO.DigOut,end_] = getDigBuffer(buffer.Dig.DigIO.DigOut,end_,...
      1,nPerBlock,nChunks);
   
end

% sanity check
if end_~=nDataPoints
   error(['nigeLab:' mfilename ':TheWorstError'],...
      ['[INTAN2BLOCK]: Error during the extraction process.\n' ...
       '\t->\t(Buffer size doesn''t match the datablock size, ' ...
       ' indicating that the recording binary file might be corrupted)']);
end
reportProgress(blockObj,'Memory Allocated.','clc','toWindow');
reportProgress(blockObj,'Indexing complete.',40,'toEvent');
reportProgress(blockObj,'Indexing complete.',40,'toWindow','Indexed');

%READ BINARY DATA
progress=0;
num_gaps = 0;
index = 0;

deBounce = false; % This just for the update job Tag part
standardFields = fieldnames(buffer.Standard);
digStreamFields = fieldnames(buffer.Dig.DigIO);

% only extract data for which we have files
validNamesIndex = ismember(standardFields, fieldnames(Files.Standard));
stimFields = intersect({'Stim'},standardFields(validNamesIndex));
standardFields = setdiff(standardFields(validNamesIndex),{'Stim'});
nStandard = numel(standardFields);
nStimFields = numel(stimFields);
nDig = numel(digStreamFields);
nChunkMax = ceil(header.NumDataBlocks/nChunks);
reportProgress(blockObj,'Indexing complete.','clc','toWindow');
if nChunkMax > 1
   nigeLab.utils.cprintf('Text*','\t\t->\t[INTAN2BLOCK]::%s: ',...
      blockObj.Name); 
   nigeLab.utils.cprintf('Text','File too large to fit in memory\n');
   nigeLab.utils.cprintf('[0.55 0.55 0.55]',...
      '\t\t\t->\t(Split into %d "chunks")',nChunkMax);
end
% Iterate over "chunks" of data
for iChunk=1:nChunkMax
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Read binary data.
   blocksToread = min(nChunks,header.NumDataBlocks-nChunks*(iChunk-1));
   dataPointsToRead = blocksToread*nDataPoints;
   dataBuffer = (fread(fid, dataPointsToRead, 'uint16=>uint16'))';
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Update the files
   index =uint32( index(end) + 1 : index(end)+nPerBlock*blocksToread);
   
   t=typecast(dataBuffer(time_buffer_index(1:dataPointsToRead)),'int32');
   t = reshape(t,1,numel(t)); % ensure correct orientation
   curStartT = get(Files.Time,'Index');
   tSampleIndices = curStartT : (curStartT+numel(t)-1);
   Files.Time(tSampleIndices) = t;
   set(Files.Time,'Index',curStartT + numel(t));
   num_gaps = num_gaps + sum(diff(t) ~= 1);
   
   % Write data to file
   for ii = 1:nStandard
      % Iterate on cell array (char) elements of `standardFields`
      field_ = standardFields{ii};
      if ~isfield(Files.Standard,field_) || ~isfield(buffer.Standard,field_)
         return;
      end
      G = fieldnames(Files.Standard.(field_));
      for iG = 1:numel(G)
         group_ = G{iG};
         fileArray = Files.Standard.(field_).(group_);
         scaleFun = formatDataFun.(field_).(group_);
         streamIndices = buffer.Standard.(field_).(group_)(1:dataPointsToRead);
         o = 40 + round(((ii-1)/((nStandard+nDig) * nChunkMax)+(iChunk-1)/nChunkMax) * 50);
         pmax = round((ii/((nStandard+nDig)*nChunkMax)+(iChunk-1)/nChunkMax) * 50);
         writeData(blockObj,fileArray,dataBuffer,streamIndices,scaleFun,o,pmax);
      end
   end
   
   % Write stim to file
   for iCh = 1:nCh.Standard.Stim
      field_ = 'Stim';
      chMask = buffer.Standard.(field_)(1:dataPointsToRead) == iCh;
      inData = single(dataBuffer(chMask)); 
      outData = single(scaleStimData(inData,stimCurr,blockObj.SampleRate,iCh,trigCh,t));
      append(Files.Standard.Stim,outData);
   end
   
   % Write digIO to file (slightly different handling): Since `digIO` gets
   % `digIn` and `digOut` as 'Group' property members, index by those
   for ii = 1:nDig
      % Iterate on cell array elements (char) of `digStreamFields`
      group_ = digStreamFields{ii}; % group_ (eg digIn or digOut) vs field (digIO)

      fileArray = Files.Dig.DigIO.(group_);
      
      ord = native_order.(group_);
      o = 40 + round((nStandard/((nStandard+nDig)*nChunkMax)+(iChunk-1)/nChunkMax)*50);
      pmax = round((ii/((nStandard+nDig)*nChunkMax)+(iChunk-1)/nChunkMax)* 50);
      
      streamIndices = buffer.Dig.DigIO.(group_)(1:dataPointsToRead);
      data = dataBuffer(streamIndices);
      writeDigData(blockObj,fileArray,data,ord,o,pmax);
   end
end

if isfield(Files.Standard,'Stim')
   Files.Standard.Complete = true; % Set 'Complete' property
   % Note: others that don't use `append` will automatically be set
end

% Check for gaps in timestamps
reportProgress(blockObj,'Writing Data.','clc','toWindow');
if (num_gaps == 0)
   nigeLab.utils.cprintf('Text*','\t\t->\t[INTAN2BLOCK]::%s: ',...
      blockObj.Name); 
   nigeLab.utils.cprintf('[0.5 0.5 0.5]','No missing timestamps.\n');
else
   nigeLab.utils.cprintf('Errors*','\t\t->\t[INTAN2BLOCK]::%s: ',...
      blockObj.Name); 
   nigeLab.utils.cprintf('Keywords*','%d',num_gaps);
   nigeLab.utils.cprintf('Errors',' gaps in timestamp data found.\n');
   nigeLab.utils.cprintf('Comments',...
      '\t\t\t->\t(Time scale will not be uniform!\n');
end
% Make sure we have read exactly the right amount of data.
bytes_remaining = filesize - ftell(fid);
if (bytes_remaining ~= 0)
   warning('Error: End of file not reached.');
end

% Close data file.
fclose(fid);

% Link to data
reportProgress(blockObj,'Linking Data.',95,'toEvent');
reportProgress(blockObj,'Linking Data.',95,'toWindow','Linking');
blockObj.linkToData(intersect({'Raw','AnalogIO','DigIO','Stim'},...
   blockObj.Fields));
flag = true;

% Helper functions below

   % Estimate available memory in order to figure out size of chunks
   function availableMemory = getMemory(pctToAllocate)
      %GETMEMORY   Get available memory based on OS
      %
      %  availableMemory = getMemory(pctToAllocate);
      %
      %  pctToAllocate : Percent of available memory (between 0 and 1) to
      %                  allow for allocation.
      
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

   % Returns the index for elements of the data buffer
   function [idx,end_] = getBufferIndex(idx,end_,nChannels,nPerBlock,nChunks)
      %GETBUFFERINDEX    Get buffer index for all streams but digIO
      %
      %  [idx,end_] = getBufferIndex(idx,end_,nChannels,nPerBlock,nChunks);
      
      bufferIndex=(end_+1):(end_+ (nChannels * nPerBlock));
      end_ = bufferIndex(end);
      idx(bufferIndex)=uint16(reshape(repmat(1:nChannels,nPerBlock,1),1,[]));
      idx=repmat(idx,1,nChunks);
   end

   % Get indexing for digital streams in buffer
   function [idx,end_] = getDigBuffer(idx,end_,nChannels,nPerBlock,nChunks)
      %GETDIGBUFFER   Get buffer index for digital "streams"
      %
      %  [idx,end_] = getDigBuffer(idx,end_,nChannels,nPerBlock,nChunks);
      
      bufferIndex = (end_+1):(end_ + (nChannels * nPerBlock));
      end_ = bufferIndex(end);
      idx(bufferIndex)=true;
      idx=repmat(idx,1,nChunks);
   end
   
   % Write chunk of data streams to disk file
   function writeData(obj,fileArray,dataBuffer,streamIndices,scaleFun,OFFSET,MAXPCT)
      %WRITEDATA  Write digital IO stream data to disk file
      %
      %  writeData(obj,fileArray,dataBuffer,streamIndices,scaleFun);
      %
      %  obj :  nigeLab.Block (for reporting progress to user)
      %  fileArray : Cell array of DiskFile objects (assignment does
      %                 saving)
      %  dataBuffer : "dataBuffer" (a chunk of data with streams mixed into it)
      %  streamIndices : Array that's the same size as dataBuffer. Each
      %                 element corresponds to the indexing element for
      %                 data of a different stream. Used in combination
      %                 with the channel index to create a mask for
      %                 dataBuffer, which is used to get the actual data
      %                 vector.
      %  scaleFun : Function handle for scaling the unsigned integer data      
      %  
      %  - optional -
      %  OFFSET : % "offset" to approximate relative progress in extraction
      %  MAXPCT : % "max" for approximating relative progress in extraction

      nChan = numel(fileArray);
      
      for iich=1:nChan % units = microvolts
         mask = streamIndices==iich; % Identify subset of data to pass
         x = single(dataBuffer(mask)); 
         y = single(scaleFun(x,iich));
         % Get indexing for assignment
         iStart = get(fileArray{iich},'Index');
         sampleIndices = iStart:(iStart+numel(y)-1);
         fileArray{iich}(1,sampleIndices) = y; % Make assignment
         set(fileArray{iich},'Index',iStart + numel(y)); % update indexing
         
         % Report progress to user
         PCT = round(iich /nChan * MAXPCT);
         obj.reportProgress('Writing Data.',OFFSET + PCT,'toEvent');
         obj.reportProgress('Writing Data.',OFFSET + PCT,'toWindow','Writing');
      end
   end

   % Write chunk of digital IO data streams to disk file
   function writeDigData(obj,fileArray,data,order,OFFSET,MAXPCT)
      %WRITEDIGDATA  Write digital IO stream data to disk file
      %
      %  writeDigData(obj,fileArray,data,channelStruct);
      %
      %  obj :  nigeLab.Block (for reporting progress to user)
      %  fileArray : Cell array of DiskFile objects (assignment saves data)
      %  data : from dataBuffer (chunk of data with streams mixed in)
      %        --> This is the "masked" version of dataBuffer that matches
      %              this particular type of stream
      %  order : From header; .native_order property indicating the
      %              ordering of streams natively into the data file
      %  
      %  
      %  - optional -
      %  OFFSET : % "offset" to approximate relative progress in extraction
      %  MAXPCT : % "max" for approximating relative progress in extraction
      
      if nargin < 5
         OFFSET = 65;
      end
      
      if nargin < 6
         MAXPCT = 25;
      end

      N = numel(order);
      for iich = 1:N
         mask = uint16(2^(order(iich)) * ones(size(data)));
         x = int8(bitand(data, mask) > 0);
         % Get indexing for assignment
         iStart = get(fileArray{iich},'Index');
         sampleIndices = iStart:(iStart+numel(x)-1);
         fileArray{iich}(1,sampleIndices) = x; % Make assignment
         set(fileArray{iich},'Index',iStart+numel(x)); % Update indexing
         
         % Report progress to user
         PCT = round(iich/N * MAXPCT);
         obj.reportProgress('Writing Data.',OFFSET + PCT,'toEvent');
         obj.reportProgress('Writing Data.',OFFSET + PCT,'toWindow','Writing');
      end
   end

   % Retrieves correct stimulation data from buffer
   function stim_data_sc = scaleStimData(stim_data,stim_step_size,fs,iCh,iTrigCh,t)
      %SCALESTIMDATA  Retrieves correct stimulation data from buffer.
      %  
      %  stim_data_sc = scaleStimData(stim_data,stim_step_size,fs,iCh);
      %
      %  Note--does not currently return the following information:
      %  * compliance_limit_data
      %  * charge_recovery_data
      %  * amp_settle_data
      %
      %  stim_data : Big matrix of data containing information about
      %              stimuli, where different bits of the 16-bit integer
      %              represent different values.
      %
      %  stim_step_size : Value (amps) 
      %
      %  fs : Sampling rate of amplifier
      %
      %  iCh : Index of amplifier channel for current stim_data
      %
      %  iTrigCh : Index of amplifier channel used in general to trigger
      %              stimuli (or NaN if no such channel was used)
      %
      %  stim_data_sc : Matrix version of stims compatible with 'Event'
      %                 DiskData format
      %  t : vector of times corresponding to the input data stim_data
      origData = stim_data;
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
      % Convert to micro-amps
      stim_curr =   stim_data.*stim_step_size .* 1.0e6; 
      StimDataBin = (stim_data~=0); % find pulses
      % fill the gaps and anticipates the pulse by one sample
      %  --> (corrected later)
      % This step offsets the digital value indicating that a pulse has
      % occurred by one sample, so effectively results in "buffering" the
      % edge of each pulse by 1 sample. The motivation is that if there is
      % a 1-sample "gap" where the indicator for stimulation was lost, we
      % want to fill that in (?)
      % NOTE: if there are stimulus pulses that are actually supposed to be
      % separated by a single sample, this will aggregate them into one
      % pulse.
      % NOTE-2: I (MM) assume we are doing this because it sometimes drops
      % samples during stimulation, which might result in discontinuous
      % vector of logical high values during an actual stimulus pulse (?)
      % Otherwise I do not understand why this is done. Is it when the
      % switch in polarity happens that it has a sample go to zero in
      % between for biphasic stim?
      StimDataBin = StimDataBin(1:end-1) | StimDataBin(2:end);
      
      % This step finds edges by convolving the "expanded" pulses with a
      % positive value followed by a negative value. Because of the order
      % of the convolution operation, this means that the Onset of each
      % pulse "rect" will output a positive value at that sample index and
      % the Offset of each pulse "rect" will output a negative value at
      % that sample index.
      StimDataConv = conv(StimDataBin,[0,1,-1],'same');
      Step = find(StimDataConv); % finds edges (gets negative values also)
      Onset = Step(1:2:end); % odd sample multiples are always "onset"
      ts = double( t( Onset)) ./ fs;      
      Offset = Step(2:2:end); % even sample multiples always "offset"
      nStim = numel(Onset);
      midPt = round((Onset + Offset)/2);
      sz_ = 10 + size(iTrigCh,2); % # columns
      if  nStim~=0
         % If there is a single unique pulse width, do this way
         pw = (Offset-Onset)./fs;

         stim_data_sc = zeros(nStim,11);
         stim_data_sc(:,1) = 1; % "Recording-associated events" % Generically, indicates "type" of Event
         stim_data_sc(:,2) = iCh;   % "value" is the channel
%             stim_data_sc(:,3) % Reserve for # pulses?
         stim_data_sc(:,4) = ts;    % ts == onset (seconds)
         stim_data_sc(:,5) = stim_curr(midPt); % Current level
         stim_data_sc(:,6) = pw; % Pulse-width (seconds) 
         stim_data_sc(:,7) = compliance_limit_data(midPt); % Is compliance-limit reached?
         stim_data_sc(:,8) = charge_recovery_data(midPt); % Is charge-recovery on?
         stim_data_sc(:,9) = amp_settle_data(midPt); % Is amp settle on?
         stim_data_sc(:,10) = stim_polarity(midPt); % Polarity of current
         stim_data_sc(:,11:sz_) = ones(nStim,1)*iTrigCh; % trigger channel
      else
         stim_data_sc = zeros(0,sz_);
      end
   end
end