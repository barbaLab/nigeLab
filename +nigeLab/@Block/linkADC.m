function flag = linkADC(blockObj)
%% LINKADC   Connect the ADC data saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = LINKADC(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% CHECK SINGLE_CHANNEL ADC DATA
flag = false;
if blockObj.NumADCchannels > 0
   fprintf(1,'\nLinking ADC channels...000%%\n');

   for i = 1:blockObj.NumADCchannels
      blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
      fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'),...
         blockObj.ADCChannels(i).custom_channel_name);
      fname = fullfile(fname);
      
      if ~exist(fullfile(fname),'file')
         flag = true;
      else
         blockObj.ADCChannels(i).data = ...
            nigeLab.libs.DiskData(blockObj.SaveFormat,fname);
      end
      fraction_done = 100 * (i / blockObj.NumADCchannels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
   end
end

end