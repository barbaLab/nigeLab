function flag = linkTime(blockObj)
%% LINKTIME  Connect the data saved on the disk to Time property
%
%  b = nigeLab.Block;
%  flag = LINKTIME(b,field);
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
flag = false;

fprintf(1,'\nLinking Time field...000%%\n');
counter = 0;
fName = fullfile(blockObj.Paths.Time.info);
   
% If file is not detected
if ~exist(fullfile(fName),'file')
   flag = true;
else
   blockObj.Time = nigeLab.libs.DiskData('Hybrid',fName);
end
fprintf(1,'\b\b\b\b\b%.3d%%\n',100)

blockObj.updateStatus('Time',true);

end