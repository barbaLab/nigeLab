function flag = tdt2Block(blockObj)
PATH = blockObj
header = ReadTDTHeader();
fprintf(1, 'Allocating memory for data...\n');
   RW_info = amplifier_channels;
   paths.RW=strrep(paths.RW,'\','/');
   infoname = fullfile(paths.RW,[blockObj.Name '_RawWave_Info.mat']);
   save(fullfile(infoname),'RW_info','-v7.3');
   
   if exist('myJob','var')~=0
      set(myJob,'Tag',sprintf('%s: Initializing DiskData arrays...',blockObj.Name));
   end
   
   % One file per probe and channel
   amplifier_dataFile = cell(num_amplifier_channels,1);
   stim_dataFile = cell(num_amplifier_channels,1);
   if (dc_amp_data_saved ~= 0)
      dc_amplifier_dataFile = cell(num_amplifier_channels,1);
   end
   for iCh = 1:num_amplifier_channels
      pnum  = num2str(amplifier_channels(iCh).port_number);
      chnum = amplifier_channels(iCh).custom_channel_name(regexp(amplifier_channels(iCh).custom_channel_name, '\d'));
      fname = sprintf(strrep(paths.RW_N,'\','/'), pnum, chnum);
      amplifier_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),single(0),...
         'class','single','size',[1 num_amplifier_samples],'access','w');
      
      stim_data_fname = strrep(fullfile(paths.DW,'STIM_DATA',[blockObj.Name '_STIM_P%s_Ch_%s.mat']),'\','/');
      fname = sprintf(strrep(stim_data_fname,'\','/'), pnum, chnum);
      stim_dataFile{iCh} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),single(0),...
         'class','single','size',[1 num_amplifier_samples],'access','w');
      
      if (dc_amp_data_saved ~= 0)
         dc_amp_fname = strrep(fullfile(paths.DW,'DC_AMP',[blockObj.Name '_DCAMP_P%s_Ch_%s.mat']),'\','/');
         fname = sprintf(strrep(dc_amp_fname,'\','/'), pnum, chnum);
         dc_amplifier_dataFile{iCh} =  orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),single(0),...
            'class','single','size',[1 num_amplifier_samples],'access','w');
      end
   end
   
   % Save single-channel adc data
   if (num_board_adc_channels > 0)
      ADC_info = board_adc_channels;
      paths.DW = strrep(paths.DW, '\', '/');
      infoname = fullfile(paths.DW,[blockObj.Name '_ADC_Info.mat']);
      save(fullfile(infoname),'ADC_info','-v7.3');
      if (data_present)
         board_adc_dataFile = cell(num_board_adc_channels,1);
         for i = 1:num_board_adc_channels
            paths.DW_N = strrep(paths.DW_N, '\', '/');
            fname = sprintf(strrep(paths.DW_N,'\','/'), board_adc_channels(i).custom_channel_name);
            board_adc_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),single(0),...
               'class','single','size',[1 num_board_adc_samples],'access','w');
         end
      end
   end
   
   % Save single-channel dac data
   if (num_board_dac_channels > 0)
      DAC_info = board_dac_channels;
      paths.DW = strrep(paths.DW, '\', '/');
      infoname = fullfile(paths.DW,[blockObj.Name '_DAC_Info.mat']);
      save(fullfile(infoname),'DAC_info','-v7.3');
      if (data_present)
         board_dac_dataFile = cell(num_aux_input_channels,1);
         for i = 1:num_board_dac_channels
            paths.DW_N = strrep(paths.DW_N, '\', '/');
            fname = sprintf(strrep(paths.DW_N,'\','/'), board_dac_channels(i).custom_channel_name);
            board_dac_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),single(0),...
               'class','single','size',[1 num_board_dac_samples],'access','w');
         end
      end
   end
   
   % Save single-channel digital input data
   if (num_board_dig_in_channels > 0)
      DigI_info = board_dig_in_channels;
      paths.DW = strrep(paths.DW, '\', '/');
      infoname = fullfile(paths.DW,[blockObj.Name '_Digital_Input_Info.mat']);
      save(fullfile(infoname),'DigI_info','-v7.3');
      if (data_present)
         board_dig_in_dataFile = cell(num_board_dig_in_channels,1);
         for i = 1:num_board_dig_in_channels
            fname = sprintf(strrep(paths.DW_N,'\','/'), board_dig_in_channels(i).custom_channel_name);
            board_dig_in_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),uint8(0),...
               'class','uint8','size',[1 num_board_dig_in_samples],'access','w');
         end
      end
   end
   
   
   % Save single-channel digital output data
   if (num_board_dig_out_channels > 0)
      DigO_info = board_dig_out_channels;
      paths.DW = strrep(paths.DW, '\', '/');
      infoname = fullfile(paths.DW,[blockObj.Name '_Digital_Output_Info.mat']);
      save(fullfile(infoname),'DigO_info','-v7.3');
      if (data_present)
         board_dig_out_dataFile = cell(num_board_dig_out_channels,1);
         for i = 1:num_board_dig_out_channels
            fname = sprintf(strrep(paths.DW_N,'\','/'), board_dig_out_channels(i).custom_channel_name);
            board_dig_out_dataFile{i} = orgExp.libs.DiskData(blockObj.SaveFormat,fullfile(fname),uint8(0),...
               'class','uint8','size',[1 num_board_dig_out_samples],'access','w');
         end
      end
   end
   fprintf(1,'Matfiles created succesfully\n');
   fprintf(1,'Exporting files...\n');
   fprintf(1,'%.3d%%',0)
   
    block = TDTbin2mat(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data',files_in{1,1},files_in{1,2},files_in{1,3}),'TYPE',{'EPOCS','SNIPS','STREAMS','SCALARS'});


end