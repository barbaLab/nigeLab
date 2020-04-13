function flag = linkTime(blockObj)
%LINKTIME  Connect the data saved on the disk to Time property
%
%  b = nigeLab.Block;
%  flag = LINKTIME(b,field);
%  --> flag is returned as true if there is no 'Time' file found.
%  This method automatically updates the 'Time' Status, and requires 'Time'
%  as an element of nigeLab.defaults.Block('Fields')

blockObj.checkCompatibility('Time'); % Checks that 'Time' is in .Fields
nigeLab.utils.printLinkFieldString(blockObj.getFieldType('Time'),'Time');
counter = 0;
fName=sprintf(strrep(blockObj.Paths.Time.file,'\','/'),'Time.mat');
% If file is not detected
if ~exist(fName,'file')
   flag = true;  % Somtehing went wrong
else
   flag = false; % Nothing went wrong (update .Time status as true)
   blockObj.Time = nigeLab.libs.DiskData('Hybrid',fName);
end
blockObj.updateStatus('Time',~flag);

end