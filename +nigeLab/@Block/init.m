function flag = init(blockObj)
%% INIT Initialize BLOCK object
%
%  b = nigeLab.Block();
%
%  Note: INIT is a protected function and will always be called on
%        construction of BLOCK. Returns a "true" flag if executed
%        successfully.
%
%  By: Max Murphy       v1.0  08/25/2017  Original version (R2017a)
%      Federico Barban  v2.0  07/08/2018
%      MAECI 2018       v3.0  11/28/2018

%% PARSE NAME INFO
% Set flag for output if something goes wrong
flag = false; 

% Parse name and extension. "nameParts" contains parsed variable strings:
[dName,fName,blockObj.FileExt] = fileparts(blockObj.RecFile);
nameParts=strsplit(fName,[blockObj.Delimiter {'.'}]);

% Parse variables from defaults.Block "template," which match delimited
% elements of block recording name:
regExpStr = sprintf('\\%c\\w*|\\%c\\w*',...
   blockObj.IncludeChar,...
   blockObj.DiscardChar);
splitStr = regexp(blockObj.DynamicVarExp,regExpStr,'match');

% Find which delimited elements correspond to variables that should be 
% included by looking at the leading character from the defaults.Block
% template string:
incVarIdx = find(cellfun(@(x) x(1)=='$',splitStr));
incVarIdx = reshape(incVarIdx,1,numel(incVarIdx));

% Find which set of variables (the total number available from the name, or
% the number set to be read dynamically from the naming convention) has
% fewer elements, and use that to determine how many loop iterations there
% are:
nMin = min(numel(incVarIdx),numel(nameParts));

% Create a struct to allow creation of dynamic variable name dictionary.
% Make sure to iterate on 'splitStr', and not 'nameParts,' because variable
% assignment should be decided by the string in namingConvention property.
dynamicVars = struct;
for ii=1:nMin 
   splitStrIdx = incVarIdx(ii);
   varName = deblank( splitStr{splitStrIdx}(2:end));
   dynamicVars.(varName) = nameParts{incVarIdx(ii)};
end

% If Recording_date isn't one of the specified "template" variables from
% namingConvention property, then parse it from Year, Month, and Day. This
% will be helpful for handling file names for TDT recording blocks, which
% don't automatically append the Rec_date and Rec_time strings:
f = fieldnames(dynamicVars);
if sum(ismember(f,{'Rec_date'})) < 1
   if isfield(dynamicVars,'Year') && ...
      isfield(dynamicVars,'Month') && ...
      isfield(dynamicVars,'Day')
      YY = dynamicVars.Year((end-1):end);
      MM = dynamicVars.Month;
      DD = sprintf('%.2d',str2double(dynamicVars.Day));
      dynamicVars.RecDate = [YY MM DD];
   else
      dynamicVars.RecDate = 'YYMMDD';
      warning('Unable to parse date from BLOCK name (%s).',fName);
   end
end

% Similarly, if recording_time is empty, still keep it as a field in
% metadata associated with the BLOCK.
if sum(ismember(f,{'Rec_time'})) < 1
   dynamicVars.RecTime = 'hhmmss';
end

blockObj.Meta = dynamicVars;

%% PARSE BLOCKOBJ.NAME, USING BLOCKOBJ.NAMINGCONVENTION
str = [];
nameCon = blockObj.NamingConvention;
for ii = 1:numel(nameCon)
   if isfield(dynamicVars,nameCon{ii})
      str = [str, ...
         dynamicVars.(nameCon{ii}),...
         blockObj.Delimiter]; %#ok<AGROW>
   end
end
blockObj.Name = str(1:(end-1));

%% GET/CREATE SAVE LOCATION FOR BLOCK

% blockObj.SaveLoc is probably empty [] at this point, which will prompt a
% UI to point to the block save directory:
if ~blockObj.setSaveLocation(blockObj.SaveLoc)
   flag = false;
   warning('Save location not set successfully.');
   return;
end

if exist(blockObj.SaveLoc,'dir')==0
   mkdir(fullfile(blockObj.SaveLoc));
   makeLink = false;
else
   makeLink = true;
end

%% EXTRACT HEADER INFORMATION
switch blockObj.FileExt
   case '.rhd'
      blockObj.RecType='Intan';
      header=ReadRHDHeader('NAME',blockObj.RecFile,...
                           'VERBOSE',blockObj.Verbose);
      blockObj.NumADCchannels = header.num_board_adc_channels;
      blockObj.NumDigInChannels = header.num_board_dig_in_channels;
      blockObj.NumDigOutChannels = header.num_board_dig_out_channels;
      blockObj.ADCChannels = header.board_adc_channels;
      blockObj.DigInChannels = header.board_dig_in_channels;
      blockObj.DigOutChannels = header.board_dig_out_channels;
      
   case '.rhs'
      blockObj.RecType='Intan';
      header=ReadRHSHeader('NAME',blockObj.RecFile,...
                           'VERBOSE',blockObj.Verbose);
                        
%       blockObj.DcAmpDataSaved = header.dc_amp_data_saved;
      blockObj.NumDACChannels = header.num_board_dac_channels;
      blockObj.NumADCchannels = header.num_board_adc_channels;
      blockObj.NumDigInChannels = header.num_board_dig_in_channels;
      blockObj.NumDigOutChannels = header.num_board_dig_out_channels;
      blockObj.DACChannels = header.board_dac_channels;
      blockObj.ADCChannels = header.board_adc_channels;
      blockObj.DigInChannels = header.board_dig_in_channels;
      blockObj.DigOutChannels = header.board_dig_out_channels;
      
   case {'', '.Tbk', '.Tdx', '.tev', '.tnt', '.tsq'}
      files = dir(fullfile(dName,'*.t*'));
      if ~isempty(files)
         blockObj.RecType='TDT';
         blockObj.RecFile = fullfile(dName);
         header=ReadTDTHeader('NAME',blockObj.RecFile,...
                           'VERBOSE',blockObj.Verbose);
         for ff=fieldnames(blockObj.Meta)'
            if isfield(header.info,ff{:})
               blockObj.Meta.(ff{:}) = header.info.(ff{:});
            end
         end
      end
   otherwise
      blockObj.RecType='other';
end

%% ASSIGN DATA FIELDS USING HEADER INFO
blockObj.Channels = header.amplifier_channels;
if ~blockObj.parseProbeNumbers % Depends on recording system
   warning('Could not properly parse probe identifiers.');
   return;
end
blockObj.NumChannels = header.num_amplifier_channels;
blockObj.NumProbes = header.num_probes;
blockObj.SampleRate = header.sample_rate;
blockObj.Samples = header.num_amplifier_samples;


blockObj.updateStatus('init');
if makeLink
   fprintf(1,'Extracted files found, linking data...\n');
   blockObj.linkToData(makeLink);
   fprintf(1,'\t->complete.\n');
end

%% SAVING
blockObj.save;
flag = true;

end