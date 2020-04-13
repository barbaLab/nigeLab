function flag = linkEventsField(blockObj,field)
%LINKEVENTSFIELD  Connect data to Events, return true if missing a file
%
%  blockObj = nigeLab.Block;
%  flag = LINKEVENTSFIELD(blockObj,field);
%
%  Input:
%  blockObj  --  nigeLab.Block object or array
%  field  --  Char array of cell array of char arrays, which are the Events
%              fields to link. For example, 'ScoredEvents' or 'DigEvents'.
%              --> These should correspond to `Fields` elements of
%                  nigeLab.Block
%              --> See `~/+nigeLab/+defaults/Block.m` and 
%                      `~/+nigeLab/+defaults/Event.m` for configuration
%
%  * Initializes 'Events' struct array field of nigeLab.Block
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
      ['\t\t->\t<strong>[LINKEVENTSFIELD]::</strong>%s: ' ...
      '`blockObj` and `field` arguments are both required.\n'],...
      blockObj.Name);
end

% Iterate on multiple blocks (if given)
if numel(blockObj) > 1
   flag = true;
   for i = 1:numel(blockObj)
      if isempty(blockObj(i))
         warning(['nigeLab:' mfilename ':EmptyBlock'],...
            ['\t\t->\t<strong>[LINKEVENTSFIELD]::</strong>%s: ' ...
            'Empty Block LinkEvents skipped\n'],blockObj(i).Name);
         continue;
      end
      flag = flag && linkEventsField(blockObj(i),field);
   end
   return; 
end

% If `field` is cell array, iterate on fields
if iscell(field)
   flag = true;
   for i = 1:numel(field)
      flag = flag && linkEventsField(blockObj,field{i});
   end
   return;
else
   flag = false;
end

evtIdx = ismember(blockObj.Pars.Event.Fields,field);
N = sum(evtIdx);
if N == 0
   flag = true;
   warning(['nigeLab:' mfilename ':BadEvent'],...
      ['\t\t->\t<strong>[LINKEVENTSFIELD]::</strong>%s: ' ...
      'Bad Event Name: ''%s'' (skipped)\n'],blockObj.Name,field);
   return;
end

updateFlag = false(1,numel(blockObj.Events.(field)));
if ~isfield(blockObj.Status,field)
   blockObj.Status.(field) = updateFlag;
end

str = nigeLab.utils.printLinkFieldString(blockObj.getFieldType(field),field);
reportProgress(blockObj,str,0);
curEvent = 0;
for i = 1:numel(blockObj.Events.(field))  
   % Get file name
   fName = sprintf(blockObj.Paths.(field).file,blockObj.Events.(field)(i).name);
   % Increment counter and update progress
   curEvent = curEvent + 1;
   pct = 100 * (curEvent / numel(blockObj.Mask));
   
   % If file is not detected
   if ~exist(fName,'file')
      flag = true;
   else
      % If file is detected, link it
      updateFlag(i) = true;
      blockObj.Events.(field)(i).data=nigeLab.libs.DiskData('Event',fName);
      status = blockObj.Events.(field)(i).data.Complete;
      if isempty(status)
         setAttr(blockObj.Events.(field)(i).data,'Complete',...
            int8(blockObj.Status.(field)(i)));
      else
         updateFlag(curEvent) = logical(status);
      end
   end
   
   % Print updated completion percent to command window
   reportProgress(blockObj,str,pct);
end
% Update the status for each linked file (number depends on the Field)
updateStatus(blockObj,field,updateFlag);

end
