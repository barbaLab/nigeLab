function flag = linkChannelsField(blockObj,field,fType)
%% LINKCHANNELSFIELD  Connect the data saved on the disk to Channels
%
%  b = nigeLab.Block;
%  field = 'Spikes';    % field = 'Raw'
%  fType = 'MatFile';   % field = 'Hybrid'
%  flag = LINKCHANNELSFIELD(b,field,fType);
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
   pNum  = num2str(blockObj.ChannelID(iCh,1));
   chNum = num2str(blockObj.ChannelID(iCh,2),'%03g');
   fName = sprintf(strrep(blockObj.Paths.(field).file,'\','/'), ...
      pNum,chNum);
   fName = fullfile(fName);
   
   % If file is not detected
   if ~exist(fullfile(fName),'file')
      flag = true;
   else
      updateFlag(iCh) = true;
      blockObj.Channels(iCh).(field) = ...
         nigeLab.libs.DiskData(fType,fName);
   end
   
   counter = counter + 1;
   pct = 100 * (counter / numel(blockObj.Mask));
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
end
blockObj.updateStatus(field,updateFlag);

end