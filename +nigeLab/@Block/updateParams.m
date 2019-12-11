function [flag,p] = updateParams(blockObj,paramType)
%% UPDATEPARAMS   Update the parameters struct property for paramType
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
%
% By: MAECI 2018 collaboration (MM, FB, SB)

%% PARSE INPUT
flag = false;
ConstructProps = {'Block','Shortcuts','Animal','Tank'};
PropsToSkip ={'nigelColors','Tempdir','Notifications'};

% Make sure a valid parameter type is selected:
tmp = dir(fullfile(nigeLab.utils.getNigelPath('UNC'),'+nigeLab','+defaults','*.m'));
tmp = cellfun(@(x)x(1:(end-2)),{tmp.name},'UniformOutput',false);

% The following properties do not apply or should be set in constructor:
tmp = setdiff(tmp,[PropsToSkip,ConstructProps]);

if nargin < 2 % if not supplied, select from list...

   idx = promptForParamType(tmp);
   paramType = tmp{idx};
elseif strcmpi(paramType,'all') % otherwise, if 'all' option is invoked:

    paramType = tmp;
   flag = blockObj.updateParams(paramType);
   return;
elseif iscell(paramType) % Use recursion to run if cell array is given
   N = numel(paramType);
   if N==0
      flag = true;
      return;
   end % ends recursion
   paramType = paramType(:); % just in case it wasn't a vector for some reason;
   flag = blockObj.updateParams(paramType{1}) && blockObj.updateParams(paramType(2:N));
   return;
elseif any(ismember(paramType,ConstructProps))
     ... Right now no action is required here
      [pars,~] = nigeLab.defaults.(paramType)();
   allNames = fieldnames(pars);
   allNames = reshape(allNames,1,numel(allNames));
   for name_ = allNames
      % Check to see if it matches any of the listed properties
      if isprop(blockObj,name_{:})
         blockObj.(name_{:}) = pars.(name_{:});
      end
   end
   flag = true;
   return;
else
   % otherwise, check if not an appropriate member
   idx = find(strncmpi(tmp,paramType,3),1,'first');
   if isempty(idx)
      idx = promptForParamType(tmp);
      paramType = tmp{idx};
   else % even if it does, make sure it has correct syntax...
      paramType = tmp{idx};
   end
   
end

%% LOAD CORRECT CORRESPONDING PARAMETERS
propString = [paramType 'Pars'];
blockObj.Pars.(paramType) = nigeLab.defaults.(paramType)();

if isprop(blockObj,propString)
    blockObj.(propString) = blockObj.Pars.(paramType); % For compatibility
end
flag = true;
if nargout > 1
   p = blockObj.Pars.(paramType);
end

%% SUB-FUNCTIONS
   function idx = promptForParamType(str_options)
      [~,idx] = nigeLab.utils.uidropdownbox(...
         'Select parameters to re-load',...
         'Select parameter TYPE:',...
         str_options);
   end

end

