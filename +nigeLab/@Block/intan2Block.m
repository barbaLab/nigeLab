function flag = intan2Block(blockObj,fields,paths)
%INTAN2BLOCK  Convert Intan binary to nigeLab.Block file structure
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

%PARSE INPUT
flag = false;
UseParallel = blockObj.UseParallel;
if nargin < 3 % If 2 inputs, need to specify default paths struct
   paths = blockObj.Paths;
end

if nargin < 2 % If 1 input, need to specify default fields
   fields = blockObj.RecSystem.Fields;
else % otherwise just make sure it is correct orientation
   fields = reshape(fields,1,numel(fields));
end

%PARSE HEADER
fid = fopen(blockObj.RecFile, 'r');
s = dir(blockObj.RecFile);
if isempty(s)
   blockObj.reportProgress('<strong>No files found!</strong> Extraction aborted ::',...
      100,'toWindow','Aborted');
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
end

if ~header.DataPresent
   warning('No data found in %s.',recFile);
   return;
end

% Header --> 10%
blockObj.reportProgress('Parsed header.',10,'toEvent');
blockObj.reportProgress('Header parsed.',10,'toWindow','Parsed');

%PRE-ALLOCATE MEMORY FOR WRITING RECORDED VARIABLES TO DISK FILES
% preallocates matfiles for varible that otherwise would require
% nChannles*nSamples matrices

fprintf(1, 'Allocating memory for data...\n');

