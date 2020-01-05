function [flag,p] = updateParams(blockObj,paramType)
% UPDATEPARAMS   Update the parameters struct property for paramType
%
%  flag = updateParams(blockObj);
%  flag = updateParams(blockObj,paramType);
%  [flag,p] = udpdateParams(__); Returns updated parameters as well
%
%  --------
%   INPUTS
%  --------
%  blockObj    :     nigeLab.Block class object.
%
%  paramType   :     (optional; char array) Name of parameter type to
%                       update
%                    -> Can be passed as cell array to update multiple
%                       parameters.
%                    -> If specified as 'all', then initializes all
%                       parameters fields except for Block and Shortcuts.
%
%  --------
%   OUTPUT
%  --------
%    flag      :     Flag indicating if setting new path was successful.

%% PARSE INPUT
flag = false;
if isempty(blockObj)
   if nargout > 1
      p = [];
   end
   return;
end
ConstructProps = {'Block','Shortcuts','Animal','Tank'};
PropsToSkip ={'nigelColors','Tempdir'};

% Make sure a valid parameter type is selected:
tmp = dir(fullfile(nigeLab.utils.getNigelPath('UNC'),'+nigeLab','+defaults','*.m'));
allProps = cellfun(@(x)x(1:(end-2)),{tmp.name},'UniformOutput',false);

% The following properties do not apply or should be set in constructor:
tmp = setdiff(allProps,[PropsToSkip,ConstructProps]);

% Make sure that blockObj.Pars is initialized as a struct
if isempty(blockObj.Pars)
   blockObj.Pars = struct;
end
if nargin < 2 % if not supplied then it is 'loadParams: all'
   if blockObj.HasParsFile
      flag = loadParams(blockObj);
      if ~flag
         flag = blockObj.updateParams('all'); % Then set from +defaults
      end
   end
   return;
end

if iscell(paramType) % Use recursion to run if cell array is given
   N = numel(paramType);
   if N==0
      flag = true;
      return;
   end % ends recursion
   paramType = paramType(:); % just in case it wasn't a vector for some reason;
   flag = blockObj.updateParams(paramType{1}) && blockObj.updateParams(paramType(2:N));
   return;
elseif strcmpi(paramType,'all') % otherwise, if 'all' option is invoked:

   paramType = [tmp,'Block'];
   flag = blockObj.updateParams(paramType);
   return;
   
elseif any(ismember(paramType,ConstructProps))
     ... Right now no action is required here
   pars = nigeLab.defaults.(paramType)();
   allNames = fieldnames(pars);
   allNames = reshape(allNames,1,numel(allNames));
   for name_ = allNames
      % Check to see if it matches any of the listed properties
      if isprop(blockObj,name_{:})
         blockObj.(name_{:}) = pars.(name_{:});
      end
   end
   blockObj.Pars.(paramType) = pars;
   flag = true;
   return;
else
   % otherwise, check if not an appropriate member
   idx = find(strncmpi(allProps,paramType,3),1,'first');
   if isempty(idx)
      error(['nigeLab:' mfilename ':BadParamsField'],...
         'Bad blockObj.Pars field name (''%s'')\n',paramType);
   else % even if it does, make sure it has correct syntax...
      paramType = allProps{idx};
   end
   
end

%% LOAD CORRECT CORRESPONDING PARAMETERS
if blockObj.HasParsFile
   flag = loadParams(blockObj,paramType);
   if ~flag
      blockObj.Pars.(paramType) = nigeLab.defaults.(paramType)();
      nigeLab.utils.cprintf('Comments',...
         '\n->\tSaving %s params for BLOCK %s (User: ''%s'')\n',...
         paramType,blockObj.Name,blockObj.User);
      blockObj.saveParams(blockObj.User,paramType);
      flag = true;
   end
else
   blockObj.Pars.(paramType) = nigeLab.defaults.(paramType)();
   nigeLab.utils.cprintf('Comments',...
         '\n->\tSaving %s params for BLOCK %s (User: ''%s'')\n',...
         paramType,blockObj.Name,blockObj.User);
   blockObj.saveParams(blockObj.User,paramType);
   flag = true;
end

if nargout > 1
   p = blockObj.Pars.(paramType);
end

end

