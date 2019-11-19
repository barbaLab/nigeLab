function flag = initChannels(blockObj)
%% INITCHANNELS   Initialize header information for channels
%
%  flag = INITCHANNELS(blockObj);
%
% By: Max Murphy & Fred Barban 2018 MAECI Collaboration

%% GET HEADER INFO DEPENDING ON RECORDING TYPE
flag = false;
switch blockObj.FileExt
   case '.rhd'
      blockObj.RecType='Intan';
      header=ReadRHDHeader('NAME',blockObj.RecFile,...
                           'VERBOSE',blockObj.Verbose);
      
   case '.rhs'
      blockObj.RecType='Intan';
      header=ReadRHSHeader('NAME',blockObj.RecFile,...
                           'VERBOSE',blockObj.Verbose);                   
      
   case {'', '.Tbk', '.Tdx', '.tev', '.tnt', '.tsq'}
      dName = fileparts(blockObj.RecFile);
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
      
   case '.mat'
      blockObj.RecType='Matfile';
       header = blockObj.ReadMatInfoFileFcn(blockObj.RecFile); 
   otherwise
      blockObj.RecType='other';
      warning('Not a recognized file extension: %s',blockObj.FileExt);
      return;
end

%% ASSIGN DATA FIELDS USING HEADER INFO
blockObj.Channels = header.raw_channels;
blockObj.Meta.Header = fixNamingConvention(header);

if ~blockObj.parseProbeNumbers % Depends on recording system
   warning('Could not properly parse probe identifiers.');
   return;
end
blockObj.NumChannels = header.num_raw_channels;
blockObj.NumAnalogIO = header.num_analogIO_channels;
blockObj.NumDigIO = header.num_digIO_channels;
blockObj.NumProbes = header.num_probes;
blockObj.SampleRate = header.sample_rate;
blockObj.Samples = header.num_raw_samples;

%% SET CHANNEL MASK (OR IF ALREADY SPECIFIED MAKE SURE IT IS CORRECT)
parseChannelID(blockObj);
if isempty(blockObj.Mask)
   blockObj.Mask = 1:blockObj.NumChannels;
else
   blockObj.Mask(blockObj.Mask > blockObj.NumChannels) = [];
   blockObj.Mask(blockObj.Mask < 1) = [];
   blockObj.Mask = reshape(blockObj.Mask,1,numel(blockObj.Mask));
end

flag = true;

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

end