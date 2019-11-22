function flag = linkStreamsField(blockObj,field)
%% LINKSTREAMSFIELD  Connect the data saved on the disk to Streams
%
%  b = nigeLab.Block;
%  flag = LINKSTREAMSFIELD(b,field);
%
%  Returns flag as true when a file is missing.
%  Updates blockObj.Status 
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%% Parse input
if nargin < 2
   field = blockObj.Fields(blockObj.getFieldTypeIndex('Streams'));
   flag = linkStreamsField(blockObj,field);
   return;
end

if iscell(field)
   flag = false;
   for i = 1:numel(field)
      flag = flag || linkStreamsField(blockObj,field{i});
   end
   return;
end

%%
flag = false;
nigeLab.utils.printLinkFieldString(blockObj.getFieldType(field),field);

updateFlag = false(1,numel(blockObj.Streams));

[pname,fname,~] = fileparts(blockObj.Paths.(field).file);
id = strsplit(fname,'%');
F = dir(fullfile(pname,[id{1} '*'])); % by convention I try to use F for this 'dir' struct
counter = 0;
for iCh = 1:numel(F)
    updateFlag = false(1,numel(info));
   % Parse info from channel struct
   fName = fullfile(F.folder,F.name);

   % If file is not detected
   if ~exist(fullfile(fName),'file')
      flag = true;
   else
      counter = counter + 1;
      updateFlag(iCh) = true;
      blockObj.Streams.(field)(iCh).data = nigeLab.libs.DiskData('Hybrid',fName);
   end
   pct = 100 * (counter / numel(F)); 
   fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
end
    blockObj.updateStatus(field,updateFlag);
% end




end