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

updateFlag = false(1,numel(blockObj.Events.(field)));

nigeLab.utils.printLinkFieldString(blockObj.getFieldType(field),field);
counter = 0;
for i = 1:numel(blockObj.Events.(field))  
   % Get file name


   fName = nigeLab.utils.getUNCPath(fullfile(blockObj.Paths.(field).dir,sprintf(...
      blockObj.BlockPars.(field).File,blockObj.Events.(field)(i).name)));
   
   % If file is not detected
   if ~exist(fName,'file')
      flag = true;
   else
      updateFlag(i) = true;
      blockObj.Events.(field)(i).data=nigeLab.libs.DiskData('MatFile',fName);
   end
   
   counter = counter + 1;
   pct = 100 * (counter / numel(blockObj.Mask));
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(100))
end
blockObj.updateStatus(field,updateFlag);

end
