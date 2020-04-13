function fieldNames = initDesiredHeaderFields(RecType)
%INITDESIREDHEADERFIELDS  Returns array of desired header fields 
%                         (previously: Desired_Outputs in parseHeader fcn)
%
%  fieldNames = nigeLab.utils.INITDESIREDHEADERFIELDS;
%  --> Returns ALL possible header fields
%
%  fieldNames = nigeLab.utils.INITDESIREDHEADERFIELDS(RecType);
%  --> Returns fields relevant to RecType

%% Parse inputs
% If no input is given, then specify 'All'
if nargin < 1
   RecType = 'All';
   % List of types included in 'All'
   % This should be expanded if new systems are added for compatibility:
   includedTypes = {'RHD','RHS','TDT'};
end

% If cell array is given, then get the Union of all fields to be parsed
if iscell(RecType)
   fieldNames = {};
   for i = 1:numel(RecType)
      fieldNames = union(fieldNames,...
         nigeLab.utils.initDesiredHeaderFields(RecType{i}));
   end
   return;
end

%% Switch for enumerating different kinds of recording types
switch RecType
   case 'All'
      fieldNames = nigeLab.utils.initDesiredHeaderFields(includedTypes);      
   case 'RHD'
      %% Enumerated list for Intan RHD system/headstage
      fieldNames = {
         'data_present';
         'DC_amp_data_saved';
         'eval_board_mode';
         'sample_rate';
         'frequency_parameters';
         'raw_channels';
         'analogIO_channels';
         'digIO_channels';
         'spike_triggers';
         'num_raw_channels';
         'num_DC_channels';
         'num_stim_channels';
         'num_digIO_channels';
         'num_analogIO_channels';
         'num_aux_channels';
         'num_supply_channels';
         'num_sensor_channels';
         'num_adc_channels';
         'num_dac_channels';
         'num_dig_in_channels';
         'num_dig_out_channels';
         'probes';
         'num_probes';
         'num_data_blocks';
         'num_samples_per_data_block';
         'num_raw_samples';
         'num_DC_samples';
         'num_stim_samples';
         'num_aux_samples';
         'num_supply_samples';
         'num_sensor_samples';
         'num_adc_samples';
         'num_dac_samples';
         'num_dig_in_samples';
         'num_dig_out_samples';
         'header_size';
         'filesize';
         'bytes_per_block';
         'data_file_main_version_number';
         'acqsys'
         };
   case 'RHS'
      %% Enumerated list for Intan RHS system/headstage
      fieldNames = {
         'data_present';
         'DC_amp_data_saved';
         'sample_rate';
         'frequency_parameters';
         'stim_parameters'
         'raw_channels';
         'analogIO_channels';
         'digIO_channels';
         'spike_triggers';
         'stim_step_size';
         'num_raw_channels';
         'num_DC_channels';
         'num_stim_channels';
         'num_digIO_channels';
         'num_analogIO_channels';
         'num_raw_channels';
         'num_aux_channels';
         'num_supply_channels';
         'num_sensor_channels';
         'num_adc_channels';
         'num_dac_channels';
         'num_dig_in_channels';
         'num_dig_out_channels';
         'probes';
         'num_probes';
         'num_data_blocks';
         'num_samples_per_data_block';
         'num_raw_samples';
         'num_DC_samples';
         'num_stim_samples';
         'num_aux_samples';
         'num_supply_samples';
         'num_sensor_samples';
         'num_adc_samples';
         'num_dac_samples';
         'num_dig_in_samples';
         'num_dig_out_samples';
         'header_size';
         'filesize';
         'bytes_per_block';
         'acqsys';
         };
   case 'TDT'
      %% Enumerated list for Tucker-Davis Technologies (TDT) system
      fieldNames = {
         'data_present';
         %    'DC_amp_data_saved';
         'sample_rate';
         %    'frequency_parameters';
         %    'stim_parameters'
         'raw_channels';
         %    'board_adc_channels';
         %    'board_dig_in_channels';
         %    'board_dig_out_channels';
         'num_raw_channels';
         'num_analogIO_channels';
         'num_digIO_channels';
         %    'num_board_dig_out_channels';
         'num_probes';
         %    'num_data_blocks';
         %    'bytes_per_block';
         %    'num_samples_per_data_block';
         'num_raw_samples';
         %    'num_board_adc_samples';
         %    'num_board_dig_in_samples';
         %    'num_board_dig_out_samples';
         'filesize';
         'info';
         'dataType';
         'fn';
         'acqsys';
         };
   case 'RC' % MM experiment
      %% Enumerated list for ad hoc experiment (MM)
      fieldNames = {
         'data_present';
         'sample_rate';
         'frequency_parameters';
         'raw_channels';
         'analogIO_channels';
         'digIO_channels';
         'num_raw_channels';
         'num_digIO_channels';
         'num_analogIO_channels';
         'probes';
         'num_probes';
         'num_raw_samples';
         'num_analogIO_samples';
         'num_digIO_samples';
         'duration';
         'blocktime';
         'acqsys';
         };
   otherwise
      error('Unrecognized RecType: %s',RecType);
end

end