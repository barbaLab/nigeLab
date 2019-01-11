function flag = linkDAC(blockObj)
%% LINKDAC   Connect the DAC data saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = LINKDAC(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% CHECK SINGLE-CHANNEL DAC DATA
flag = false;
if blockObj.NumDACChannels > 0
   fprintf(1,'\nLinking DAC channels...000%%\n');

   for i = 1:blockObj.NumDACChannels
      blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
      fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), ...
         blockObj.DACChannels(i).custom_channel_name);
      fname = fullfile(fname);
      
      if ~exist(fullfile(fname),'file')
         flag = true;
      else
         blockObj.DACChannels(i).data = ...
            nigeLab.libs.DiskData(blockObj.SaveFormat,fname);
      end
      fraction_done = 100 * (i / blockObj.NumDACChannels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
   end
end

end