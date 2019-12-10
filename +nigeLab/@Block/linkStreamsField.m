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
str = nigeLab.utils.printLinkFieldString(blockObj.getFieldType(field),field);
blockObj.reportProgress(str,0);

% updateFlag corresponds to blockObj.Streams.(field)
updateFlag = false(1,numel(blockObj.Streams.(field)));

[pname,f_str,ext] = fileparts(nigeLab.utils.getUNCPath(blockObj.Paths.(field).file));
counter = 0;
for iStream = 1:numel(blockObj.Streams.(field))
   
   % Parse info from channel struct. Because INIT comes first, we want to
   % use the file name conventions already established, so we don't use
   % dir() or something like that here. If the file is missing, then this
   % step will be flagged and the updateStatus will reflect that part.
   dataFileName = nigeLab.utils.getUNCPath(fullfile(...
      pname,...
      [sprintf(f_str,blockObj.Streams.(field)(iStream).signal.Group,...
      blockObj.Streams.(field)(iStream).name),ext]));

   % If file is not detected
   if ~exist(fullfile(dataFileName),'file')
      flag = true;
   else
      counter = counter + 1;
      updateFlag(iStream) = true;
      blockObj.Streams.(field)(iStream).data = ...
         nigeLab.libs.DiskData('Hybrid',dataFileName);
   end
   pct = 100 * (counter / numel(blockObj.Streams.(field))); 
   blockObj.reportProgress(str,pct);
end

blockObj.updateStatus(field,updateFlag);


end