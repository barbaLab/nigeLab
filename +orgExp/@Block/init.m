function init(blockObj)
%% INIT Initialize BLOCK object
%
%  b = orgExp.Block();
%
%  Note: INIT is a protected function and will always be called on
%        construction of BLOCK.
%
%  By: Max Murphy       v1.0  08/25/2017  Original version (R2017a)
%      Federico Barban  v2.0  07/08/2018
%      MAECI 2018       v3.0  11/28/2018

%% LOAD DEFAULT PARAMETERS
[pars,blockObj.Fields] = orgExp.defaults.Block;

%% PARSE NAME INFO
% Parse name and extension. "nameParts" contains parsed variable strings:
[~,blockObj.Name,blockObj.File_extension] = fileparts(blockObj.RecFile);
nameParts=strsplit(blockObj.Name,{pars.Delimiter '.'});

% Parse variables from defaults.Block "template," which match delimited
% elements of block recording name:
expression = sprintf('\\%c\\w*|\\%c\\w*',pars.includeChar,pars.discardChar);
[splitStr]=regexp(pars.namingConvention,expression,'match');

% Find which delimited elements correspond to variables that should be 
% included by looking at the leading character from the defaults.Block
% template string:
includedVarIndices=find(cellfun(@(x) x(1)=='$',splitStr));
P = properties(blockObj);

% Create a struct to allow creation of dynamic variable name dictionary
dynamicVars = struct;
for ii=includedVarIndices
   varName = upper( deblank( splitStr{ii}(2:end)));
   dynamicVars.(varName) = nameParts{ii};
   
   % If this variable is a property, assign it:
   Prop = P(ismember(upper(P),varName));
   if ~isempty(Prop)
      blockObj.(Prop{:}) = nameParts{ii};
   end
end

% If Recording_date isn't one of the specified "template" variables from
% pars.namingConvention, then parse it from YEAR, MONTH, and DATE:
if isempty(blockObj.Recording_date)
   if isfield(varName,'YEAR') && ...
      isfield(varName,'MONTH') && ...
      isfield(varName,'DAY')
      YY = varName.YEAR((end-1):end);
      MM = varName.MONTH;
      DD = sprintf('%.2d',str2double(varName.DAY));
      blockObj.Recording_date = [YY MM DD];
   else
      blockObj.Recording_date = 'YY MM DD';
      warning('Unable to parse date from BLOCK name (%s).',blockObj.Name);
   end
end

% blockObj.SaveLoc is probably empty [] at this point, which will prompt a
% UI to point to the block save directory:
blockObj.setSaveLocation(blockObj.SaveLoc);
blockObj.SaveFormat = pars.SaveFormat;

if exist(blockObj.SaveLoc,'dir')==0
   mkdir(fullfile(blockObj.SaveLoc));
end

%% EXTRACT HEADER INFORMATION
switch blockObj.File_extension
   case '.rhd'
      blockObj.RecType='Intan';
      header=orgExp.libs.RHD_read_header('NAME',blockObj.Path,...
                                         'VERBOSE',blockObj.Verbose);
   case '.rhs'
      blockObj.RecType='Intan';
      header=orgExp.libs.RHS_read_header('NAME',blockObj.Path,...
                                         'VERBOSE',blockObj.Verbose);
   otherwise
      blockObj.RecType='other';
end

%% ASSIGN DATA FIELDS USING HEADER INFO
blockObj.Channels = header.amplifier_channels;
blockObj.numChannels = header.num_amplifier_channels;
blockObj.numProbes = header.num_probes;
% blockObj.dcAmpDataSaved = header.dc_amp_data_saved;
blockObj.numADCchannels = header.num_board_adc_channels;
% blockObj.numDACChannels = header.num_board_dac_channels;
blockObj.numDigInChannels = header.num_board_dig_in_channels;
blockObj.numDigOutChannels = header.num_board_dig_out_channels;
blockObj.Sample_rate = header.sample_rate;
blockObj.Samples = header.num_amplifier_samples;
% blockObj.DACChannels = header.board_dac_channels;
blockObj.ADCChannels = header.board_adc_channels;
blockObj.DigInChannels = header.board_dig_in_channels;
blockObj.DigOutChannels = header.board_dig_out_channels;
blockObj.Sample_rate = header.sample_rate;
blockObj.Samples = header.num_amplifier_samples;

blockObj.updateStatus('init');

blockObj.save;
end