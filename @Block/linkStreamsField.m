function flag = linkStreamsField(blockObj,field)
%% LINKSTREAMSFIELD  Connect the data saved on the disk to Streams
%
%  b = nigeLab.Block;
%  flag = LINKSTREAMSFIELD(b,field);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
flag = false;
updateFlag = false(1,blockObj.NumChannels);
info = blockObj.Streams.(field);

fprintf(1,'\nLinking Streams field: %s ...000%%\n',field);
counter = 0;
for iCh = 1:numel(info)
   % Parse info from channel struct
   fName = parseNameFromChannelStruct(blockObj.Paths,field,info,iCh);
   
   % If file is not detected
   if ~exist(fullfile(fName),'file')
      flag = true;
   else
      updateFlag(iCh) = true;
      blockObj.Streams(iCh).(field)=nigeLab.libs.DiskData('Hybrid',fName);
   end
   
   counter = counter + 1;
   pct = 100 * (counter / numel(blockObj.Mask));
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
end
blockObj.updateStatus(field,updateFlag);

   function fName = parseNameFromChannelStruct(paths,field,info,ch)
      %% PARSENAMEFROMCHANNELSTRUCT    Get file name based on channel info
      sigType = info(ch).signal_type;
      
      if isempty(sigType)
         sigType = field;
         name = num2str(ch,'%03g');
      else
         name = info(ch).custom_channel_name;
      end
      
      fName = sprintf(strrep(paths.(field).file,'\','/'), sigType, name);
      fName = fullfile(fName);
   end

end