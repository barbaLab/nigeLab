function flag = tdt2Block(blockObj)

%% PARSE INPUT
if nargin < 3
   paths = blockObj.Paths;
else % Otherwise, it was run via a "q" command
   myJob = getCurrentJob;
end

if nargin < 2
   recFile = blockObj.RecFile;
end
tic;
TDTNaming =  nigeLab.defaults.TDT();


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read the file header

header = ReadTDTHeader('NAME',recFile);
blockObj.Meta.Header = fixNamingConvention(header);

% this is laziness at its best, I should go through the code and change
% each variable that was inserted in the header structure to header.variable
% but I'm to lazy to do that

FIELDS=fields(header);
for ii=1:numel(FIELDS)
   eval([FIELDS{ii} '=header.(FIELDS{ii});']);
end
if ~data_present
   warning('No data found in %s.',recFile);
   return;
end

   

%% PRE-ALLOCATE MEMORY FOR WRITING RECORDED VARIABLES TO DISK FILES
% preallocates matfiles for varible that otherwise would require
% nChannles*nSamples matrices

diskPars = struct('format',blockObj.SaveFormat,...
   'name',[],...
   'size',[1 num_raw_samples],...
   'access','w',...
   'class','int32');
Files = struct;

fprintf(1, 'Allocating memory for data...\n');
diskPars.name = fullfile(paths.Time.info);
Files.Time = makeDiskFile(diskPars);

if (num_raw_channels > 0)
   reportProgress(blockObj,'Raw info', 0);
   info = raw_channels;
   infoname = fullfile(paths.Raw.info);
   save(fullfile(infoname),'info','-v7.3');
   % One file per probe and channel
   amplifier_dataFile = cell(num_raw_channels,1);
   for iCh = 1:num_raw_channels
      pNum  = num2str(raw_channels(iCh).port_number);
      chNum = raw_channels(iCh).custom_channel_name(regexp(raw_channels(iCh).custom_channel_name, '\d'));
      fName = sprintf(strrep(paths.Raw.file,'\','/'), pNum, chNum);
      if exist(fName,'file'),delete(fName);end
      amplifier_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
         'class','single','size',[1 num_raw_samples],'access','w');
      fraction_done = 100 * (iCh / num_raw_channels);
   end
end


   fprintf(1,'Matfiles created succesfully\n');
   fprintf(1,'Exporting files...\n');
   
   reportProgress(blockObj,'Raw', 0);
   %%%%%%%%%%%%%% Raw waveform
   if any(contains(header.fn,TDTNaming.WaveformName))
       for iCh=1:num_raw_channels
           ch = raw_channels(iCh).native_order;
           pb = raw_channels(iCh).port_number;
           block = TDTbin2mat(recFile,'TYPE',{'STREAMS'},'CHANNEL',ch,'VERBOSE',false);
           data = single(block.streams.(TDTNaming.WaveformName{pb}).data * 10^6);  %#ok<*NASGU>
           amplifier_dataFile{iCh}.append(data);
           blockObj.Channels(iCh).Raw = lockData(amplifier_dataFile{iCh});
           fraction_done = 100 * (iCh / num_raw_channels);
           reportProgress(blockObj,'Raw', fraction_done);
       end
   end
   
   %%%%%%%%%%%% Other nonstandard streams
   if any(contains(header.fn,TDTNaming.streamsName))
       reportProgress(blockObj,'Streams', 0);
       for iCh=1:num_raw_channels
           pNum  = num2str(raw_channels(iCh).port_number);
           chNum = raw_channels(iCh).custom_channel_name(regexp(raw_channels(iCh).custom_channel_name, '\d'));
           gen_data_fName = TDTNaming.streamsTargetFileName;
           fName = sprintf(strrep(gen_data_fName,'\','/'), pNum, chNum);
           if exist(fName,'file'),delete(fName);end
           generic_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
               'class','single','size',[1 num_amplifier_samples],'access','w');
           
           ch = raw_channels(iCh).native_order;
           block = TDTbin2mat(recFile,'TYPE',{'STREAMS'},'CHANNEL',ch,'VERBOSE',false);
           for kk=1:numel(TDTNaming.streamsSource)
               data = single(block.streams.(TDTNaming.streamsSource{kk}).data);  %#ok<*NASGU>
               generic_dataFile{iCh}.append(data);
               blockObj.(TDTNaming.streamsTarget{kk}) = lockData(generic_dataFile{iCh});
           end
           fraction_done = 100 * (iCh / num_raw_channels);
           reportProgress(blockObj,'Streams', fraction_done);
       end
   end
   
   fprintf(1, '\t->Extracting epocs info...%.3d%%\n',0);
   if any(contains(header.fn,TDTNaming.evsVar))    % usually used to store events and different experimental conditions
       block = TDTbin2mat(recFile,'TYPE',{'epocs'},'VERBOSE',false);
       for jj=1:numel(TDTNaming.evsVar)
           try
           nEvs = numel(block.epocs.(TDTNaming.evsVar{jj}).onset);      % number of events occurring
           events = cell2struct(cell(nEvs,numel(TDTNaming.evsTarget{jj}))',TDTNaming.evsTarget{jj},1); % init events structure
           for ii = 1:nEvs
               for kk = 1:numel(TDTNaming.evsSource)
                   NameParts = strsplit(TDTNaming.evsSource{jj}{kk},'.');
                   S = cell2struct([repmat({'.'},1,numel(NameParts));NameParts],{'type','subs'},1);
                   events(ii).(TDTNaming.evsTarget{jj}{kk}) = ...
                     subsref(block.epocs,S);
               end % kk, evsSource
           end % ii, events
           fraction_done = 100 * (jj / numel(TDTNaming.evsVar));
           reportProgress(blockObj,'Epocs', fraction_done);
           catch er
               nigeLab.utils.cprintf('UnterminatedStrings','Block %s: epoch field %s not found!',blockObj.Name,TDTNaming.evsVar{jj});
           end % try
       end % jj, evsVar
   end  % if
   
   
%    fprintf(1, '\t->Extracting snips info...%.3d%%\n',0);
%    if any(strcmp('snips',dataType))     % usually sorted spike snippets. 30 samples
%    end
   
   flag = true;
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