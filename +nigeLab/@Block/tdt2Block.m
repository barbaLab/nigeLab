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
   end
   
   fprintf(1,'Matfiles created succesfully\n');
   fprintf(1,'Exporting files...\n');
   
   fprintf(1, '\t->Extracting RAW info...%.3d%%\n',0);
   for iCh=1:num_amplifier_channels
    ch = amplifier_channels(iCh).native_order;
    pb = amplifier_channels(iCh).port_number;
    block = TDTbin2mat(recFile,'TYPE',{'STREAMS'},'CHANNEL',ch,'VERBOSE',false);
    data = single(block.streams.(wav_data{pb}).data * 10^6);  %#ok<*NASGU>
    amplifier_dataFile{iCh}.append(data);
    fraction_done = 100 * (iCh / num_amplifier_channels);
    fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done));
   end
   
   flag = true;
end