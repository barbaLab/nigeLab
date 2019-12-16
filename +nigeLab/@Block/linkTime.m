function flag = linkTime(blockObj)
%% LINKTIME  Connect the data saved on the disk to Time property
%
%  b = nigeLab.Block;
%  flag = LINKTIME(b,field);
%
% flag is returned as true if there is no 'Time' file found.
%  This method automatically updates the 'Time' Status, and requires 'Time'
%  as an element of nigeLab.defaults.Block('Fields').

%%
flag = false;
updateflag = false;
blockObj.checkCompatibility('Time');

nigeLab.utils.printLinkFieldString(blockObj.getFieldType('Time'),'Time');
counter = 0;
fName = fullfile(blockObj.Paths.Time.file);
   
% If file is not detected
if ~exist(fullfile(fName),'file')
   flag = true;
else
   updateflag = true;
   blockObj.Time = nigeLab.libs.DiskData('Hybrid',fName);
end
fprintf(1,'\b\b\b\b\b%.3d%%\n',100)

blockObj.updateStatus('Time',updateflag);

end