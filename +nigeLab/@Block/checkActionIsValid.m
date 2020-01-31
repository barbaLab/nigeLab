function flag = checkActionIsValid(blockObj,nDBstackSkip)
%CHECKACTIONISVALID  Return true if correct 'Status' evaluates true.
%
%  blockObj.checkActionIsValid(); 
%  --> Throws an error if the ".required" doActions field is not present
%
%  blockObj.checkActionIsValid(nDBstackSkip);   
%
%  nDBstackSkip  --  Optional input: number of db stack lines to skip. This
%                       is really only there to differentiate between
%                       recursion calls and original call; this should
%                       never have to be given as an argument really.
%
%  Throws an error if the corresponding fields for a particular 'doAction'
%  have not been configured correctly in nigeLab.defaults.doActions.m OR if
%  they are configured but the corresponding fields have not been
%  successfully updated in the Status of the block object.
%
%  flag = checkActionIsValid(blockObj,__);
%  --> If .batch field of blockObj.Pars.doActions parameters struct is
%      non-empty, then if the field is missing returns false. Otherwise,
%      default behavior is to return true (if no .batch is specified for
%      example, then it will return true).
%  --> If blockObj is an array, returns a logical array the same size as
%        blockObj.

if nargin < 2
   nDBstackSkip = 1;
end

if numel(blockObj) > 1
   flag = true(size(blockObj));
   for i = 1:numel(blockObj)
      flag(i) = checkActionIsValid(blockObj(i),2);
   end
   return;
else
   flag = true;
end

if isempty(blockObj.HasParsInit)
   blockObj.updateParams('doActions');
elseif ~blockObj.HasParsInit.doActions
   blockObj.updateParams('doActions');
end
nigeLab.utils.checkForWorker(blockObj,'config');

% Get dbstack, ignoring first N "cards"
% Skips: (1) this function and possibly (2) recursive call
ST = dbstack(nDBstackSkip); 
doName = ST(1).name;

if ~isfield(blockObj.Pars.doActions,doName)
   error(['nigeLab:' mfilename ':doActionNotReady'],...
      '%s is not configured in %s',doName,...
      nigeLab.utils.getNigeLink('nigeLab.defaults.doActions'));
end

Fields = blockObj.Pars.doActions.(doName).required;
if isempty(Fields)
   BatchFields = blockObj.Pars.doActions.(doName).batch;
   if ~isempty(BatchFields)
      for i = 1:numel(BatchFields)
         isIncomplete = checkSpecificField(blockObj,BatchFields{i});
         flag = flag && ~isIncomplete;
      end
   end
   return; % No requirements; proceed
end

% Check any included fields. If they don't have all necessary parts, throw
% an error.
for i = 1:numel(Fields)
   isIncomplete = checkSpecificField(blockObj,Fields{i});
   if isIncomplete
      error(['nigeLab:' mfilename ':doActionNotReady'],...
         ['%s (a necessary pre-processing step) is not yet completed.\n' ...
         'Cannot run %s until this is complete, or requirement is changed in %s'],...
         Fields{i}, doName, nigeLab.utils.getNigeLink('nigeLab.defaults.doActions'));
   end
end

% Helper functions
   function isIncomplete = checkSpecificField(blockObj,f)
      %CHECKSPECIFICFIELD  Checks specified field for completion status
      %
      %  isIncomplete = checkSpecificField(blockObj,f);
      %  --> blockObj: Block (scalar)
      %  --> f : Fieldname (char array; single field of block)
      %
      %  --> isIncomplete = true if there is an incomplete (unmasked)
      %                    element from field f for blockObj
      
      completionFlag = blockObj.getStatus(f);
      switch blockObj.getFieldType(f)
         case 'Channels'
            % Only consider the channels for which Mask == true
            isIncomplete = ~all(completionFlag(blockObj.Mask));
         otherwise
            % Otherwise, everything must be completed
            isIncomplete = ~all(completionFlag);
      end
   end

end