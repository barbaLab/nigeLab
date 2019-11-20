function fieldNames = desiredHeaderFields(RecType)
%% DESIREDHEADERFIELDS  Returns array of desired header fields (previously Desired_Outputs)
%
%  fieldNames = nigeLab.utils.DESIREDHEADERFIELDS;
%  --> Returns ALL fields
%  fieldNames = nigeLab.utils.DESIREDHEADERFIELDS(RecType);
%  --> Returns fields relevant to RecType

%%
if nargin < 1
   RecType = 'All';
end

switch RecType
   case 'All'
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
         'stim_parameters';
         'stim_step_size';
         'info';
         'dataType';
         'fn';
      };
   case 'RHD'
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
      };
   case 'RHS'
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
      };
   case 'TDT'
      DesiredOutputs = {
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
      };
   otherwise
      error('Unrecognized RecType: %s',RecType);
end


end