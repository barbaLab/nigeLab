function checkActionIsValid(blockObj,nDBstackSkip)
% CHECKACTIONISVALID  Return true if correct 'Status' evaluates true.
%
%  blockObj.checkActionIsValid(); --> should always work
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

%%
if nargin < 2
   nDBstackSkip = 1;
end

if numel(blockObj) > 1
   for i = 1:numel(blockObj)
      checkActionIsValid(blockObj(i),2);
   end
   return;
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
   return; % No requirements; proceed
end

% Check any included fields. If they don't have all necessary parts, throw
% an error.
for i = 1:numel(Fields)
   f = Fields{i};  % Status from each must be met
   completionFlag = blockObj.getStatus(f);
   switch blockObj.getFieldType(f)
      case 'Channels'
         % Only consider the channels for which Mask == true
         isIncomplete = ~all(completionFlag(blockObj.Mask));
      otherwise
         % Otherwise, everything must be completed
         isIncomplete = ~all(completionFlag);
   end
   
   if isIncomplete
      error(['nigeLab:' mfilename ':doActionNotReady'],...
         ['%s (a necessary pre-processing step) is not yet completed.\n' ...
         'Cannot run %s until this is complete, or requirement is changed in %s'],...
         f, doName, nigeLab.utils.getNigeLink('nigeLab.defaults.doActions'));
   end
end

end