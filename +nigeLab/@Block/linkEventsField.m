function flag = linkEventsField(blockObj,field)
%LINKEVENTSFIELD  Connect data to Events, return true if missing a file
%
%  blockObj = nigeLab.Block;
%  flag = LINKEVENTSFIELD(blockObj,field);
%
%  Creates nigeLab.libs.DiskData "pointers" to the "Events" FieldType data
%  files associated with the nigeLab.Block object.
%
%  Returns true if any file was not detected during linking.

flag = false;
evtIdx = ismember(blockObj.Pars.Event.Fields,field);
N = sum(evtIdx);
if N == 0
   flag = true;
   return;
end
updateFlag = false(1,numel(blockObj.Events.(field)));

str = nigeLab.utils.printLinkFieldString(blockObj.getFieldType(field),field);
reportProgress(blockObj,str,0);
counter = 0;
for i = 1:numel(blockObj.Events.(field))  
   % Get file name
   fName = sprintf(blockObj.Paths.(field).file,blockObj.Events.(field)(i).name);
   % Increment counter and update progress
   counter = counter + 1;
   pct = 100 * (counter / numel(blockObj.Mask));
   
   % If file is not detected
   if ~exist(fName,'file')
      flag = true;
   else
      % If file is detected, link it
      updateFlag(i) = true;
      blockObj.Events.(field)(i).data=nigeLab.libs.DiskData('Event',fName);
   end
   
   % Print updated completion percent to command window
   reportProgress(blockObj,str,pct);
end
% Update the status for each linked file (number depends on the Field)
updateStatus(blockObj,field,updateFlag);

end
