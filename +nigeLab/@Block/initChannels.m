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
                        
      blockObj.DCAmpDataSaved = header.dc_amp_data_saved;
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
      warning('Not a recognized file extension: %s',blockObj.FileExt);
      return;
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

end