Files = struct;
nCh = struct;
for f = fields
   idx = find(strcmpi(blockObj.Fields,f),1,'first');
   if isempty(idx)
      nigeLab.utils.cprintf('UnterminatedStrings','Field: ''%s'' is invalid.\n',f{:});...
      nigeLab.utils.cprintf('Text','-->\tSkipped its extraction.\n');
      continue;
   else
      curDataField = blockObj.Fields{idx}; % Make sure case syntax is correct
   end

   switch blockObj.FieldType{idx}
      case 'Channels' % Each "Channels" file has multiple channels
         blockObj.parseProbeNumbers;
         info = header.RawChannels;
         infoname = fullfile(paths.(curDataField).info);
         save(fullfile(infoname),'info','-v7.3');
         % One file per probe and channel
         Files.(curDataField) = cell(blockObj.NumChannels,1);
         nCh.(curDataField) = blockObj.NumChannels;
         diskPars.class = 'single';
         for iCh = 1:nCh.(curDataField)
            pNum  = num2str(blockObj.Channels(iCh).probe);
            chNum = blockObj.Channels(iCh).chStr;
            fName = sprintf(strrep(paths.(curDataField).file,'\','/'), pNum, chNum);
            nSamples = info(iCh).signal.Samples;
            diskPars = struct('format',blockObj.getFileType(curDataField),...
               'name',fullfile(fName),...
               'size',[1 nSamples],...
               'access','w',...
               'class','single');
            Files.(curDataField){iCh} = nigeLab.utils.makeDiskFile(diskPars);
            pct = round(iCh/nCh.(curDataField) * 30);
            reportProgress(blockObj,[curDataField ' info'], pct,'toWindow','Allocating');
            reportProgress(blockObj,'Allocating.',pct,'toEvent');
         end
      case 'Events'
         fName = sprintf(strrep(paths.(curDataField).file,'\','/'), curDataField);
         diskPars = struct('format',blockObj.getFileType(curDataField),...
            'name',fullfile(fName),...
            'size',[inf inf],...
            'access','w',...
            'class','single');
         
         if strcmp(curDataField,'Stim')
            info = header.SpikeTriggers;
            Files.(curDataField)(1:numel(info))= {(nigeLab.utils.makeDiskFile(diskPars))};
            nCh.(curDataField) = numel(info);
         else
           Files.(curDataField)(1)= {(nigeLab.utils.makeDiskFile(diskPars))};
            nCh.(curDataField) = 1;
         end

         % {{{ To be added: Automate event extraction HERE }}}
         
      case 'Meta' % Each "Meta" file should only have one "channel"
         fName = sprintf(strrep(paths.(curDataField).file,'\','/'),[curDataField '.mat']);
         diskPars = struct('format',blockObj.getFileType(curDataField),...
            'name',fullfile(fName),...
            'size',[1 header.NumRawSamples],...
            'access','w',...
            'class','int32');
         Files.(curDataField){1} = nigeLab.utils.makeDiskFile(diskPars);
         
      case 'Streams'
         infofield = [curDataField 'Channels'];
         info = header.(infofield);
         infoname = fullfile(paths.(curDataField).info);
         save(fullfile(infoname),'info','-v7.3');
         
         [pname,f_str,ext] = fileparts(nigeLab.utils.getUNCPath(...
            paths.(curDataField).file));
         
         % Get unique subtypes of streams
         sig = [info.signal];
         if isempty(sig)
            continue;
         end
         [U,~,iU] = unique({sig.Source});
         
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
               nSamples = info(iCh).signal.Samples;
               chName = info(iCh).custom_channel_name;
               dataFileName = nigeLab.utils.getUNCPath(fullfile(...
                  pname,...
                  [sprintf(f_str,blockObj.Streams.(curDataField)(chCount).signal.Group,...
                     blockObj.Streams.(curDataField)(chCount).name),ext]));
               diskPars = struct('format',blockObj.getFileType(curDataField),...
                  'name',fullfile(dataFileName),...
                  'size',[1 nSamples],...
                  'access','w',...
                  'class','single');
               if strncmpi(info(iCh).signal.SubGroup,'dig',3) % DIG files are int8
                  diskPars.class = 'int8';
               end
               Files.(U{ii}){chCount} = nigeLab.utils.makeDiskFile(diskPars);
            end
         end
         
      otherwise
         warning('No extraction handling for FieldType: %s.',...
            blockObj.FieldType{idx});
         continue;
   end
   
end
% Memory --> 30%
blockObj.reportProgress('Memory Allocated.',35,'toEvent');
blockObj.reportProgress('Memory Allocated.',35,'toWindow','Allocated');

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
nBlocks = min(header.NumDataBlocks,...
   floor(availableMemory/memDivisor));

%EXTRACT INDEXING VECTORS
buffer = struct;
formatDataFun = struct;
% dataOffset = struct;

time_buffer_index = false(1,nDataPoints);
[time_buffer_index,end_] = getDigBuffer(time_buffer_index,end_,...
   2,nPerBlock,nBlocks);


if (header.NumRawChannels > 0)
   buffer.Raw = zeros(1,nDataPoints,'uint16');
   [buffer.Raw,end_] = getBufferIndex(buffer.Raw,end_,...
      header.NumRawChannels,nPerBlock,nBlocks);
   formatDataFun.Raw = @(x,iCh)  (x-32768)*0.195;
%    dataOffset.Raw = 32768;
end

if (header.NumDCChannels > 0)
   buffer.DC = zeros(1,nDataPoints,'uint16');
   [buffer.DC,end_] = getBufferIndex(buffer.DC,end_,...
      header.NumRawChannels,nPerBlock,nBlocks);
   formatDataFun.DC =  @(x,iCh)  (x - 512)* -0.01923;
%    dataOffset.DC = 512;
end

if (header.NumStimChannels > 0)
   buffer.Stim = zeros(1,nDataPoints,'uint16');
   [buffer.Stim,end_] = getBufferIndex(buffer.Stim,end_,...
      header.NumRawChannels,nPerBlock,nBlocks);
   formatDataFun.Stim = @(x,iCh) scaleStimData(x,header.StimParameters.stim_step_size,blockObj.SampleRate,iCh);
end

if (header.NumAuxChannels > 0)
   buffer.Aux = zeros(1,nDataPoints,'uint16');
   [buffer.Aux,end_] = getBufferIndex(buffer.Aux,end_,...
      header.NumAuxChannels,nPerBlock/4,nBlocks);
   formatDataFun.Aux = @(x,iCh)  x * 37.4e-6;
%    dataOffset.Aux = 0;
end

if (header.NumSupplyChannels > 0)
   buffer.Supply = zeros(1,nDataPoints,'uint16');
   [buffer.Supply,end_] = getBufferIndex(buffer.Supply,end_,...
      header.NumSupplyChannels,1,nBlocks);
   formatDataFun.Supply = @(x,iCh)  (x - 32768) * 0.195;
%    dataOffset.Supply = 32768;
end

if (header.NumSensorChannels > 0)
   buffer.Sensor = zeros(1,nDataPoints,'uint16');
   [buffer.Sensor,end_] = getBufferIndex(buffer.Sensor,end_,...
      header.NumSensorChannels,1,nBlocks);
   formatDataFun.Sensor = @(x,iCh)  x * 0.01;
%    dataOffset.Sensor = 0;
end


if (header.NumAdcChannels > 0)
   buffer.Adc = zeros(1,nDataPoints,'uint16');
   [buffer.Adc,end_] = getBufferIndex(buffer.Adc,end_,...
      header.NumAdcChannels,nPerBlock,nBlocks);
   formatDataFun.Adc = @(x,iCh)  (x - adc_offset) * adc_scale;
%    dataOffset.Adc = adc_offset;
end

if (header.NumDacChannels > 0)
   buffer.Dac = zeros(1,nDataPoints,'uint16');
   [buffer.Dac,end_] = getBufferIndex(buffer.Dac,end_,...
      header.NumDacChannels,nPerBlock,nBlocks);
   formatDataFun.Dac = @(x,iCh)  (x - 32768)* 312.5e-6;
%    dataOffset.Dac = 32768;
end

% Get TTL streams as well
digBuffer = struct;
if (header.NumDigInChannels > 0)
   digBuffer.DigIn = false(1,nDataPoints);
   [digBuffer.DigIn,end_] = getDigBuffer(digBuffer.DigIn,end_,...
      1,nPerBlock,nBlocks);
end

if (header.NumDigOutChannels > 0)
   digBuffer.DigOut = false(1,nDataPoints);
   [digBuffer.DigOut,end_] = getDigBuffer(digBuffer.DigOut,end_,...
      1,nPerBlock,nBlocks);
   
end

% sanity check 
if end_~=nDataPoints
   error('Error during the extraction process(buffer size doesn''t match the datablock size), the data file might be corrupted.'); 
end
blockObj.reportProgress('Indexing complete.',40,'toEvent');
blockObj.reportProgress('Indexing complete.',40,'toWindow','Indexed');

%READ BINARY DATA
progress=0;
num_gaps = 0;
index = 0;
  
deBounce = false; % This just for the update job Tag part
F = fieldnames(buffer);
D = fieldnames(digBuffer);

% only extract data for which we have files
F = F(ismember(F, fieldnames(Files))); 
nF = numel(F);
D = D(ismember(D, fieldnames(Files)));
nD = numel(D);
fprintf(1,'File too long to safely load in memory.\n');
fprintf(1, '-->\tSplit into %d blocks',ceil(header.NumDataBlocks/nBlocks));
NB = ceil(header.NumDataBlocks/nBlocks);
for iBlock=1:NB

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Read binary data.
   blocksToread = min(nBlocks,header.NumDataBlocks-nBlocks*(iBlock-1));
   dataPointsToRead = blocksToread*nDataPoints;
   dataBuffer = (fread(fid, dataPointsToRead, 'uint16=>uint16'))';
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Update the files
   index =uint32( index(end) + 1 : index(end)+nPerBlock*blocksToread);
   
   t=typecast(dataBuffer(time_buffer_index(1:dataPointsToRead)),'int32');
   t = reshape(t,1,numel(t)); % ensure correct orientation
   Files.Time{1}.append(t);
   num_gaps = num_gaps + sum(diff(t) ~= 1);
   
   % Write data to file
   for iF = 1:numel(F)
      writeData(blockObj,dataBuffer,...
         Files,buffer,formatDataFun,F{iF},dataPointsToRead,iF,nF,nD,NB);
   end
   
   for iD = 1:numel(D)
      writeDigData(blockObj,dataBuffer,...
         Files,digBuffer,info,D{iD},dataPointsToRead,iD,nF,nD,NB);
      
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

% Close data file.
fclose(fid);

% Link to data
blockObj.reportProgress('Linking Data.',95,'toEvent');
blockObj.reportProgress('Linking Data.',95,'toWindow','Linking');
blockObj.linkToData(intersect({'Raw','AnalogIO','DigIO','Stim'},...
                              blockObj.Fields));
flag = true;

end

function availableMemory = getMemory(pctToAllocate)
%GETMEMORY   Get available memory based on OS

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
%GETBUFFERINDEX    Get buffer index

index=(end_+1):(end_+ (nChannels * nPerBlock));
end_ = index(end);
idx(index)=uint16(reshape(repmat(1:nChannels,nPerBlock,1),1,[]));
idx=repmat(idx,1,nBlocks);
end

function [idx,end_] = getDigBuffer(idx,end_,nChannels,nPerBlock,nBlocks)
%GETDIGBUFFER   Get buffer index for digital "streams"

index = (end_+1):(end_ + (nChannels * nPerBlock));
end_ = index(end);
idx(index)=true;
idx=repmat(idx,1,nBlocks);
end

function writeData(blockObj,dataBuffer,Files,buffer,scaleFun,field,dataPointsToRead,iCur,Nf,Nd,NChunk)
%WRITEDATA   Write data from buffer to DiskData file
if ~isfield(Files,field) || ~isfield(buffer,field)
   return;
end

nChan = numel(Files.(field));
OFFSET = 40 + round((iCur-1)/((Nf+Nd) * NChunk) * 100);
MAXPCT = 25/NChunk;
for iCh=1:nChan % units = microvolts
   Files.(field){iCh}.append( ...
      single(scaleFun.(field)(...
          single(dataBuffer(...
                 buffer.(field)(1:dataPointsToRead)==iCh)),iCh)));
   
   PCT = round(iCh /nChan * MAXPCT);
   blockObj.reportProgress('Writing Data.',OFFSET + PCT,'toEvent');
   blockObj.reportProgress('Writing Data.',OFFSET + PCT,'toWindow','Writing');
end
end

function writeDigData(blockObj,dataBuffer,Files,buffer,info,field,dataPointsToRead,iCur,Nf,Nd,NChunk)
data = dataBuffer(buffer.(field)(1:dataPointsToRead));
sig = [header.DigIOChannels.signal];
dataIdx = ismember({sig.Field},field);
dataIdx = find(dataIdx);
if isempty(dataIdx)
   return;
else
   dataIdx = reshape(dataIdx,1,numel(dataIdx));
end

OFFSET = 40 + round((iCur-1+Nf)/((Nf+Nd) * NChunk) * 100);
MAXPCT = 25/NChunk;
dataCount = 0;
for iCh = dataIdx
   dataCount = dataCount + 1;
   mask = uint16(2^(header.DigIOChannels(iCh).native_order) * ones(size(data)));
   Files.(field){dataCount}.append(int8(bitand(data, mask) > 0));
   
   PCT = round(dataCount/numel(dataIdx) * MAXPCT);
   blockObj.reportProgress('Writing Data.',OFFSET + PCT,'toEvent');
   blockObj.reportProgress('Writing Data.',OFFSET + PCT,'toWindow','Writing');
end
end

function formatteData = scaleStimData(stim_data,stim_step_size,fs,iCh)
%SCALESTIMEDATA function do retrieve correct stimulation data from buffer. 
% compliance_limit_data, charge_recovery_data, amp_settle_data are not
% returned yet (if usefull might be in the future)
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
   ScaleData =   stim_step_size * stim_data / 1.0e-6; % units = microamps
   StimDataBin = (stim_data~=0); % find pulses
   StimDataBin = StimDataBin(1:end-1) | StimDataBin(2:end); % fill the gaps and anticipates the pulse by one sample(corrected later)
   Step = find (conv(StimDataBin,[0,1,-1],'same')); % finds edges
   Onset = Step(1:2:end);
   Offset = Step(2:2:end);
   nStim = numel(Onset);
   if  nStim~=0
      if numel(unique(Offset-Onset))==1
         l = unique(Offset-Onset);
         formatteData = zeros(nStim,4+l+1);
         formatteData(:,2) = iCh;    % value
         formatteData(:,4) = Onset./fs;           % ts
         formatteData(:,5:end) = ScaleData((Onset)'+(0:l));           % ts
      else
         formatteData = zeros(nStim,6);
         formatteData(:,2) = ScaleData(Onset);    % value
         formatteData(:,4) = Onset./fs;           % ts
      end
   else
      formatteData = [];
   end
end