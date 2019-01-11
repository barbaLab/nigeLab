function flag = tdt2Block(blockObj)

%% PARSE INPUT
if nargin < 3
   paths = blockObj.paths;
else % Otherwise, it was run via a "q" command
   myJob = getCurrentJob;
end

if nargin < 2
   recFile = blockObj.RecFile;
end
tic;

header = ReadTDTHeader('NAME',recFile);
TDTNaming =  nigeLab.defaults.TDT();
% this is laziness at its best, I should go through the code and change
% each variable that was inserted in the header structure to header.variable
% but I'm to lazy to do that

FIELDS=fields(header);
for ii=1:numel(FIELDS)
   eval([FIELDS{ii} '=header.(FIELDS{ii});']);
end

fprintf(1, 'Allocating memory for data...\n');
   paths.RW=strrep(paths.RW,'\','/');
   infoname = fullfile(paths.RW,[blockObj.Name '_RawWave_Info.mat']);
   
   if exist('myJob','var')~=0
      set(myJob,'Tag',sprintf('%s: Initializing DiskData arrays...',blockObj.Name));
   end
   
   % One file per probe and channel
   amplifier_dataFile = cell(num_amplifier_channels,1);
   stim_dataFile = cell(num_amplifier_channels,1);
   for iCh = 1:num_amplifier_channels
      pNum  = num2str(amplifier_channels(iCh).port_number);
      chNum = amplifier_channels(iCh).custom_channel_name(regexp(amplifier_channels(iCh).custom_channel_name, '\d'));
      fName = sprintf(strrep(paths.RW_N,'\','/'), pNum, chNum);
      if exist(fName,'file'),delete(fName);end
      amplifier_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
         'class','single','size',[1 num_amplifier_samples],'access','w');
     
      stim_data_fName = strrep(fullfile(paths.DW,'STIM_DATA',[blockObj.Name '_STIM_P%s_Ch_%s.mat']),'\','/');
      fName = sprintf(strrep(stim_data_fName,'\','/'), pNum, chNum);
      if exist(fName,'file'),delete(fName);end
      stim_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
         'class','single','size',[1 num_amplifier_samples],'access','w');
   end
   
   fprintf(1,'Matfiles created succesfully\n');
   fprintf(1,'Exporting files...\n');
   
   fprintf(1, '\t->Extracting streams...%.3d%%\n',0)
   
   %%%%%%%%%%%%%% Raw waveform
   if any(contains(header.fn,TDTNaming.WaveformName))
       for iCh=1:num_amplifier_channels
           ch = amplifier_channels(iCh).native_order;
           pb = amplifier_channels(iCh).port_number;
           block = TDTbin2mat(recFile,'TYPE',{'STREAMS'},'CHANNEL',ch,'VERBOSE',false);
           data = single(block.streams.(TDTNaming.WaveformName{pb}).data * 10^6);  %#ok<*NASGU>
           amplifier_dataFile{iCh}.append(data);
           blockObj.Channels(iCh).Raw = lockData(amplifier_dataFile{iCh});
           fraction_done = 100 * (iCh / num_amplifier_channels);
           fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
       end
   end
   
   %%%%%%%%%%%% Other nonstandard streams
   if any(contains(header.fn,TDTNaming.streamsName))
       for iCh=1:num_amplifier_channels
           pNum  = num2str(amplifier_channels(iCh).port_number);
           chNum = amplifier_channels(iCh).custom_channel_name(regexp(amplifier_channels(iCh).custom_channel_name, '\d'));
           gen_data_fName = TDTNaming.streamsTargetFileName;
           fName = sprintf(strrep(gen_data_fName,'\','/'), pNum, chNum);
           if exist(fName,'file'),delete(fName);end
           generic_dataFile{iCh} = nigeLab.libs.DiskData(blockObj.SaveFormat,fullfile(fName),...
               'class','single','size',[1 num_amplifier_samples],'access','w');
           
           ch = amplifier_channels(iCh).native_order;
           block = TDTbin2mat(recFile,'TYPE',{'STREAMS'},'CHANNEL',ch,'VERBOSE',false);
           for kk=1:numel(TDTNaming.streamsSource)
               data = single(block.streams.(TDTNaming.streamsSource{kk}).data);  %#ok<*NASGU>
               generic_dataFile{iCh}.append(data);
               blockObj.(TDTNaming.streamsTarget{kk}) = lockData(generic_dataFile{iCh});
           end
           fraction_done = 100 * (iCh / num_amplifier_channels);
           fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
       end
   end
   
   fprintf(1, '\t->Extracting epocs info...%.3d%%\n',0);
   if any(contains(header.fn,TDTNaming.evsVar))    % usually used to store events and different experimental conditions
       block = TDTbin2mat(recFile,'TYPE',{'epocs'},'VERBOSE',false);
       for jj=1:numel(TDTNaming.evsVar)
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
           fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
       end % jj, evsVar
   end  % if
   
   
%    fprintf(1, '\t->Extracting snips info...%.3d%%\n',0);
%    if any(strcmp('snips',dataType))     % usually sorted spike snippets. 30 samples
%    end
   
   flag = true;
end