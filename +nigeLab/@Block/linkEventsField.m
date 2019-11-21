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

updateFlag = false;

fprintf(1,'\nLinking Events field: %s ...000%%\n',field);
counter = 0;
   
   % Get file name

   fName = sprintf(strrep(blockObj.Paths.(field).file,'\','/'), ...
      field);
   fName = fullfile(fName);
   
   % If file is not detected
   if ~exist(fullfile(fName),'file')
      flag = true;
   else
      updateFlag = true;
      indx = strcmp({blockObj.Events.name},field);
      blockObj.Events(indx).data=nigeLab.libs.DiskData('MatFile',fName);
   end
   
%    counter = counter + 1;
%    pct = 100 * (counter / numel(blockObj.Mask));
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(100))

blockObj.updateStatus(field,updateFlag);

end
