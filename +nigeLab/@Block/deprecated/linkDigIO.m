function flag = linkDigIO(blockObj)
%% LINKDIGIO   Connect Digital I/O saved on the disk to the structure
%
%  b = nigeLab.Block;
%  flag = LINKDIGIO(b);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% CHECK SINGLE-CHANNEL DIGITAL INPUT DATA
flag = false(1,2);
if blockObj.NumDigInChannels > 0
   fprintf(1,'\nLinking DIG-IN channels...000%%\n');
   
   for i = 1:blockObj.NumDigInChannels
      blockObj.paths.DW_N = strrep(blockObj.paths.DW_N, '\', '/');
      fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), ...
         blockObj.DigInChannels(i).custom_channel_name);
      fname = fullfile(fname);
      
      if ~exist(fullfile(fname),'file')
         flag(1) = true;
      else
         blockObj.DigInChannels(i).data = ...
            nigeLab.libs.DiskData(blockObj.SaveFormat,fname);
      end
      fraction_done = 100 * (i / blockObj.NumDigInChannels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
   end
   
end

% Note: no parsing of DIGITAL status here yet, since uncertain how the
%       format will end up looking in the end.

%% CHECK SINGLE-CHANNEL DIGITAL OUTPUT DATA
if blockObj.NumDigOutChannels > 0
   fprintf(1,'\nLinking DIG-OUT channels...000%%\n');
   
   for i = 1:blockObj.NumDigOutChannels
      fname = sprintf(strrep(blockObj.paths.DW_N,'\','/'), ...
         blockObj.DigOutChannels(i).custom_channel_name);
      fname = fullfile(fname);
      if ~exist(fullfile(fname),'file')
         flag(2) = true;
      else
         blockObj.DigOutChannels(i).data = ...
            nigeLab.libs.DiskData(blockObj.SaveFormat,fname);
      end
      fraction_done = 100 * (i / blockObj.NumDigOutChannels);
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
   end
end

% Note: no parsing of DIGITAL status here yet, since uncertain how the
%       format will end up looking in the end.

end