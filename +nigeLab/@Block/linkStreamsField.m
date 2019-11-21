function flag = linkStreamsField(blockObj,field)
%% LINKSTREAMSFIELD  Connect the data saved on the disk to Streams
%
%  b = nigeLab.Block;
%  flag = LINKSTREAMSFIELD(b,field);
%
%  Returns flag as true when a file is missing.
%
% Note: This is useful when you already have formatted data,
%       or when the processing stops for some reason while in progress.
%
% By: MAECI 2018 collaboration (Federico Barban & Max Murphy)

%%
flag = false;
updateFlag = false(1,blockObj.NumChannels);
Fields = blockObj.Fields(strcmpi(blockObj.FieldType,'Streams'));

fprintf(1,'\nLinking Streams field: %s ...000%%\n',field);

for jj=1:numel(Fields)
   counter = 0;
   [pname,fname,~] = fileparts(blockObj.Paths.(Fields{jj}).file);
   id = strsplit(fname,'%');
   info = dir(fullfile(pname,[id{1} '*']));
   for iCh = 1:numel(info)
      % Parse info from channel struct
      fName = fullfile(info.folder,info.name);
      
      % If file is not detected
      if ~exist(fullfile(fName),'file')
         flag = true;
      else
         counter = counter + 1;
         updateFlag(iCh) = true;
         blockObj.Streams.(field)(iCh)=nigeLab.libs.DiskData('Hybrid',fName);
      end
      
      
      pct = 100 * (counter / numel(info)); % Bug in STREAMS "% update" WAS HERE (MM 2019-11-20)
      fprintf(1,'\b\b\b\b\b%.3d%%\n',floor(pct))
   end
end
blockObj.updateStatus(field,updateFlag);

end