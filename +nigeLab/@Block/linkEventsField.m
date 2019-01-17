function flag = linkEventsField(blockObj,field)
%% LINKEVENTSFIELD  Connect the data saved on the disk to Events
%
%  b = nigeLab.Block;
%  flag = LINKEVENTSFIELD(b,field);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
flag = false;
evtIdx = ismember(blockObj.EventPars.Fields,field);
N = sum(evtIdx);
if N == 0
   flag = true;
   return;
end

updateFlag = false(1,blockObj.NumChannels);

fprintf(1,'\nLinking Events field: %s ...000%%\n',field);
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
      blockObj.Events(iCh).(field)=nigeLab.libs.DiskData('MatFile',fName);
   end
   
   counter = counter + 1;
   pct = 100 * (counter / numel(blockObj.Mask));
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
end
blockObj.updateStatus(field,updateFlag);

end
