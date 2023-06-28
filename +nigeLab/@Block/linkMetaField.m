function flag = linkMetaField(blockObj,field)
%LINKMETAFIELD  Connect data to Meta, return true if missing a file
%
%  blockObj = nigeLab.Block;
%  flag = LINKMETAFIELD(blockObj,field);
%
%  Input:
%  blockObj  --  nigeLab.Block object or array
%  field  --  Char array of cell array of char arrays, which are the Meta
%              fields to link. For example, 'Time' or 'Stim'.
%              --> These should correspond to `Fields` elements of
%                  nigeLab.Block
%              --> See `~/+nigeLab/+defaults/Block.m` and 
%                      `~/+nigeLab/+defaults/Event.m` for configuration
%
%  * Initializes 'Meta' struct array field of nigeLab.Block
%
%  * Does not create the DiskData file if it does not already exist. If the
%    file exists, it parses completion status from the DiskData.Complete
%    file attribute (dependent) property. 
%
%  Output:
%  flag  --  Returns TRUE if any file was not detected during linking.


% Check number of inputs
if nargin < 2
   error(['nigeLab:' mfilename ':TooFewInputs'],...
      ['\t\t->\t<strong>[LINKMETAFIELD]::</strong>%s: ' ...
      '`blockObj` and `field` arguments are both required.\n'],...
      blockObj.Name);
end

% Iterate on multiple blocks (if given)
if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      if isempty(blockObj(i))
         warning(['nigeLab:' mfilename ':EmptyBlock'],...
            ['\t\t->\t<strong>[LINKMETAFIELD]::</strong>%s: ' ...
            'Empty Block LinkMeta skipped\n'],blockObj(i).Name);
         continue;
      end
      flag = linkMetaField(blockObj(i),field) || flag;
   end
   return; 
end

% If `field` is cell array, iterate on fields
if iscell(field)
   flag = true;
   for i = 1:numel(field)
      flag = flag && linkMetaField(blockObj,field{i});
   end
   return;
else
   flag = false;
end

fileType = blockObj.FileType{strcmp(field,blockObj.Fields)};
updateFlag = false(1,1);
if ~isfield(blockObj.Status,field)
   blockObj.Status.(field) = updateFlag;
end

str = nigeLab.utils.printLinkFieldString(blockObj.getFieldType(field),field);
reportProgress(blockObj,str,0);

% Get file name
fName = sprintf(blockObj.Paths.(field).file,[blockObj.Meta.BlockID]);
% Increment counter and update progress


% If file is not detected
if ~exist(fName,'file')
    flag = true;
    updateFlag = false;
else
    % If file is detected, link it
    updateFlag = true;
    blockObj.Meta.(field)=nigeLab.libs.DiskData(fileType,fName);
    status = blockObj.Meta.(field).Complete;
    if isempty(status)
        setAttr(blockObj.Meta.(field),'Complete',...
            int8(blockObj.Status.(field)));
    else
        updateFlag = logical(status);
    end
end
   
% Print updated completion percent to command window
reportProgress(blockObj,str,100);
% Update the status for each linked file (number depends on the Field)
updateStatus(blockObj,field,updateFlag);

end
