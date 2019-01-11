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

fprintf(1,'\nLinking Channels field: %s ...000%%\n',field);
counter = 0;
for iCh = blockObj.Mask
   
   % Get file name
   pnum  = num2str(blockObj.ChannelID(iCh,1));
   chnum = num2str(blockObj.ChannelID(iCh,2),'%03g');
   fname = sprintf(strrep(blockObj.Paths.(field).file,'\','/'), ...
      pnum,chnum);
   fname = fullfile(fname);
   
   % If file is not detected
   if ~exist(fullfile(fname),'file')
      flag = true;
   else
      updateFlag(iCh) = true;
      blockObj.Channels(iCh).(field) = ...
         nigeLab.libs.DiskData(blockObj.SaveFormat,fname);
   end
   
   counter = counter + 1;
   fraction_done = 100 * (counter / numel(blockObj.Mask));
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(fraction_done))
end
blockObj.updateStatus(field,updateFlag);

end